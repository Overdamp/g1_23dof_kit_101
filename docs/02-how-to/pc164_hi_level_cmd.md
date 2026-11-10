# Hi-level cmd

> ย้ายมาจาก vault ของผู้ดูแล (`06 my_note/Hi-level cmd.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-05

คำสั่งที่ใช้บน **คอม high-level ของหุ่น (PC2, `192.168.123.164`)** แกะจาก `history` บนเครื่องนั้น (บันทึก 5/11/2026) เลือกเฉพาะที่ใช้งานจริง ตัดคำสั่งติดตั้ง/แก้ apt ที่ลองผิดลองถูกออก
คำสั่ง ROS 2 (topic, service, launch) อยู่ใน [ros2 cmd](ros2_cmd.md) · คำสั่งฝั่งคอมเรา: [terminal cmd](terminal_cmd.md)

> [!NOTE]
> **เครื่องนี้คืออะไร**
> - Jetson (aarch64) · Ubuntu 20.04 · ROS 2 **Foxy** · user `unitree`
> - คนละเครื่องกับบอร์ด motion control (`.161`) ที่ส่ง `rt/lowstate` และรับ `rt/lowcmd`
> - มีของรุ่นพี่/แลปติดตั้งไว้: `unitree_ros2`, กล้อง RealSense, mediamtx (สตรีมภาพ), แขน Inspire, xr_teleoperate, service ของ FIBO ที่เปิดเองตอนบูต

## 1. เข้าเครื่อง
```bash
# จากคอมเรา (ต้องตั้ง IP enp43s0 แล้ว ดู terminal cmd ข้อ 0) · ครั้งแรกตอบ yes ให้จำ host key
ssh unitree@192.168.123.164
# ออก
exit            # หรือ logout
```

## 2. ตั้ง environment (ทุกครั้งที่เปิด terminal ใหม่)
```bash
# เครื่องนี้เปิด conda (base) อัตโนมัติ · ROS 2 Foxy ใช้ python ของระบบ ต้องปิด conda ก่อน
conda deactivate
# โหลด ROS 2 Foxy + unitree_ros2 + CycloneDDS ที่ตั้งค่าให้คุยกับหุ่น (สคริปต์ปิด conda ให้ด้วย)
source ~/unitree_ros2/setup.sh
```
> [!WARNING]
> ถ้าเจอ `ModuleNotFoundError: No module named 'rclpy'` = ลืม `source ~/unitree_ros2/setup.sh` (เคยเกิด 5/11 ตอนรัน `g1_arm.py`)

## 3. ต่ออินเทอร์เน็ต (ชั่วคราว)
```bash
# ให้ออกเน็ตผ่าน router ของแลป (192.168.123.254) · หายเมื่อรีบูต · ใช้ตอน apt / git clone
sudo ip route add default via 192.168.123.254 dev eth0
ping -c 3 www.google.com
```

## 4. systemd service ที่รันอยู่บนเครื่องนี้
service เหล่านี้**เปิดเองตอนบูต** (มีที่ enable ไว้) บางตัวสั่งหุ่นได้

| service | ทำอะไร (จากชื่อและ history) | สั่งหุ่นไหม |
|---|---|---|
| `fibo_legged_robot_g1.service` | รัน `g1_bringup.launch.xml` ของแลป: loco client, move base, behavior tree | **ได้** (สั่งเดินผ่าน sport API) |
| `g1_arm.service` | รัน `~/g1_arm.py` (node `g1_arm_joint_control`, ท่า pick / home) | **ได้** (แขน) |
| `g1_arm_web.service` | รัน `~/g1_arm_web.py` หน้าเว็บกดท่าแขน | ได้ (ผ่าน g1_arm) |
| `realsense_gst.service` | สตรีมกล้อง RealSense D455 ด้วย GStreamer | ไม่ |
| `mediamtx_arm_linux.service` | RTSP server สำหรับสตรีมภาพ | ไม่ |

```bash
# ดูสถานะ (active/inactive, enabled ตอนบูตไหม, log ล่าสุด) · กด q ออก
sudo systemctl status fibo_legged_robot_g1.service
# หยุด / เริ่ม / เริ่มใหม่
sudo systemctl stop  fibo_legged_robot_g1.service
sudo systemctl start fibo_legged_robot_g1.service
sudo systemctl restart realsense_gst.service
# ดู log ย้อนหลัง / ตามดูสด
journalctl -u fibo_legged_robot_g1.service --since "5 minutes ago"
sudo journalctl -fu realsense_gst.service
# หลังแก้ไฟล์ /etc/systemd/system/<ชื่อ>.service ต้อง reload ก่อน
sudo systemctl daemon-reload
# เปิด / ปิด ให้รันเองตอนบูต
sudo systemctl enable  g1_arm.service
sudo systemctl disable g1_arm.service
```

> [!CAUTION]
> **ก่อนเทส low-level (sysid / g1_ctrl) ของเรา**
> service ที่สั่งหุ่นได้ (`fibo_legged_robot_g1`, `g1_arm`, `g1_arm_web`) อาจส่งคำสั่งแข่งกับเรา
> 1. เช็คก่อนเริ่ม:
>    ```bash
>    systemctl is-active fibo_legged_robot_g1 g1_arm g1_arm_web
>    ps -eo pid,etime,cmd | grep -E "python3|ros2" | grep -v grep
>    ```
> 2. ถ้า active ให้ `sudo systemctl stop <ชื่อ>` (ไม่ใช่ kill) และแจ้งรุ่นพี่ที่ใช้ service นั้น
> 3. **ยังไม่ยืนยัน:** 3/11 เราเห็น `python3` บน 164 ที่ส่ง lowcmd ~1 kHz ตอนอยู่โหมด `ai` อาจเป็นหนึ่งใน service ข้างบน (เช่น `g1_arm.py`) หรือ controller ของ Unitree เอง ครั้งหน้าดูด้วยคำสั่งข้อ 1 แล้วจดชื่อไว้

## 5. build workspace ROS 2 (`~/unitree_ros2/cyclonedds_ws`)
```bash
# build CycloneDDS + rmw ของ unitree_ros2 (ทำครั้งแรก หรือเมื่อ clone ใหม่)
source ~/unitree_ros2/scripts/build_cyclone_foxy.sh
# build package ของแลปหลังแก้โค้ด/launch (ต้อง source Foxy ก่อน ไม่ใช่ setup.sh)
cd ~/unitree_ros2/cyclonedds_ws
source /opt/ros/foxy/setup.bash
colcon build                      # หรือ --symlink-install ให้แก้ python/launch แล้วไม่ต้อง build ใหม่
# ถ้า service ใช้ package นี้อยู่ ให้ restart หลัง build
sudo systemctl restart fibo_legged_robot_g1.service
```
ไฟล์ launch หลัก: `~/unitree_ros2/cyclonedds_ws/src/ros2_unitree_bringup/launch/g1_bringup.launch.xml`

## 6. สคริปต์แขน (`~/g1_arm.py`)
```bash
source ~/unitree_ros2/setup.sh
# รันมือ (ถ้า g1_arm.service รันอยู่แล้ว อย่ารันซ้ำ จะได้สอง node แย่งกัน) · Ctrl-C หยุด
python3 g1_arm.py
```
สั่งท่าผ่าน service: ดู [ros2 cmd](ros2_cmd.md) ข้อ 5

## 7. กล้อง / สตรีม / หน้าจอ
```bash
# สตรีม RealSense แบบรันมือ (หยุด service ก่อน กล้องใช้ได้ทีละโปรแกรม)
sudo systemctl stop realsense_gst.service
cd ~/unitree_ros2/external/GstRealsense/ && python3 gst_realsense_d455f.py
# image server ของ xr_teleoperate (env teleimager)
source ~/miniconda3/etc/profile.d/conda.sh && conda activate teleimager
cd ~/xr_teleoperate/teleop/teleimager && python -m teleimager.image_server
# เปิด NoMachine (remote desktop) ไว้ใช้ rviz2 / rqt จากเครื่องอื่น
./nomachine.sh
```

## 8. เช็คฮาร์ดแวร์ USB (กล้อง, มือ Inspire)
```bash
lsusb                                          # อุปกรณ์ที่เสียบอยู่
ls -l /dev/ttyUSB* /dev/ttyACM* 2>/dev/null    # พอร์ต serial (มือ Inspire)
sudo dmesg -w                                  # ดู kernel log สดตอนเสียบ/ถอด
```

## สิ่งที่ตัดออก (ไม่ต้องทำซ้ำ)
- ติดตั้ง/แก้ apt source ของ ROS (ประวัติ ~806–1003 ลองหลายแบบ ตอนนี้ใช้ได้แล้ว)
- ติดตั้ง Docker และ `systronics_graphql_sqlite` (งาน mission DB ของแลป)
- build `dfx_inspire_service` (ไดรเวอร์มือ Inspire)
- `rm -rf` package ใน `src/` หลายรอบ (รุ่นพี่ลบ/clone ใหม่ระหว่างพัฒนา)


## ดูเพิ่ม
[ros2 cmd](ros2_cmd.md) · [Network Setup](network_setup.md) · [Motion Switcher](../04-explanation/motion_switcher.md) · [Stop Mechanisms](../04-explanation/stop_mechanisms.md)
