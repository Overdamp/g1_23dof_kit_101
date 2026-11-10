# Domain Randomization

> ย้ายมาจาก vault ของผู้ดูแล (`03 Training and Sim/Domain Randomization.md`) เมื่อ 10/11/2026

**แนวคิด:** sim ไม่เหมือนจริง 100% ถ้าสุ่มฟิสิกส์ให้กว้างพอตอนเทรน หุ่นจริงจะเป็นแค่ "อีกแบบหนึ่ง" ที่ policy เคยเจอ

## สุ่มเมื่อไร
| mode | เมื่อไร |
|---|---|
| startup | ครั้งเดียวต่อ env (1024 env = หุ่น 1024 แบบ) |
| reset | ทุก episode |
| interval | ระหว่าง episode (เช่นผลัก) |
| obs noise | ทุก step (actor เท่านั้น) |

## รายการ (P1 → P3b)
| event | สุ่มอะไร | ช่วง | P1 | P2 | P3b |
|---|---|---|:-:|:-:|:-:|
| foot_friction | แรงเสียดทานเท้า | 0.3–1.6 | ✅ | ✅ | ✅ |
| encoder_bias | offset มุมข้อต่อ | ±0.015 rad | ✅ | ✅ | ✅ |
| base_com | COM ลำตัว | ±5 cm | ✅ | ✅ | ✅ |
| push_robot | ผลัก (ทุก 5–6 s) | xy ±0.5 m/s ฯลฯ | ✅ | ✅ | ✅ |
| torso_mass_payload | มวลลำตัวเพิ่ม | −1 ถึง +3.5 kg | | ✅ | ✅ |
| limb_mass_scale | มวล link | ×0.9–1.1 | | ✅ | ✅ |
| joint_friction | frictionloss | 0–0.3 | | ✅ | ✅ |
| joint_damping | damping ข้อต่อ | 0–0.1 | | ✅ | ✅ |
| motor_pd_gains | kp, kd | ×0.85–1.15 | | ✅ | ✅ |
| motor_effort_limits | แรงบิดสูงสุด | ×0.85–1.05 | | ✅ | ✅ |
| action_delay | delay เป้าหมาย | **0–20 ms** (P3a 0–40) | | | ✅ |

obs noise: gyro ±0.2, gravity ±0.05, joint pos ±0.01, joint vel ±1.5

## เชื่อมกับหุ่นจริง
| DR | ผลวัดจริง | ครอบคลุม? |
|---|---|---|
| motor_pd_gains ×0.85–1.15 | `kp x` 0.89–1.09 | ✅ |
| action_delay 0–20 ms | delay 3 ms | ✅ |
| encoder_bias ±0.015 | ต้องตรวจหลัง calibrate ([Offset Check](../02-how-to/offset_check.md)) | ? |
| มวลรวม 31–36 kg | หุ่นจริงพร้อมแบต ~34–35 kg | ✅ |

## ดูเพิ่ม
[Policy Lineage](../03-reference/policy_lineage.md) · [Armature and Gains](armature_and_gains.md) · ที่มา `doc/domain_randomization_phases_g1_23dof.md`
