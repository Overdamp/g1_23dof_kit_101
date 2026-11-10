# How-to (runbook)

รู้แล้วว่าจะทำอะไร ต้องการขั้นตอนและคำสั่ง หน้าส่วนใหญ่ย้ายมาจาก vault ของผู้ดูแล (10/11/2026) แต่ละหน้ามีบรรทัดบอกที่มาและวันที่อัปเดตของต้นฉบับ
ตัวแปร `$S` ที่หลายหน้าใช้ = `deploy/robots/g1_23dof/scripts` (รันจากโฟลเดอร์ `unitree_rl_mjlab`)
alias ส่วนตัวใน `~/.bashrc` ของผู้ดูแลเปลี่ยนเป็น `make <target>` หรือคำสั่งเต็มแล้ว (ตารางเทียบ: [environments_map](../03-reference/environments_map.md))

## ใช้ประจำ
| หน้า | ใช้เมื่อ |
|---|---|
| [terminal_cmd](terminal_cmd.md) | คำสั่งฝั่งคอมเราทั้งหมดในวันทดสอบหุ่น พร้อมคอมเมนต์ทุกบรรทัด |
| [mujoco_sim_cmd](mujoco_sim_cmd.md) | sim ของ MuJoCo: โครงสร้างโฟลเดอร์, sim2sim, sim ที่มีเชือก (`make sim-band`), การทดลอง FixStand |
| [isaaclab_sim_cmd](isaaclab_sim_cmd.md) | รัน policy จาก mjlab ใน Isaac Lab (cross-sim) และเทรนใน Isaac |
| [training_practice](training_practice.md) | เทรนแบบขรุขระตั้งแต่ต้น หรือเรียบก่อนแล้ว fine-tune, เทรนบน DGX, สิ่งที่ policy ใหม่ต้องผ่านก่อนขึ้นหุ่น |
| [troubleshooting](troubleshooting.md) | อาการ → สาเหตุ → วิธีแก้ (ดูคู่กับ [pitfalls](../pitfalls.md)) |

## หุ่นจริง (ทดสอบเป็นกลุ่มเท่านั้น)
| หน้า | ใช้เมื่อ |
|---|---|
| [test_day_procedure](test_day_procedure.md) | ลำดับวันทดสอบ ข้อ 0–9 พร้อมเกณฑ์ผ่าน |
| [network_setup](network_setup.md) | ตั้ง IP ของเครื่องเรา และต่อหุ่น |
| [byobu_guide](byobu_guide.md) | หน้าจอ 4 ช่อง T1–T4 ของวันทดสอบ และปุ่มลัดทั้งหมด |
| [offset_check](offset_check.md) | ตรวจ offset ของ encoder แต่ละข้อต่อ |
| [sysid_motion](sysid_motion.md) | ขยับข้อต่อแบบ step / chirp เพื่อวัด kp, kd |
| [kp_kd_verification](kp_kd_verification.md) | วิเคราะห์ผลว่ามอเตอร์ให้แรงตาม kp/kd จริงไหม |
| [handover](handover.md) | ส่งหุ่นคืนให้ controller ของ Unitree (L1 + R1 แล้ว START) |
| [safe_shutdown](safe_shutdown.md) | ปิดหุ่นให้ปลอดภัย |

## คอม high-level ของหุ่น (192.168.123.164)
| หน้า | ใช้เมื่อ |
|---|---|
| [pc164_hi_level_cmd](pc164_hi_level_cmd.md) | เข้าเครื่อง, ตั้ง environment, systemd service ที่รันอยู่ |
| [ros2_cmd](ros2_cmd.md) | คำสั่ง ROS 2 บนเครื่องนั้น (topic, service, loco client, แขน) |
