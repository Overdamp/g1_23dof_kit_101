# Reference

หาค่า ตาราง และนิยาม (หน้าส่วนใหญ่ย้ายมาจาก vault ของผู้ดูแล 10/11/2026)

## kit
| หน้า | เนื้อหา |
|---|---|
| [make_targets](make_targets.md) | แต่ละ `make <target>` รันคำสั่งอะไร จากไฟล์ไหน |
| [environments_map](environments_map.md) | env ไหนใช้กับ repo ไหน · ตารางเทียบ alias เดิมกับคำสั่งใน kit |
| [glossary](glossary.md) | คำศัพท์ทั้งหมดของโปรเจค |

## สัญญาระหว่าง policy กับหุ่น
| หน้า | เนื้อหา |
|---|---|
| [deploy_contract](deploy_contract.md) | `deploy.yaml` ต้องตรงกับการเทรนในเรื่องอะไรบ้าง |
| [joint_map_and_slots](joint_map_and_slots.md) | ลำดับ joint ของ policy กับ slot มอเตอร์ 29 ช่อง |
| [observations](observations.md), [observation_history](observation_history.md) | obs แต่ละตัว และการเรียง history |
| [action_scale](action_scale.md) | action → ท่าเป้าหมายของมอเตอร์ |
| [lowstate_and_lowcmd](lowstate_and_lowcmd.md) | ข้อความ `rt/lowstate`, `rt/lowcmd` |
| [timing_and_rates](timing_and_rates.md) | ความถี่ของ policy, PD, DDS |

## หุ่นและเครื่องมือ
| หน้า | เนื้อหา |
|---|---|
| [real_robot_tools](real_robot_tools.md) | สคริปต์แต่ละตัวทำอะไร ส่งคำสั่งหรืออ่านอย่างเดียว |
| [remote_and_led](remote_and_led.md) | ปุ่มรีโมทและไฟ LED |
| [policy_lineage](policy_lineage.md) | policy แต่ละตัวเทรนต่อมาจากอะไร |

## โค้ด
| หน้า | เนื้อหา |
|---|---|
| [code_map](code_map.md) | ไฟล์ที่โปรเจคสร้างและแก้ใน repo ต่างๆ |
| [fsm_code_walkthrough](fsm_code_walkthrough.md) | ไล่โค้ด FSM ของ `g1_ctrl` ทีละบรรทัด |
