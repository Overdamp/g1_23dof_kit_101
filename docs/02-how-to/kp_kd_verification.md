# kp kd Verification

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/kp kd Verification.md`) เมื่อ 10/11/2026
>
> คำสั่งในหน้านี้รันจากโฟลเดอร์ `<WS>/unitree_rl_mjlab` ใน env `g1_sdk` · `$S` = `deploy/robots/g1_23dof/scripts` (ตั้งด้วย `S=deploy/robots/g1_23dof/scripts`)

คำถาม: "มอเตอร์ใช้ kp/kd ตามที่เราส่งจริงไหม และข้อต่อจริงตอบสนองเหมือน sim ไหม"

## ตรวจ 4 ชั้น
| ชั้น | คำถาม | เครื่องมือ | ใช้หุ่น |
|---|---|---|---|
| 1 | ไฟล์ตรงกับตอนเทรน | `gain_check.py` | ไม่ |
| 2 | g1_ctrl ส่งค่าถูก slot ถูกโหมด | `lowcmd_monitor.py` | sim → จริง |
| 3 | มอเตอร์ใช้ gain ตามที่ส่ง | `pd_check.py` (torque check) | จริง (แขวน) |
| 4 | พลวัตจริงเหมือน sim | `pd_check.py --replay` | จริง (แขวน) ต้องมีการเคลื่อนที่ที่สั่ง ([Sysid Motion](sysid_motion.md)) |

## pd_check ทำอะไร
1. หา delay ของคำสั่ง (0–30 ms) จาก correlation
2. fit ต่อข้อต่อต่อโหมด: `tau_est − tau_ff = a·kp(q_des−q) + b·kd(dq_des−dq)` → **`kp x` = a, `kd x` = b** (ควร ≈ 1)
3. ตัด sample ที่แรงบิด > 95% ของ limit · term ที่เล็กกว่า 0.3 Nm **ยังอยู่ในสมการ fit** แค่ไม่รายงานค่า (`not scored: small term`) ตั้งแต่ d9194fd (4/11) เพราะถ้าตัดทิ้ง อีก gain จะรับแรงส่วนนั้นไปแทน (omitted variable bias)
4. `--segments <seg.csv>` (ece6d7a): fit ทีละช่วงทดสอบของ [Sysid Motion](sysid_motion.md) เฉพาะข้อต่อที่ทดสอบ `tau_est − tau_ff = a·P + b·D + c` (c = offset ของ `tau_est`)
5. `--replay`: ส่ง lowcmd ที่บันทึกเข้า MuJoCo (ลำตัวยึดกลางอากาศ) เทียบ q → `nrmse`, `lag ms` เลือก `--armature mjcf|train`, `--delay-ms`

```bash
python $S/pd_check.py ~/g1_state_X.csv ~/g1_cmd_X.csv
python $S/pd_check.py ~/g1_state_X.csv ~/g1_cmd_X.csv --segments ~/sysid_seg_X.csv
python $S/pd_check.py ~/g1_state_X.csv ~/g1_cmd_X.csv --replay --t0 5 --t1 25 --armature train
```

## เกณฑ์
| ด่าน | ตรวจ | ผ่าน |
|---|---|---|
| Passive (kp 0) | kd ด้วยการหมุนมือ | `kd x` 0.5–1.5 |
| FixStand (Unitree) | kp สู้แรงโน้มถ่วง | `kp x` 0.8–1.2, corr ≥ 0.9 |
| FixStand (gain ที่เทรน) | kp + kd ช่วงต่ำ | `kp x` 0.8–1.2, `kd x` 0.5–1.5 |

## อ่านผลที่ไม่ผ่าน
| อาการ | น่าจะเป็น |
|---|---|
| ทุกข้อต่อเพี้ยนทางเดียวกัน | `tau_est` คลาด (±10–20%) หรือแบตอ่อน ไม่ใช่ gain ผิด |
| บางข้อต่อเพี้ยน | มอเตอร์ตัวนั้น / friction สูง |
| ข้อเท้าแปลก | linkage ข้อเท้า firmware แปลงแรงบิดให้ |
| `kp x` ต่ำในแรงบิดเล็ก | `tau_est` มี offset คงที่ (30/10 ข้อเท้าขวา −0.26 Nm: 0.67 → 0.91 เมื่อ fit แบบมี offset) · gain เทรนต่ำ แรงบิดตอนค้างท่าเล็ก → เจอบ่อย 3/11: fit เฉพาะช่วง step + offset แทน |
| `kp x` ต่ำ ข้อต่อที่ส่วน D เล็ก (เช่นไหล่ roll ใน chirp) | `pd_check` ก่อน d9194fd ตัด D ทิ้งจาก fit: sim 0.67 → 0.99 หลังแก้ |
| เข่าใน chirp `kp x` / `kd x` 0.85–0.93 **แม้ใน sim** | ส่วน P (3.6 Nm) กับ D (3.2 Nm) เกือบหักล้างกัน แรงบิดรวมเหลือ 0.4 Nm fit จึงไวต่อเวลาคลาด ~1 ms → เทียบกับ sim ไม่ใช่กับ 1.0 |
| `kp x` กับ `kd x` เพี้ยนเท่ากัน | น่าจะเป็นสเกลของ `tau_est` (Kt ใน firmware) ไม่ใช่ gain ผิด ถ้าเพี้ยนไม่เท่ากันค่อยสงสัย gain |
| delay > 10 ms | เน็ต/PC หน่วง |
| replay `nrmse` ≈ 1 | ข้อมูลไม่มีการเคลื่อนที่ที่สั่ง (q_des คงที่ เช่นดันด้วยมือ) **ใช้ไม่ได้** |

## ผลจริง
30/10: FixStand `kp x` 0.89–1.09, แขน `kd x` 0.92–0.98, delay 3 ms, Passive `kd x` 0.94–0.98 ✅ ([Real Robot Results](../05-history/real_robot_results.md))
3/11 gain ที่เทรน: step ศอกซ้าย / ศอกขวา / เข่าซ้าย `kp x` 0.99 / 0.96 / 0.95 (fit มี offset, [Sysid Motion](sysid_motion.md)) · FixStand ค้าง 5 นาที ห่างท่า ขา ≤ 0.04 แขน ≤ 0.07 rad ([FixStand Train Gains](../04-explanation/fixstand_train_gains.md)) ✅
3/11 ด้วย `pd_check --segments` (ตัวจริงใน repo): ศอกซ้าย 0.96 / 0.88, ศอกขวา 0.96 / 0.84, เข่าซ้าย 0.93 / 0.86 (`kp x` / `kd x`, step ซึ่งเชื่อ `kd x` ได้น้อย)

**ค่าอ้างอิงจาก sim (chirp ทุกข้อต่อ, 4/11, PD ใน sim ตรงเป๊ะ):** ใช้ตั้งเกณฑ์ผ่านของหุ่นจริง (±0.1 ต่อข้อต่อ)

| กลุ่ม | `kp x` | `kd x` |
|---|---|---|
| ไหล่ pitch/yaw, ศอก, ข้อมือ, เอว, hip, ข้อเท้า | 0.97–0.99 | 0.95–0.98 |
| ไหล่ roll | 0.99 | ไม่รายงาน (D 0.27 Nm) |
| เข่าซ้าย / ขวา | 0.93 / 0.86 | 0.92 / 0.85 |

log: scratchpad `chirp_{state,cmd,seg}.csv` (หายเมื่อรีบูต)
ยังไม่ได้วัด: `kd x` ที่ gain เทรนบนหุ่นจริงด้วย chirp → แผนทดสอบ chirp + L2 + B (เอกสารแยกของผู้ดูแล)

## ดูเพิ่ม
[PD Control](../04-explanation/pd_control.md) · [Armature and Gains](../04-explanation/armature_and_gains.md) · [Real Robot Tools](../03-reference/real_robot_tools.md)
