# ros2 cmd

> ย้ายมาจาก vault ของผู้ดูแล (`06 my_note/ros2 cmd.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-05

คำสั่ง ROS 2 ที่ใช้บนคอม high-level ของหุ่น (`192.168.123.164`, ROS 2 Foxy) แกะจาก `history` (5/11/2026)
ตั้ง environment ก่อนทุกครั้ง ดู [Hi-level cmd](pc164_hi_level_cmd.md) ข้อ 2:
```bash
conda deactivate
source ~/unitree_ros2/setup.sh
```

> [!NOTE]
> **ROS 2 topic กับ DDS topic ของเรา**
> ฝั่งคอมเราใช้ SDK อ่าน DDS ตรงๆ ชื่อ `rt/lowstate` · ใน ROS 2 ชื่อเดียวกันจะเห็นเป็น **`/lowstate`** (ROS ซ่อน prefix `rt/`) เป็นข้อมูลชุดเดียวกัน

> [!CAUTION]
> **service ของ loco / move base ทำให้หุ่นขยับจริง**
> ใช้ได้เฉพาะโหมด `ai` (controller ของ Unitree) · หุ่นต้องอยู่บนพื้นหรือแขวนตามแผน มีคนดู และพร้อมกด `damp`
> **ห้ามใช้ระหว่างเทส low-level ของเรา** (debug mode / sysid / g1_ctrl)

## 1. ดูว่ามีอะไรรันอยู่
```bash
ros2 node list            # node ที่รันอยู่ (เช่น g1_loco_client_node, g1_arm_joint_control)
ros2 topic list           # topic ทั้งหมด
ros2 service list         # service ทั้งหมด (ใช้เช็คว่า service ข้างล่างยังมีอยู่ไหม)
ros2 action list          # action ทั้งหมด
```

## 2. อ่านข้อมูลหุ่น (อ่านอย่างเดียว ปลอดภัย)
```bash
# สถานะมอเตอร์ทั้งตัว (เหมือน rt/lowstate) · ข้อมูลยาวมาก Ctrl-C หยุด
ros2 topic echo /lowstate
# ความถี่ของ lowstate (บนคอมเราวัดได้ ~1000 Hz ผ่าน ROS อาจต่ำกว่า)
ros2 topic hz /lowstate
# lowstate อีกช่อง (lf = low frequency)
ros2 topic hz /lf/lowstate
ros2 topic echo /lf/lowstate
# คำสั่งและคำตอบของ sport API (ดูว่าใครสั่ง loco อะไร)
ros2 topic echo /api/sport/request
ros2 topic echo /api/sport/response
# point cloud จาก Livox MID-360 บนหัว
ros2 topic echo /utlidar/cloud_livox_mid360
```

## 3. เปิดระบบของแลป (bringup)
```bash
# เปิด node ทั้งชุดของแลป (loco client, move base, behavior tree ...)
# ปกติ fibo_legged_robot_g1.service เปิดให้ตอนบูตแล้ว ถ้าจะรันมือให้ stop service ก่อน ไม่งั้นได้ node ซ้ำ
ros2 launch ros2_unitree_bringup g1_bringup.launch.xml
```

## 4. loco client: สั่งโหมดเดินของ Unitree (ต้องอยู่โหมด `ai`)
`std_srvs/srv/Trigger` = เรียกเฉยๆ ไม่มีค่า
```bash
# damping: มอเตอร์นิ่มลง หุ่นทรุด · ใช้เป็นปุ่มหยุดฝั่ง ROS
ros2 service call /g1_loco_client_node/damp std_srvs/srv/Trigger "{}"
# zero torque: ปล่อยแรงหมด (ไฟม่วง) · ต้องแขวนหรือนั่งอยู่
ros2 service call /g1_loco_client_node/zero_torque std_srvs/srv/Trigger "{}"
# ยืนขึ้นจากท่านั่ง/damping
ros2 service call /g1_loco_client_node/stand_up std_srvs/srv/Trigger "{}"
# เข้าโหมดพร้อมเดิน (รับคำสั่งความเร็ว) · ลำดับที่ใช้: damp → stand_up → start
ros2 service call /g1_loco_client_node/start std_srvs/srv/Trigger "{}"
# สลับโหมดเดิน / วิ่ง
ros2 service call /g1_loco_client_node/set_walk_motion_mode std_srvs/srv/Trigger "{}"
ros2 service call /g1_loco_client_node/set_run_mode std_srvs/srv/Trigger "{}"
# ขับด้วยคีย์บอร์ด (ส่ง /cmd_vel) หลัง start แล้ว
ros2 run teleop_twist_keyboard teleop_twist_keyboard
```

## 5. แขน (`g1_arm.py` / `g1_arm.service`)
```bash
# ยกแขนท่าหยิบ
ros2 service call /g1_arm_joint_control/move_joint_arms_pick std_srvs/srv/Trigger "{}"
# แขนกลับท่าพัก
ros2 service call /g1_arm_joint_control/move_joint_arms_home std_srvs/srv/Trigger "{}"
```

## 6. move base: เดินไปตำแหน่ง/มุมที่กำหนด (ต้อง `start` ก่อน)
```bash
# เปิดให้ controller ขับเอง
ros2 service call /robot_move_base_controller_node/enable_autonomous_moving std_srvs/srv/SetBool "data: true"
# เดินหน้า 1 m (ค่าลบ = ถอยหลัง)
ros2 service call /robot_move_base_controller_node/set_desired_relative_pos_x unitree_api/srv/SetDesiredSetpoint "value: 1.0"
# หมุนไปที่มุม (rad) เช่น 1.57 = 90°, 3.14 = 180°
ros2 service call /robot_move_base_controller_node/set_desired_angle unitree_api/srv/SetDesiredSetpoint "value: 1.57"
# ปิดโหมดขับเอง
ros2 service call /robot_move_base_controller_node/enable_autonomous_moving std_srvs/srv/SetBool "data: false"
```

## 7. behavior tree: ภารกิจ (mission)
```bash
ros2 service call /bt_executor/list_mission ros2_behavior_tree/srv/ListMission "{}"            # มีภารกิจอะไรบ้าง
ros2 service call /bt_executor/get_mission ros2_behavior_tree/srv/GetMission "name: 'Move'"     # ดูรายละเอียด
ros2 service call /bt_executor/set_mission ros2_behavior_tree/srv/SetMission "mission: 'Move'"  # เลือกภารกิจ
ros2 service call /bt_executor/execute std_srvs/srv/SetBool "data: true"                         # เริ่ม (false = หยุด)
```
ภารกิจที่เห็นใน history: `Move`, `MissionTree`

> [!WARNING]
> **ข้อ 6–7 อาจไม่มีแล้ว**
> ใน history ช่วงท้าย รุ่นพี่ลบ `ros2_behavior_tree`, `unitree_bt_plugins`, `ros2_unitree_api_client` ออกจาก `src/` แล้ว build ใหม่ เช็คด้วย `ros2 service list` ก่อนใช้

## 8. เครื่องมือ GUI (ต้องมีหน้าจอหรือ NoMachine)
```bash
rviz2     # ดูโมเดล, TF, point cloud
rqt       # ดู topic / เรียก service แบบกดปุ่ม / plot
```

## ดูเพิ่ม
[Hi-level cmd](pc164_hi_level_cmd.md) · [terminal cmd](terminal_cmd.md) · [Motion Switcher](../04-explanation/motion_switcher.md) · [LowState and LowCmd](../03-reference/lowstate_and_lowcmd.md)
