# 2. ตัวแปร environment

## เหมือนโน้ตที่แปะไว้บนกระดานของ terminal
แต่ละหน้าต่าง terminal มีกระดานโน้ตของตัวเอง โปรแกรมทุกตัวที่เปิดจาก terminal นั้นจะอ่านโน้ตบนกระดานก่อนเริ่มทำงาน

| คำสั่ง | เทียบกับ |
|---|---|
| `export NAME=ค่า` | แปะโน้ต |
| `unset NAME` | ดึงโน้ตออก |
| `echo $NAME` | อ่านโน้ต (ว่างเปล่า = ไม่มีโน้ต) |
| `NAME=ค่า โปรแกรม` | แปะโน้ตให้โปรแกรมนี้ตัวเดียว ไม่ค้างบนกระดาน |
| `env -u NAME โปรแกรม` | ซ่อนโน้ตจากโปรแกรมนี้ตัวเดียว |

## กฎสำคัญ 3 ข้อ
1. **โน้ตอยู่แค่ใน terminal ที่แปะ** เปิดหน้าต่างใหม่ = กระดานใหม่
2. **`~/.bashrc` คือสคริปต์ที่รันทุกครั้งที่เปิด terminal ใหม่** ถ้าเขียน `export` ไว้ในนั้น โน้ตจะติดมากับทุกหน้าต่าง (นี่คือที่มาของโน้ตที่ "ค้าง" โดยไม่รู้ตัว)
3. **โปรแกรมลูกเห็นโน้ตของแม่** แต่โปรแกรมลูกแก้โน้ตของแม่ไม่ได้

## ตัวแปรที่เจอในโปรเจคนี้
| ตัวแปร | ใครอ่าน | ไว้ทำอะไร |
|---|---|---|
| `PATH` | shell | หาโปรแกรมจากชื่อ (`python` คือตัวไหน) conda เปลี่ยนค่านี้ตอน activate |
| `PYTHONPATH` | Python | โฟลเดอร์ที่ให้หาโค้ดก่อน ([หน้า 7](07_git_worktree_and_pythonpath.md)) |
| `LD_LIBRARY_PATH` | โปรแกรม C++ | หาไฟล์ `.so` เช่น `/opt/unitree_robotics/lib` |
| `CYCLONEDDS_URI` | Cyclone DDS | บังคับใช้การ์ดเครือข่าย ([หน้า 5](05_dds_domain_interface.md)) |
| `ROS_DOMAIN_ID` | ROS 2 | ช่องสื่อสารของ ROS |
| `RMW_IMPLEMENTATION` | ROS 2 | เลือก DDS ([หน้า 6](06_ros2_vs_unitree_sdk.md)) |

## ลองพิมพ์
```bash
echo "โน้ต: [$TEST_NOTE]"        # โน้ต: []
export TEST_NOTE=สวัสดี
echo "โน้ต: [$TEST_NOTE]"        # โน้ต: [สวัสดี]
bash -c 'echo "ลูกเห็น: [$TEST_NOTE]"'               # ลูกเห็น: [สวัสดี]
env -u TEST_NOTE bash -c 'echo "ลูกเห็น: [$TEST_NOTE]"'   # ลูกเห็น: []
unset TEST_NOTE
echo "โน้ต: [$TEST_NOTE]"        # โน้ต: []
env | sort | less                # ดูโน้ตทั้งหมดบนกระดาน (q = ออก)
```
แล้วลองเปิด terminal ใหม่ พิมพ์ `echo $TEST_NOTE` จะเห็นว่าว่าง

## คำถามท้ายบท
1. ใส่ `export X=1` ไว้ใน `~/.bashrc` แล้ว terminal ที่เปิดค้างอยู่ก่อนหน้าจะเห็น `X` ไหม
2. ทำไม target ของ make ใช้ `env -u CYCLONEDDS_URI ...` แทน `unset CYCLONEDDS_URI`

<details><summary>เฉลย</summary>

1. ไม่เห็น `.bashrc` รันตอนเปิด terminal เท่านั้น ต้องเปิดหน้าต่างใหม่ หรือพิมพ์ `source ~/.bashrc`
2. `env -u` ซ่อนโน้ตจากโปรแกรมนั้นตัวเดียว ไม่ไปแตะกระดานของ terminal คุณ ถ้าคุณตั้งใจ set ไว้ใช้กับ ROS ค่าก็ยังอยู่เหมือนเดิม
</details>
