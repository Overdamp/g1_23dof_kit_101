# Glossary

> ย้ายมาจาก vault ของผู้ดูแล (`Glossary.md`) เมื่อ 10/11/2026

| คำ | ความหมาย | โน้ต |
|---|---|---|
| **kp / kd** | stiffness / damping ของ PD ในมอเตอร์ | [PD Control](../04-explanation/pd_control.md) |
| **armature** | ความเฉื่อยของโรเตอร์สะท้อนผ่านเกียร์ (kg·m²) | [Armature and Gains](../04-explanation/armature_and_gains.md) |
| **BeyondMimic gains** | ชุด gain ที่คำนวณ kp = armature·ω² (ω = 2π·10 Hz) ที่ policy เราเทรนด้วย | [Armature and Gains](../04-explanation/armature_and_gains.md) |
| **Unitree gains** | ชุดปรับมือ 100/150/40/200 ใช้ใน FixStand | [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md) |
| **action scale** | ตัวคูณ output ของ policy เป็นมุม (rad) | [Action Scale](action_scale.md) |
| **deploy contract** | ข้อตกลงระหว่าง policy กับ deploy: `policy.onnx` + `deploy.yaml` | [Deploy Contract](deploy_contract.md) |
| **`rt/lowstate`** | topic สถานะหุ่น (มอเตอร์, IMU, รีโมท) ~1 kHz | [LowState and LowCmd](lowstate_and_lowcmd.md) |
| **`rt/lowcmd`** | topic คำสั่งมอเตอร์ (q, dq, kp, kd, tau) | [LowState and LowCmd](lowstate_and_lowcmd.md) |
| **`rt/lf/bmsstate`** | topic แบตเตอรี่ (SOC, SOH, cycle) | [Real Robot Tools](real_robot_tools.md) |
| **slot** | ช่องมอเตอร์ 0–28 ใน SDK | [Joint Map and Slots](joint_map_and_slots.md) |
| **`mode_machine`** | รหัสรุ่นหุ่น 4 = 23dof | [Joint Map and Slots](joint_map_and_slots.md) |
| **`motorstate`** | flag error ของมอเตอร์ 0 = ปกติ | [Incident Motors 25-26](../05-history/incident_motors_25-26.md) |
| **DDS / CycloneDDS** | middleware ที่ Unitree SDK และ ROS 2 ใช้ | [DDS and Domains](../04-explanation/dds_and_domains.md) |
| **domain** | เลขแยกวง DDS (หุ่นจริง 0, sim 1, ROS 1) | [DDS and Domains](../04-explanation/dds_and_domains.md) |
| **g1_ctrl** | โปรแกรม C++ deploy policy บนหุ่น | [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md) |
| **Passive / FixStand / Velocity / Handover** | state ของ g1_ctrl | [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md) |
| **motion_switcher** | บริการในหุ่นเลือกว่า controller ไหนคุม | [Motion Switcher](../04-explanation/motion_switcher.md) |
| **`ai`** | ชื่อ controller ในตัวของ Unitree (โหมดเริ่มต้น) | [Motion Switcher](../04-explanation/motion_switcher.md) |
| **debug / development mode / released** | ไม่มี controller ในตัว (`name=''`) รับ lowcmd จากเรา | [Motion Switcher](../04-explanation/motion_switcher.md) |
| **zero torque** | มอเตอร์ไม่ออกแรงเลย (ไฟม่วง) | [Remote and LED](remote_and_led.md) |
| **damping** | kp = 0, kd > 0 หนืดอย่างเดียว | [PD Control](../04-explanation/pd_control.md) |
| **gantry / รอก** | โครงแขวนหุ่น | [Test Day Procedure](../02-how-to/test_day_procedure.md) |
| **elastic band** | สปริงเสมือนแขวนหุ่นใน `unitree_mujoco` | [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md) |
| **sim2sim** | ทดสอบ policy ใน sim อีกตัวที่ไม่ได้ใช้เทรน | [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md) |
| **sim2real** | จาก sim ไปหุ่นจริง | [Domain Randomization](../04-explanation/domain_randomization.md) |
| **DR** | domain randomization สุ่มฟิสิกส์ตอนเทรน | [Domain Randomization](../04-explanation/domain_randomization.md) |
| **P1 / P2 / P3a / P3b** | phase การเทรน policy สายหลัก | [Policy Lineage](policy_lineage.md) |
| **Hist5 / yaw_ft / yaw_stand** | policy สายที่ actor เห็นประวัติ 5 เฟรม | [Policy Lineage](policy_lineage.md) |
| **soft start** | ไล่เป้าหมาย 0.5 s ตอนเข้า Velocity | [Soft Start](../04-explanation/soft_start.md) |
| **sysid** | system identification วัดพลวัตข้อต่อ | [Sysid Motion](../02-how-to/sysid_motion.md) |
| **`tau_est`** | แรงบิดที่มอเตอร์ประมาณจากกระแส (คลาด ±10–20%) | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| **chirp** | sine ที่ความถี่ไต่ขึ้น (ของเรา 0.3 → 2.5 Hz ใน 12 s) ทำให้ส่วน D ใหญ่พอวัด kd ได้ | [Sysid Motion](../02-how-to/sysid_motion.md) |
| **Kt (torque constant)** | แรงบิดต่อกระแส 1 A (Nm/A) firmware ใช้แปลงกระแสเป็น `tau_est` ถ้าคลาด `kp x` และ `kd x` เพี้ยนเท่ากัน | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| **least squares** | หาค่าพารามิเตอร์ที่ทำให้ผลรวมกำลังสองของ residual น้อยที่สุด ไวต่อ outlier | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| **residual** | ส่วนที่ fit อธิบายไม่ได้ = ค่าจริง − ค่าจากสมการ | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| **omitted variable bias** | ตัดตัวแปรที่มีผลจริงออกจาก fit แล้วตัวแปรที่เหลือเพี้ยน (ไหล่ roll 0.67 → 0.99) | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| **`kp x` / `kd x`** | อัตราส่วน gain ที่วัดได้ / ที่ส่ง (ควร ≈ 1) | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| **hard stop** | จุดชนสุดทางกลของข้อต่อ | [Offset Check](../02-how-to/offset_check.md) |
| **PhysX / Newton (MJWarp) / MuJoCo** | physics engine 3 ตัวที่ใช้ทดสอบข้ามกัน | [Cross-Sim Isaac Lab](../04-explanation/cross_sim_isaac_lab.md) |
| **byobu / tmux** | แบ่งหน้าจอ terminal ใช้วันทดสอบ (T1–T4) | [Real Robot Tools](real_robot_tools.md) |
| **safe by default** | ค่าเริ่มต้นต้องปลอดภัย ฮาร์ดแวร์จริงต้องเลือกเอง (ไม่ใส่ flag = sim) | [DDS and Domains](../04-explanation/dds_and_domains.md) |
| **`CYCLONEDDS_URI`** | ตัวแปรบอก CycloneDDS ว่าใช้การ์ดไหน ตั้งทั่วไปแล้ว SDK หาหุ่นไม่เจอ | [DDS and Domains](../04-explanation/dds_and_domains.md) |
| **runbook** | โน้ตคำสั่งพร้อมคัดลอก + เหตุผล ใช้ตอนลงมือจริง | [terminal cmd](../02-how-to/terminal_cmd.md) |
| **inotify** | กลไก Linux ให้โปรแกรมรู้ว่าไฟล์เปลี่ยน (Obsidian/IDE ใช้) มีเพดานจำนวน | [Troubleshooting](../02-how-to/troubleshooting.md) |
