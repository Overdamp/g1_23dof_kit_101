# Network Setup

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Network Setup.md`) เมื่อ 10/11/2026

| รายการ | ค่า |
|---|---|
| PC | `192.168.123.123/24` บน `enp43s0` |
| บอร์ด low-level ของหุ่น | `192.168.123.161` |
| Unitree DDS | domain 0 |
| ROS 2 (g1pilot) | `ROS_DOMAIN_ID=1` |

```bash
sudo ip addr add 192.168.123.123/24 dev enp43s0 && sudo ip link set enp43s0 up
sudo ip link set lo multicast on          # หายทุกครั้งที่รีบูตคอมพ์ (จำเป็นสำหรับ sim)
ip -br addr show enp43s0                  # UP + 192.168.123.123/24
ping -c 3 192.168.123.161                 # 0% packet loss
```

## RViz mirror (อ่านอย่างเดียว)
```bash
cd ~/Ros2_Directory/g1pilot_ws/src/docker && ./run_real.sh
# ใน container:
./cbuild g1pilot
source /ros2_ws/setup_uri.sh $G1_INTERFACE
ros2 launch g1pilot robot_state_23dof.launch.py use_rviz:=true
```
- **ห้ามรัน `bringup_23dof.launch.py`** ตอนใช้ g1_ctrl (`loco_client` เรียก `Damp()` ทันที)
- ปิด RViz ก่อนส่งคำสั่งมอเตอร์ ลดภาระ PC

## เครื่องในหุ่น
| IP | เครื่อง | SSH |
|---|---|---|
| 192.168.123.161 | บอร์ดควบคุมการเคลื่อนที่ (controller `ai`, บัสมอเตอร์) | ❌ ปิด · ใช้ `ping` เช็คสายเท่านั้น |
| 192.168.123.164 | คอมนักพัฒนา (Jetson Orin) | ✅ `ssh unitree@192.168.123.164` (รหัสพิมพ์เอง) |
| 192.168.123.123 | คอมเรา | – |

- รันบนคอมเรา (สาย LAN) หรือบน 164 ก็ส่ง DDS ไป 161 เหมือนกัน · ช่วงบนรอกใช้คอมเรา
- **ห้ามสองเครื่องส่ง lowcmd พร้อมกัน** → ก่อนรัน g1_ctrl/sysid ต้อง `release` แล้ว `robot_health.py` ได้ `lowcmd 0`
- **lowcmd ~1 kHz ตอนโหมด `ai` (3/11, ยังไม่ยืนยันเต็ม):** หลังบูตเห็น kp 0 / kd 5.0 (ขา) 0.2 (แขน) · `python3` บน 164 ใช้ CPU ~100% ตั้งแต่บูต · kill แล้ว lowcmd หยุด · **หลัง Handover (SelectMode `ai`) กลับมาเองเป็น kp 0 / kd 0** ตรงกับไฟม่วง → น่าจะเป็น controller `ai` ของ Unitree (motion_switcher เปิดใหม่) **ไม่ใช่สคริปต์ของคนอื่น** → อย่า kill ใช้ `motion_mode.py release` แทน · ยืนยัน: บน 164 `ps -eo pid,user,etime,pcpu,args | grep python` หลัง `select ai` ดูว่า etime เริ่มใหม่ไหม
- บน 164 ฆ่าด้วย PID: `kill -INT <pid>` (`pkill` รับชื่อ) · อย่าฆ่า service ของ Unitree

## ปัญหาที่เจอ
ดู [DDS and Domains](../04-explanation/dds_and_domains.md) และ [Troubleshooting](troubleshooting.md)

## ดูเพิ่ม
[Test Day Procedure](test_day_procedure.md) · [Real Robot Tools](../03-reference/real_robot_tools.md)
