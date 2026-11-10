# Remote and LED

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Remote and LED.md`) เมื่อ 10/11/2026

ไฟล์เต็ม: `unitree_rl_mjlab/doc/remote/remote_buttons_comparison.md` (5 เวอร์ชัน firmware) · ชื่อปุ่ม: **LT = L2, RT = R2, LB = L1, RB = R1**

## สีไฟหัว
| สี | สถานะ | เจอเมื่อ |
|---|---|---|
| ฟ้า | ทำงานปกติ | ยืน/เดินในโหมด ai |
| น้ำเงินเข้ม | Standby | |
| ส้ม | Damping | L2 + B ในโหมด ai |
| เขียว | นั่ง | เปิดเครื่องตอนนั่ง / L2 + ← |
| **เหลือง** | **Debug** | หลัง release (อาจดูเป็นเขียวอ่อนในบางแสง) |
| ม่วง | Zero torque | หลัง `select ai` / [Handover](../02-how-to/handover.md) |
| **แดง** | **Error** | หยุดและอ่านสถานะ |

## ปุ่มในโหมด `ai` (G1 23dof, firmware ≥ 8.2)
| ปุ่ม | ผล |
|---|---|
| L2 + B | Damping |
| L2 + Y | Zero torque |
| L2 + ↑ | ล็อกยืน |
| L2 + ← ค้าง 2 s | นั่ง (ต้องมีคนประคอง) |
| L2 + A ค้าง | ย่อ ↔ ยืน |
| **R1 + X ค้าง 2 s** | **Regular (เดินปกติ)** |
| R2 + A ค้าง | Running (เร็ว ไม่ใช้) |
| ดับเบิลคลิก L2 / L1 | ความเร็วต่ำ / สูง |

**บังคับเดินด้วยรีโมท (จากไฟม่วง, แขวน):** L2 + B → L2 + ↑ → หย่อนรอกให้เท้าแตะพื้น → R1 + X ค้าง → ดับเบิลคลิก L2 → stick ทีละน้อย
**เก็บ:** ปล่อย stick → ดึงรอกรับน้ำหนัก → L2 + B → ปิด ([Safe Shutdown](../02-how-to/safe_shutdown.md)) ยังไม่ได้ทดสอบเดินด้วย ai บนหุ่นตัวนี้

## ปุ่มของ g1_ctrl (โหมด debug)
| ปุ่ม | ผล |
|---|---|
| L2 + ↑ | Passive → FixStand |
| R2 + A | FixStand → Velocity |
| **L2 + B** | → Passive (หยุดฉุกเฉิน ทุก state) |
| **L1 + R1** (LB + RB) ค้าง 1 s → START | Passive → [Handover](../02-how-to/handover.md) (3/11 ทดสอบจริงแล้ว) |
| stick | vx (ซ้ายตั้ง, clamp −0.5..1.0), vy (ซ้ายนอน ±0.5), wz (ขวานอน ±1.0) **ไม่มี smooth รอบแรกดัน ≤ 40%** |

> [!TIP]
> **เช็คว่าหุ่นเห็นปุ่มอะไร**
> ชื่อ LB/RB ใน config ทำให้สับสน (3/11 กดแล้วหุ่นอ่านเป็น L2/R2) → ให้ดูตัวอักษร L1/R1 บนรีโมท · อ่านปุ่มสดได้จาก `rt/lowstate` `wireless_remote[2..3]` (อ่านอย่างเดียว)

> [!CAUTION]
> **ปุ่มที่ห้าม**
> - **L2 + A ใน debug** = Unitree ใช้ยืนยัน debug แต่หุ่นเหยียดตัวตรง (30/10 กดตอนนั่ง แล้ว 25/26 หลุด) → เราข้าม
> - **L2 + B ตอนยืนบนพื้นไม่มีรอก** → หุ่นทรุดล้ม ([Incident Fall 2026-10-30](../05-history/incident_fall_2026-10-30.md))

## ดูเพิ่ม
[Motion Switcher](../04-explanation/motion_switcher.md) · [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md) · [Stop Mechanisms](../04-explanation/stop_mechanisms.md)
