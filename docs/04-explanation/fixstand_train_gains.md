# FixStand Train Gains

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/FixStand Train Gains.md`) เมื่อ 10/11/2026
>
> คำสั่งในหน้านี้รันจากโฟลเดอร์ `<WS>/unitree_rl_mjlab` ใน env `g1_sdk` · `$S` = `deploy/robots/g1_23dof/scripts` (ตั้งด้วย `S=deploy/robots/g1_23dof/scripts`)

## ทำไม
30/10 วัด gain ได้แค่ช่วงของ FixStand ปกติ (kp 40–200, kd 2.5–10) แต่ policy ใช้ **แขน kp 14.3 / kd 0.9** และขา kd 1.8–6.3 ซึ่งยังไม่เคยวัด → ทำ FixStand ที่ใช้ gain ชุดของ policy แล้ววัดตอนแขวน

## ทำงานอย่างไร
`fixstand_train_gains.sh [policy folder, default v0]`
1. คัดลอก g1_ctrl + `config/` ไป `/tmp/g1_fixstand_train` (config จริงไม่ถูกแตะ)
2. แทน kp/kd ของ FixStand ด้วย stiffness/damping จาก deploy.yaml ผ่าน `joint_ids_map` (slot ว่าง = 0)
3. **ลบ transition `Velocity: RT + A`** → เข้า Velocity ไม่ได้ (กันขาตีตอนแขวน) ในsim คีย์ `v` ก็ไม่ทำงาน
4. ตรวจผลด้วย yaml

```bash
$S/fixstand_train_gains.sh
IFACE=enp43s0 G1_CTRL_DIR=/tmp/g1_fixstand_train/build $S/deploy_byobu.sh 1 bm
```
`/tmp` หายเมื่อรีบูต สคริปต์สร้างใหม่ทุกครั้งอยู่แล้ว

## ขั้นตอนบนหุ่น
1. แขวน, debug (`name=''`), T1/T2 บันทึก, T3 เปิด g1_ctrl จาก /tmp
2. L2 + ↑ → T2 ต้องขึ้น **`gains match: Velocity`** (gain ชุดเดียวกับ Velocity เป็นเรื่องปกติ)
3. ค้าง 30 s: นิ่ง ไม่สั่น แขนห้อยมากกว่า FixStand ปกติ
4. ดันทีละกลุ่ม 0.1–0.2 rad แล้วปล่อย + ดึงแล้วปล่อยทันที → L2 + B
5. `pd_check.py ~/g1_state_<วันที่>_bm1.csv ~/g1_cmd_<วันที่>_bm1.csv` ช่วง "Velocity": `kp x` 0.8–1.2, `kd x` 0.5–1.5
6. จบ: `tmux kill-session -t g1deploy` แล้วเปิด byobu ปกติก่อนไปขั้นอื่น

## ผลใน sim (2/11/2026)
| ตรวจ | ผล |
|---|---|
| u / v / p | FixStand ✅ / Velocity ไม่เข้า ✅ / Passive ✅ |
| lowcmd_monitor | `gains match: Velocity` ไม่มี MISMATCH |
| pd_check | `kp x` 0.90–1.00 |
| ห่างท่าตอนค้าง | ไหล่ ~0.05 rad, ศอก 0.02, สะโพก 0.026, เข่า/ข้อเท้า < 0.01 · ไม่สั่น |

**ใช้เทียบกับหุ่นจริง:** ถ้าแขนห้อยห่างท่า > 0.15 rad = kp จริงอ่อนกว่าที่ส่ง (sim วัด kd ไม่ได้เพราะนิ่งเกินไป)

## ผลบนหุ่นจริง (3/11/2026) ✅
| ตรวจ | ผล |
|---|---|
| ค้าง FixStand | 19:54:56 → 19:59:58 (5 นาที) ไม่สั่น · L2 + B กลับ Passive ✅ |
| lowcmd_monitor | `gains match: Velocity` ไม่มี MISMATCH · 889 Hz, max gap 22 ms |
| ห่างท่า ขา + เอว | 0.001–0.042 rad (มากสุด hip pitch −0.04: ขาห้อยไปหน้า) · dq std ≤ 0.016 |
| ห่างท่า แขน | 0.04–0.07 rad (< 0.15 ✅, sim ~0.05) |
| pd_check (ค้างท่า) | delay 3 ms · sat 0% · ข้อต่อที่แรงบิดพอวัด `kp x` 0.85–1.19 · `!! CHECK` 8 ข้อ (แรงบิด 0.2–1.7 Nm, offset ของ `tau_est`) ตรงกับข้อที่ step test ได้ 0.95–0.99 |
| R2 + A | ไม่ได้กด (config ไม่มี transition อยู่แล้ว) |
| **ยังไม่ได้** | `kd x` (นิ่งเกินไป ต้องดันแล้วปล่อยหรือ chirp) · ทดสอบดัน |

log: `~/g1_{state,cmd}_20261103_bm1.csv`

## ดูเพิ่ม
[kp kd Verification](../02-how-to/kp_kd_verification.md) · [Armature and Gains](armature_and_gains.md) · [g1_ctrl FSM](g1_ctrl_fsm.md)
