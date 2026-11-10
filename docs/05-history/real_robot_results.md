# Real Robot Results

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Real Robot Results.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-03

ค่าที่วัดได้จริง ใช้เป็น baseline เทียบครั้งต่อไป

## 28/10/2026: read-only บนรอก (damping ของ Unitree)
| รายการ | ผล |
|---|---|
| LowState | 1044 Hz, gap สูงสุด 60 ms |
| `mode_machine` / `mode_pr` | 4 / 0 |
| IMU | ตั้งตรง, gyro bias ≤ 0.0014 rad/s, แกนตรงกับ RViz |
| encoder noise | ~0.0001 rad |
| อุณหภูมิ / แบต | 36–51 °C / 52 V |
| joint map | index + ทิศถูกครบ 23 |

**ช่วงหมุนสุด (rad)** reference ของ [Offset Check](../02-how-to/offset_check.md):

| slot | joint | min / max | | slot | joint | min / max |
|---|---|---|---|---|---|---|
| 0 | L hip pitch | −2.534 / 2.808 | | 12 | waist yaw | −2.704 / 2.704 |
| 1 | L hip roll | −0.524 / 2.962 | | 15 | L sh pitch | −3.065 / 2.666 |
| 2 | L hip yaw | −2.761 / 2.747 | | 16 | L sh roll | −0.146 / 2.245 |
| 3 | L knee | −0.086 / 2.877 | | 17 | L sh yaw | −2.613 / 2.608 |
| 4 | L ankle pitch | −0.868 / 0.514 | | 18 | L elbow | −1.038 / 2.089 |
| 5 | L ankle roll | −0.284 / 0.271 | | 19 | L wrist roll | −1.998 / 1.959 |
| 6 | R hip pitch | −2.536 / 2.867 | | 22 | R sh pitch | −3.076 / 2.669 |
| 7 | R hip roll | −2.963 / 0.531 | | 23 | R sh roll | −2.255 / 0.149 |
| 8 | R hip yaw | −2.750 / 2.760 | | 24 | R sh yaw | −2.625 / 2.603 |
| 9 | R knee | −0.087 / 2.895 | | 25 | **R elbow** | −1.033 / 2.073 |
| 10 | R ankle pitch | −0.868 / 0.525 | | 26 | **R wrist roll** | −1.967 / 1.979 |
| 11 | R ankle roll | −0.319 / 0.242 | | | | |

เกิน MJCF เล็กน้อย: ankle roll, waist yaw (±2.704 vs ±2.618), wrist roll ไม่ต้องแก้ config

## 30/10/2026: kp/kd บนรอก (P3b g1_ctrl)
| ด่าน | ผล |
|---|---|
| FixStand (Unitree) | `kp x` 0.89–1.09 (ข้อเท้าขวา roll 0.67 → 0.91 เมื่อ fit มี offset) |
| แขน kd | `kd x` 0.92–0.98 |
| delay | 3 ms |
| Passive | `kd x` 0.94–0.98 |
| rate | lowstate 1053 Hz, lowcmd ~820–884 Hz |
| sysid ศอกซ้าย (gain เทรน) | `kp x` 1.02, rise 137 ms, ไม่ overshoot, friction 0.3–0.5 Nm |
| แบตท้ายวัน | SOC 49%, 48.6 V, SOH 92%, 6 cycles · อุณหภูมิ 32–50 °C |

## 2/11/2026
| รายการ | ผล |
|---|---|
| lowstate | 1056 Hz (355 Hz ตอนเพิ่งบูต) |
| แบต | SOC 81% → 80%, 52.2–52.5 V, SOH 92% |
| อุณหภูมิ | ≤ 39 °C |
| motion mode ตอนบูต | `ai` |
| **มอเตอร์ 25/26** | **offline ตั้งแต่บูต** ([Incident Motors 25-26](incident_motors_25-26.md)) |

## 3/11/2026
| รายการ | ผล |
|---|---|
| lowstate | 881–1048 Hz |
| แบต | SOC 89% → 75% (หลายรอบบูต), 51.5–53.0 V, SOH 92% |
| อุณหภูมิ | ≤ 54 °C (ขึ้นเรื่อยๆ ตอนเปิดทิ้งใน `ai`) |
| motion mode ตอนบูต | `ai` |
| **มอเตอร์ 25/26** | หลุดตั้งแต่บูต → ถอดแบตไม่หาย → **บิดแขนก่อนเปิด หาย** ([Incident Motors 25-26](incident_motors_25-26.md)) |
| [Offset Check](../02-how-to/offset_check.md) แขนขวา | OK ทั้ง 5 ข้อ |
| **lowcmd ~1 kHz ในโหมด `ai`** | น่าจะเป็น controller `ai` ของ Unitree เอง (กลับมาหลัง SelectMode `ai`) ไม่ใช่ของคนอื่น · ใช้ `release` แทนการ kill ([Network Setup](../02-how-to/network_setup.md)) |
| release → debug | ✅ |
| sysid step (gain เทรน) | ศอกซ้าย / ศอกขวา / เข่าซ้าย `kp x` 0.99 / 0.96 / 0.95 · L2 + B ✅ ([Sysid Motion](../02-how-to/sysid_motion.md)) |
| FixStand gain เทรน | ค้าง 5 นาที ✅ ขา ≤ 0.04 แขน ≤ 0.07 rad ([FixStand Train Gains](../04-explanation/fixstand_train_gains.md)) |
| **[Handover](../02-how-to/handover.md)** | ✅ ครั้งแรกบนหุ่นจริง 3.6 s → ไฟม่วง `name='ai'` · ปุ่มคือ **L1 + R1** |
| จบวัน | SOC 60%, 49.6 V, มอเตอร์ ≤ 54 °C · ปิดเครื่องตอนแขวน |
| ยังไม่ได้ | `kd x` ที่ gain เทรน · ทดลองบูต 2 รอบ (25/26) · offset ขา/เอว/แขนซ้าย |

## ดูเพิ่ม
[kp kd Verification](../02-how-to/kp_kd_verification.md) · [Test Day Procedure](../02-how-to/test_day_procedure.md)
