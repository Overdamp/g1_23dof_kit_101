# 4. make

## make คือโปรแกรมมาตรฐาน ไม่ใช่ของที่เราสร้าง
มากับแพ็กเกจ `build-essential` ของ Ubuntu (`make --version`) หน้าที่เดิมคือ build โปรแกรม C/C++ โดย compile ใหม่เฉพาะไฟล์ที่แก้
ตอน build `g1_ctrl` เราใช้ make ในหน้าที่นี้: `cmake` สร้างไฟล์ `Makefile` ไว้ใน `build/` แล้ว make เป็นตัว compile

## ใน kit นี้ใช้ make เป็น "ปุ่มลัด"
ของที่เราเขียนเองคือ**ไฟล์ `Makefile`** ส่วน make เป็นแค่ตัวอ่านไฟล์

```
make sim2sim POLICY=v0
 │      │       └─ ตัวแปรที่ส่งเข้าไป
 │      └─ ชื่อ target (ตั้งเองใน Makefile)
 └─ โปรแกรมมาตรฐาน
```

ในไฟล์ `Makefile` target หน้าตาแบบนี้:
```make
sim2sim: ## tmux: sim + g1_ctrl + speed monitor
	$(need_ws)
	$(in_sdk) bash $(SCRIPTS)/sim2sim_policy.sh $(POLICY)
```
บรรทัดใต้ชื่อคือคำสั่ง shell ที่จะรัน (ต้องขึ้นต้นด้วย **Tab** ใช้ช่องว่างแทนไม่ได้) คำสั่งเต็มของทุก target อยู่ใน [make_targets.md](../../03-reference/make_targets.md)

## make หา Makefile จากที่ไหน
จาก**โฟลเดอร์ที่ยืนอยู่**เท่านั้น ไม่ค้นที่อื่น
| ยืนอยู่ที่ | `make` จะ |
|---|---|
| โฟลเดอร์ kit | ใช้ปุ่มลัดของ kit |
| `.../g1_23dof/build/` | compile g1_ctrl ใหม่ (Makefile ของ cmake) |
| ที่อื่นที่ไม่มี Makefile | `No rule to make target` |

สั่งจากที่ไหนก็ได้: `make -C ~/nvidia/unitree/g1_23dof_kit <target>`

## ทำไมใช้ make แทนพิมพ์เอง
พิมพ์เองก็ได้ผลเหมือนกันทุกอย่าง แต่ make จำเรื่องที่เคยพลาดให้: เปิด env ให้ถูก, unset `CYCLONEDDS_URI`, ตั้ง `PYTHONPATH`, และตรวจก่อนต่อหุ่นจริง
**กฎของ kit:** แต่ละ target ยาวไม่เกิน 3 คำสั่ง และทุกสคริปต์รันได้โดยไม่ต้องใช้ make (`make check` ตรวจให้)

## ลองพิมพ์
```bash
cd ~/nvidia/unitree/g1_23dof_kit
make                       # รายการ target
make -n sim2sim POLICY=v0  # ดูคำสั่งจริง ไม่รัน
make -n doctor
cd ~ && make doctor        # error: ไม่มี Makefile ใน home
make -C ~/nvidia/unitree/g1_23dof_kit -n doctor   # ใช้ได้
```

## คำถามท้ายบท
1. `make sim2sim` compile อะไรไหม
2. อยากรู้ว่า `make deploy-real` ตรวจอะไรบ้าง ต้องเปิดไฟล์ไหน

<details><summary>เฉลย</summary>

1. ไม่ compile แค่เปิด env แล้วเรียก `sim2sim_policy.sh`
2. `scripts/real_robot_guard.sh` (มีคอมเมนต์ว่าแต่ละข้อกันอะไร) หรือดูจาก `make -n deploy-real IFACE=enp43s0`
</details>
