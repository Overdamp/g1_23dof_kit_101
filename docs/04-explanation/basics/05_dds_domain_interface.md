# 5. DDS, domain, interface

## DDS คือระบบส่งข้อความระหว่างโปรแกรม
โปรแกรมไม่ต้องรู้ว่าอีกฝั่งอยู่เครื่องไหน แค่ประกาศ "ฉันส่ง topic ชื่อ `rt/lowcmd`" อีกฝั่งประกาศ "ฉันรับ `rt/lowcmd`" DDS จะหากันและส่งให้เอง
- `rt/lowstate`: หุ่น (หรือ sim) → เรา: มุมข้อต่อ, ความเร็ว, IMU หลายร้อยครั้งต่อวินาที
- `rt/lowcmd`: เรา → หุ่น: ท่าเป้าหมาย, kp, kd ของมอเตอร์ทุกตัว

ใน Unitree SDK, g1_ctrl และ unitree_mujoco ใช้ DDS ยี่ห้อ **Cyclone DDS**

## สองค่าที่ตัดสินว่าใครได้ยินใคร
| ค่า | เทียบกับ | ในโปรเจคนี้ |
|---|---|---|
| **interface** (การ์ดเครือข่าย) | สายที่ใช้คุย | `lo` = วงในเครื่องตัวเอง · `enp43s0` = สายแลนไปหุ่น (ชื่อต่างกันได้แต่ละเครื่อง ดูด้วย `ip -br addr`) |
| **domain** | ช่องวิทยุ | `1` = sim ของเรา · `0` = หุ่นจริง |

สองโปรแกรมจะคุยกันได้ต้อง**อยู่บนสายเดียวกัน และเปิดช่องเดียวกัน**
domain **ไม่ใช่**เครื่อง: คอมสองเครื่องในหุ่น (.161 low-level, .164 high-level) ใช้ domain 0 ทั้งคู่ แยกกันด้วย IP

## kit ตั้งให้ปลอดภัยโดยไม่ต้องจำ
| | interface | domain | วิธีสั่ง |
|---|---|---|---|
| **sim** (ค่าเริ่มต้นทุกโปรแกรม) | `lo` | 1 | ไม่ต้องใส่อะไร หรือ `--network lo` |
| **หุ่นจริง** | `enp43s0` | 0 | ต้องใส่ `--network enp43s0` เอง domain เป็น 0 ให้อัตโนมัติ |

บรรทัดแรกที่โปรแกรมพิมพ์ออกมาจะบอกเสมอ เช่น `DDS: domain 1 on lo (SIM, keyboard on)` **อ่านบรรทัดนี้ทุกครั้ง**
ถ้า sim ใช้ domain 0 เหมือนหุ่น คำสั่งที่ตั้งใจส่งให้ sim อาจไปถึงหุ่นจริงที่ต่อสายอยู่ได้ นี่คือเหตุผลที่แยกช่อง

## CYCLONEDDS_URI: โน้ตที่บอกว่า "ใช้สายนี้เท่านั้น"
(ทบทวนเรื่องโน้ตใน [หน้า 2](02_environment_variables.md))
- **มีโน้ต** → ทุกโปรแกรม Cyclone DDS ใน terminal นั้นใช้สายตามโน้ต **ไม่สน `--network`**
- **ไม่มีโน้ต** → ทำตาม `--network`

| terminal ไว้ทำ | โน้ต | เพราะ |
|---|---|---|
| ROS 2 | **set** (`export CYCLONEDDS_URI=...` เอง หรือ `source unitree_ros2/setup.sh`) | ROS ไม่มี `--network` ให้เลือก ต้องบอกผ่านโน้ต |
| Unitree SDK, g1_ctrl, `make ...` | **unset** | มี `--network` อยู่แล้ว โน้ตเก่าจะมาขวาง |

อาการที่พบเมื่อลืม: g1_ctrl ค้างที่ "Waiting for connection" โดยไม่มี error ใดๆ

## ลองพิมพ์
```bash
ip -br addr                       # การ์ดเครือข่ายทั้งหมดและ IP
ip link show lo | grep MULTICAST  # sim ต้องมีคำนี้ (DDS หากันด้วย multicast)
echo "[$CYCLONEDDS_URI]"          # [] = ไม่มีโน้ต ดีแล้ว
make doctor                       # หมวด DDS / network ตรวจเรื่องเหล่านี้ให้
```

## คำถามท้ายบท
1. เปิด sim อยู่ แล้วรัน `g1_ctrl --network enp43s0` จะคุยกับ sim ไหม
2. terminal เพิ่ง `source unitree_ros2/setup.sh` ไป แล้วรัน `g1_ctrl --network lo` ทำไมอาจไม่เจอ sim

<details><summary>เฉลย</summary>

1. ไม่ เพราะ sim อยู่บน `lo` domain 1 แต่ g1_ctrl ไปที่ `enp43s0` domain 0 คนละสาย คนละช่อง
2. `setup.sh` set `CYCLONEDDS_URI` ไว้ที่การ์ดของหุ่น (`enp3s0`) โน้ตนี้ทับ `--network lo` ต้อง unset ก่อนหรือเปิด terminal ใหม่
</details>
