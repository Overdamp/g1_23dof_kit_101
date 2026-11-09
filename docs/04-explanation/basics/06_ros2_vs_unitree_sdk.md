# 6. ROS 2 กับ Unitree SDK

## ทั้งสองคุยผ่าน DDS แต่เป็นคนละชั้น
```
        ROS 2  (ros2 topic, launch, rviz, g1pilot, บริการของแลปบน .164)
          │  เลือก DDS ผ่าน RMW_IMPLEMENTATION
          ▼
  ┌──────────────── DDS ────────────────┐
  │  Fast DDS   หรือ   Cyclone DDS      │
  └─────────────────────────────────────┘
          ▲
          │  ใช้ Cyclone DDS เสมอ
  Unitree SDK  (unitree_sdk2 C++, unitree_sdk2py, g1_ctrl, unitree_mujoco)
```

| | Unitree SDK | ROS 2 |
|---|---|---|
| คืออะไร | library ของ Unitree สำหรับคุยกับหุ่นโดยตรง | framework หุ่นยนต์ทั่วไป มีเครื่องมือเยอะ |
| ในโปรเจคนี้ใช้ทำ | ควบคุมมอเตอร์ low-level (`rt/lowcmd`), อ่าน `rt/lowstate` | ของ high-level บน .164: เดินด้วย controller ของ Unitree, แขน, กล้อง |
| เลือกสาย (interface) | `--network` | ผ่านโน้ต `CYCLONEDDS_URI` ([หน้า 5](05_dds_domain_interface.md)) |
| เลือกช่อง | `--domain` (kit เลือกให้) | `ROS_DOMAIN_ID` |
| ชื่อ topic | `rt/lowstate` | `/lowstate` (ROS ซ่อนคำนำหน้า `rt/`) ข้อมูลชุดเดียวกัน |

**งานควบคุมมอเตอร์ทั้งหมดของ kit ไม่ใช้ ROS** ใช้ Unitree SDK อย่างเดียว ROS เป็นเรื่องฝั่ง high-level

## Fast DDS กับ Cyclone DDS
DDS มีหลายยี่ห้อ ทุกยี่ห้อพูดโปรโตคอลมาตรฐานเดียวกัน (RTPS) แต่ค่าตั้งและพฤติกรรมต่างกัน

| ROS 2 รุ่น | DDS เริ่มต้น |
|---|---|
| Foxy (บน .164), Humble, Jazzy | **Fast DDS** |
| Galactic | Cyclone DDS |

Unitree SDK ใช้ Cyclone ถ้า ROS ใช้ยี่ห้อเดียวกัน การค้นหากันและ QoS จะตรงกันแน่นอน Unitree จึงให้ ROS ใช้ Cyclone ด้วย:
```bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp    # ต้องติดตั้ง ros-<distro>-rmw-cyclonedds-cpp
```
`unitree_ros2/setup.sh` และ g1pilot ตั้งค่านี้ให้แล้ว

**ผลที่ตามมา:** ถ้า ROS ยังใช้ Fast DDS อยู่ `CYCLONEDDS_URI` จะ**ไม่มีผลกับ ROS เลย** (Fast DDS ตั้งการ์ดผ่านไฟล์ XML ของตัวเองที่ชี้ด้วย `FASTDDS_DEFAULT_PROFILES_FILE`) แต่ยังมีผลกับโปรแกรมของ Unitree SDK เหมือนเดิม

## ลองพิมพ์ (เครื่องที่ติดตั้ง ROS 2)
```bash
echo "RMW=[$RMW_IMPLEMENTATION] DOMAIN=[$ROS_DOMAIN_ID]"   # ว่าง = Fast DDS, domain 0
ls /opt/ros/*/lib | grep -E "librmw_(cyclonedds|fastrtps)_cpp.so"   # มียี่ห้อไหนติดตั้งไว้
```

## คำถามท้ายบท
1. จะดู `rt/lowstate` ของ sim ต้องเปิด ROS ไหม
2. set `CYCLONEDDS_URI` แล้ว `ros2 topic list` ยังเห็น topic จากการ์ดอื่น เพราะอะไร

<details><summary>เฉลย</summary>

1. ไม่ต้อง ใช้ `lowstate_monitor.py` (Unitree SDK, env `g1_sdk`) ได้เลย
2. ROS น่าจะใช้ Fast DDS อยู่ (ไม่ได้ตั้ง `RMW_IMPLEMENTATION`) จึงไม่อ่านโน้ตของ Cyclone
</details>
