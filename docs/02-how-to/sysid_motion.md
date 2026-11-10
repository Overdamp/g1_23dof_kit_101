# Sysid Motion

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Sysid Motion.md`) เมื่อ 10/11/2026
>
> คำสั่งในหน้านี้รันจากโฟลเดอร์ `<WS>/unitree_rl_mjlab` ใน env `g1_sdk` · `$S` = `deploy/robots/g1_23dof/scripts` (ตั้งด้วย `S=deploy/robots/g1_23dof/scripts`)

## ทำไมต้องมี
- ดันข้อต่อด้วยมือสู้ kp 100–200 ไม่ไหว ("แข็งมาก บิดไม่ไป")
- replay ข้อมูลดันมือใช้ไม่ได้เพราะ `q_des` คงที่ (nrmse ≈ 1)
→ ให้สคริปต์**สั่งท่าเอง**แล้วบันทึกการตอบสนอง

## ทำอะไร
`deploy/robots/g1_23dof/scripts/sysid_motion.py --network enp43s0` ส่ง `rt/lowcmd` เอง (**แทน g1_ctrl ห้ามรันพร้อมกัน**)
1. ไล่ไปท่ายืน 3 s แล้วค้าง 2 s
2. ทีละข้อต่อ:
   - **step**: +A → 0 → −A → 0 (ช่วงละ 1.5 s, ขอบนุ่ม 0.1 s)
   - **chirp**: 0.3 → 2.5 Hz ใน 12 s (fade เข้า/ออก 1 s)
   - พัก 1 s
3. จบ: damping (kp 0, kd ของ Passive) 1 s

แอมพลิจูดตั้งต่อชนิดข้อต่อ กลุ่ม: `armL`, `armR`, `waist`, `legL`, `legR` รอบเต็ม ~8 นาที

## ระบบป้องกัน
- ตรวจแผนก่อนส่ง: limit MJCF เผื่อ 0.1 rad, ความเร็วเป้า ≤ 6 rad/s
- เข้า damping ทันทีเมื่อ: **L2 + B**, Ctrl-C, LowState ขาด > 50 ms, ห่างเป้า > 0.5 rad, > 70 °C, มอเตอร์หลุด (หุ่นจริง)
- ไม่ยอมเริ่มถ้ามี lowcmd อยู่ (g1_ctrl) หรือ motion mode ไม่ใช่ `''`

## คำสั่ง
```bash
IFACE=enp43s0 $S/deploy_byobu.sh 1 sysid          # T1/T2 บันทึก, T3 ไม่เปิด g1_ctrl
python $S/sysid_motion.py --network enp43s0 --dry-run
python $S/sysid_motion.py --network enp43s0 --groups armL --joints elbow --kinds step --segments ~/sysid_seg_<วันที่>_light.csv
python $S/sysid_motion.py --network enp43s0 --segments ~/sysid_seg_<วันที่>_full.csv      # รอบเต็ม
```
ตัวเลือก: `--gains train|unitree`, `--groups`, `--joints`, `--kinds step,chirp`, `--network`, `--domain`, `--yes`
**ตั้งชื่อ `--segments` ใหม่ทุกครั้ง** (30/10 ไฟล์ถูกทับ) ใช้เวลาใน segments กับ `pd_check --replay --t0 --t1`

## ผล
- sim (unitree_mujoco แยก domain 1, elastic band) 30/10: ครบแผน, ปฏิเสธเมื่อมี lowcmd, Ctrl-C และ sim ตาย → damping ✅
- **หุ่นจริง 30/10 (ศอกซ้าย step, gain ที่เทรน):** `kp x` 1.02, rise 137 ms, ไม่ overshoot, friction hysteresis ~0.3–0.5 Nm, lowcmd 526–556 Hz, **L2 + B หยุดได้** ✅
- **หุ่นจริง 3/11 (step, gain ที่เทรน)** fit เฉพาะช่วง step + มี offset ของ `tau_est`:

| ข้อต่อ | kp | `kp x` ดิบ | **`kp x` มี offset** | offset | log |
|---|---|---|---|---|---|
| ศอกซ้าย | 14.3 | 1.15 | **0.99** | −0.12 Nm | `~/g1_{state,cmd}_20261103_sysid1.csv` |
| ศอกขวา (มอเตอร์ 25 หลังกลับมา) | 14.3 | 0.70 | **0.96** | +0.15 Nm | `..._sysid2.csv` |
| เข่าซ้าย | 99.1 | 0.80 | **0.95** | −0.30 Nm | `..._sysid3.csv` |

  delay 0–4 ms · 25/26 ไม่หลุด · **L2 + B ตอน 3.5 s → `-> damping (remote L2 + B)`** ✅ (`..._sysid4.csv`, segment `completed 0`)
  `pd_check` ทั้งหน้าต่างให้ค่าต่ำ (ศอกขวา 0.61, เข่าซ้าย 0.77) เพราะรวมช่วงค้างท่าที่แรงบิดเล็ก → ใช้ fit เฉพาะ segment: ตอนนี้คือ `pd_check.py --segments` (ece6d7a, ค่าต่างจาก `stepfit.py` เดิมเล็กน้อย: 0.96 / 0.96 / 0.93 เพราะ delay ที่ใช้ต่างกัน)
- **sim 4/11 chirp ทุกข้อต่อ (305 s):** ครบแผน `pd_check --segments` OK ทุกข้อ (`kd x` 0.95–0.98, เข่า 0.85–0.92) ตารางอ้างอิงอยู่ใน [kp kd Verification](kp_kd_verification.md)
- **sim 4/11 L2 + B ปลอม** (ใส่บิตปุ่มใน LowState ด้วยตัวครอบ `fake_l2b.py` โดยไม่แก้สคริปต์): lowcmd kp 0 ทุกข้อต่อภายใน **0.6–0.8 ms** หลังกด แล้วส่ง damping ต่อ 1 s ก่อนจบโปรแกรม · บั๊กของตัวครอบทำให้ callback พังโดยบังเอิญ → ตัวป้องกัน LowState > 50 ms ตัดเข้า damping ได้จริง
- `wireless_remote` ใน Python SDK เป็น `bytes` (แก้ทีละไบต์ไม่ได้ ต้องแปลงเป็น `bytearray` ก่อน)
- ยังไม่รู้: หลังโปรแกรมจบและ lowcmd หยุดมา มอเตอร์จริงคงคำสั่งสุดท้าย (kp 0 + damping) ไว้หรือปล่อยอิสระ (sim คงคำสั่งสุดท้าย)
- ข้อควรรู้: sysid ไม่ยอมเริ่มถ้ามีมอเตอร์ offline (เช็คทุกข้อต่อ) และถ้ามี lowcmd อยู่

## ดูเพิ่ม
[kp kd Verification](kp_kd_verification.md) · [Armature and Gains](../04-explanation/armature_and_gains.md) · [Stop Mechanisms](../04-explanation/stop_mechanisms.md)
