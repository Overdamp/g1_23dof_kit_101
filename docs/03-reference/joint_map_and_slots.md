# Joint Map and Slots

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Joint Map and Slots.md`) เมื่อ 10/11/2026

SDK ของ G1 มี **29 slot** (ออกแบบให้รุ่น 29-DoF) หุ่นเรามี **23 ข้อต่อ** ช่องที่เหลือว่างหรือถูกล็อก

| slot | ข้อต่อ | | slot | ข้อต่อ |
|---|---|---|---|---|
| 0 | left_hip_pitch | | 15 | left_shoulder_pitch |
| 1 | left_hip_roll | | 16 | left_shoulder_roll |
| 2 | left_hip_yaw | | 17 | left_shoulder_yaw |
| 3 | left_knee | | 18 | left_elbow |
| 4 | left_ankle_pitch | | 19 | left_wrist_roll |
| 5 | left_ankle_roll | | 20, 21 | (wrist pitch/yaw ไม่มี) |
| 6 | right_hip_pitch | | 22 | right_shoulder_pitch |
| 7 | right_hip_roll | | 23 | right_shoulder_roll |
| 8 | right_hip_yaw | | 24 | right_shoulder_yaw |
| 9 | right_knee | | **25** | **right_elbow** |
| 10 | right_ankle_pitch | | **26** | **right_wrist_roll** |
| 11 | right_ankle_roll | | 27, 28 | (wrist pitch/yaw ไม่มี) |
| 12 | waist_yaw | | | |
| 13, 14 | (waist roll/pitch ล็อก) | | | |

**slot ที่ไม่ใช้: 13, 14, 20, 21, 27, 28** ใน Velocity ต้องได้ kp = kd = 0 (`lowcmd_monitor` ตรวจ)

## ค่าที่เกี่ยวข้อง
| ฟิลด์ | ค่า | ความหมาย |
|---|---|---|
| `mode_machine` | **4** | รุ่น 23dof g1_ctrl เช็คตอนเริ่ม ไม่ตรง → `Unmatched robot type` |
| `mode_pr` | 0 | ข้อเท้าโหมด PR (pitch/roll) firmware แปลงเป็นมอเตอร์ 2 ตัวให้ |
| `joint_ids_map` | ใน deploy.yaml | ลำดับข้อต่อของ policy → slot |

## ตรวจแล้ว
28/10/2026 หมุนทีละข้อต่อ: index ถูกครบ 23 ตัว ทิศยืนยันด้วยข้อมูลและ RViz ช่วงหมุนสุดที่วัดได้ใช้เป็น reference ใน [Offset Check](../02-how-to/offset_check.md)

## ดูเพิ่ม
[Deploy Contract](deploy_contract.md) · [Incident Motors 25-26](../05-history/incident_motors_25-26.md) · [Real Robot Results](../05-history/real_robot_results.md)
