# Explanation

อยากรู้ว่า**ทำไม**ออกแบบแบบนี้ (หน้าส่วนใหญ่ย้ายมาจาก vault ของผู้ดูแล 10/11/2026)

- **[basics/](basics/README.md): พื้นฐานสำหรับมือใหม่ 8 หน้า (terminal, env var, conda, make, DDS, ROS 2, worktree, tmux) อ่านก่อน Day 1**

## ความปลอดภัยและการแยก sim กับหุ่นจริง
| หน้า | ตอบคำถาม |
|---|---|
| [dds_and_domains](dds_and_domains.md) | ทำไม sim = lo + domain 1 และหุ่น = enp43s0 + domain 0 |
| [stop_mechanisms](stop_mechanisms.md) | หยุดหุ่นได้กี่ทาง แต่ละทางเร็วแค่ไหน และมีช่องโหว่อะไร |
| [motion_switcher](motion_switcher.md) | ทำไมต้องปลด controller ของ Unitree ก่อนสั่ง low-level |
| [soft_start](soft_start.md) | ทำไมตอนเข้า Velocity ต้องค่อยๆ ผสมจากท่า FixStand ไปเป็นเป้าของ policy ใน 0.5 วินาทีแรก |

## ควบคุม
| หน้า | ตอบคำถาม |
|---|---|
| [g1_ctrl_fsm](g1_ctrl_fsm.md) | Passive → FixStand → Velocity ทำงานอย่างไร |
| [pd_control](pd_control.md) | kp, kd คืออะไร และมอเตอร์ใช้อย่างไร |
| [armature_and_gains](armature_and_gains.md) | gain ที่ใช้เทรนมาจากไหน |
| [fixstand_train_gains](fixstand_train_gains.md) | ทำไม FixStand ใช้ gain ของ Unitree และทำไมยืนเองบนพื้นไม่ได้ |

## เทรนและประเมินผล
| หน้า | ตอบคำถาม |
|---|---|
| [domain_randomization](domain_randomization.md) | สุ่มอะไรบ้างตอนเทรน และเพื่ออะไร |
| [sim2sim_evaluation](sim2sim_evaluation.md) | ประเมิน policy ใน sim อย่างไรก่อนขึ้นหุ่น |
| [cross_sim_isaac_lab](cross_sim_isaac_lab.md) | ทำไมลองรัน policy ใน physics engine อื่น |
