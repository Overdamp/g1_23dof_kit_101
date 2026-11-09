# 1. terminal, path, cd

## ทุก terminal "ยืน" อยู่ในโฟลเดอร์หนึ่งเสมอ
เหมือนเราเปิดหน้าต่างไฟล์ค้างไว้ที่โฟลเดอร์หนึ่ง คำสั่งที่พิมพ์จะทำงาน**จากโฟลเดอร์นั้น** เว้นแต่จะบอก path เต็ม

```bash
pwd                 # ตอนนี้ยืนอยู่ที่ไหน (print working directory)
ls                  # ในโฟลเดอร์นี้มีอะไร
cd ~/nvidia/unitree # ย้ายไปโฟลเดอร์นี้ (~ = home ของเรา เช่น /home/you)
cd ..               # ถอยขึ้นไปหนึ่งชั้น
cd -                # กลับไปโฟลเดอร์ก่อนหน้า
```

## path เต็ม กับ path แบบ relative
| แบบ | ตัวอย่าง | ความหมาย |
|---|---|---|
| เต็ม (absolute) | `/home/you/nvidia/unitree/g1_23dof_kit` | ชี้ที่เดียวเสมอ ไม่ว่ายืนอยู่ไหน |
| เริ่มจาก home | `~/nvidia/unitree/g1_23dof_kit` | เหมือนข้างบน แต่สั้นกว่า และใช้ได้กับทุก user |
| relative | `scripts/doctor.sh` | นับจากโฟลเดอร์ที่ยืนอยู่ ยืนผิดที่ = หาไม่เจอ |

## ทำไมเรื่องนี้สำคัญในโปรเจคนี้
- `make` อ่าน `Makefile` **ในโฟลเดอร์ที่ยืนอยู่** ถ้ายืนอยู่ใน `build/` ของ cmake จะไปรันอีกไฟล์หนึ่งเลย ([หน้า 4](04_make.md))
- `g1_ctrl` อ่าน `config.yaml` ที่อยู่ข้างไฟล์โปรแกรม จึงต้อง `cd` เข้าไปใน `build/` ก่อนรัน
- สคริปต์จึงหาโฟลเดอร์ของตัวเองด้วย `$(dirname "$0")` แทนการเชื่อว่าคนเรียกยืนถูกที่ เช่น `run_*.sh` ใน unitree_rl_mjlab ขึ้นต้นด้วย `cd "$(dirname "$0")"` และสคริปต์ของ kit ใช้ `KIT="$(cd "$(dirname "$0")/.." && pwd)"` จะเรียกจากที่ไหนก็ได้ผลเหมือนกัน

## ลองพิมพ์
```bash
cd ~
ls scripts/doctor.sh                         # หาไม่เจอ: ไม่มีโฟลเดอร์ scripts ใน home
ls ~/nvidia/unitree/g1_23dof_kit/scripts/doctor.sh   # เจอ: path เต็ม
cd ~/nvidia/unitree/g1_23dof_kit && ls scripts/doctor.sh   # เจอ: ยืนถูกที่แล้ว
```

## คำถามท้ายบท
1. ยืนอยู่ที่ `~` แล้วพิมพ์ `bash scripts/doctor.sh` จะเกิดอะไรขึ้น
2. ทำไมคู่มือเขียน `~/nvidia/...` แทน `/home/you/nvidia/...`

<details><summary>เฉลย</summary>

1. `No such file or directory` เพราะ path แบบ relative นับจาก `~` ซึ่งไม่มีโฟลเดอร์ `scripts`
2. `~` จะแทนด้วย home ของคนที่พิมพ์ จึงใช้ได้กับทุกเครื่องและทุก user ส่วน `/home/you` ใช้ได้แค่บนเครื่องที่มี user ชื่อ you
</details>
