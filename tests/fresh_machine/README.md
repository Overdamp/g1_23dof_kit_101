# Phase 5: ทดสอบบนเครื่องเปล่า

เป้าหมาย: พิสูจน์ว่าคนที่ไม่มีอะไรในเครื่องเลย ทำตาม README + Day 1–2 แล้วผ่าน **โดยไม่ต้องใช้ของที่ผู้ดูแลตั้งไว้** (`~/.bashrc`, conda env เดิม, `local.mk`)
วิธี: สร้าง user ใหม่บนเครื่องเดิม ให้ home ว่าง ส่วน driver, apt และ `/opt/unitree_robotics` ใช้ร่วมกันทั้งเครื่อง

## 0. เตรียม (ผู้ดูแล, ต้อง sudo)
```bash
df -h /home                         # ต้องเหลือ ≥ 25 GB
sudo adduser g1test                 # ตั้งรหัสผ่านเอง ไม่ต้องใส่ในเอกสารใดๆ
```
ไม่ต้องให้ g1test อยู่กลุ่ม sudo: ขั้นที่ต้อง sudo (apt, sdk2 install) ทำไว้แล้วทั้งเครื่อง ถ้า Day 1 บอกให้ sudo ให้จดไว้ แล้วผู้ดูแลทำแทน

## 1. เข้าเป็น g1test
```bash
su - g1test                         # terminal ใหม่ home ว่าง
```
ขั้นที่เปิดหน้าต่าง GUI (MuJoCo, viewer) ต้องอนุญาตให้ g1test ใช้หน้าจอก่อน (รันจาก user หลัก):
```bash
xhost +SI:localuser:g1test          # ยกเลิกทีหลังด้วย xhost -SI:localuser:g1test
```
แล้วใน terminal ของ g1test: `export DISPLAY=:0` (ดูค่าจริงจาก `echo $DISPLAY` ของ user หลัก)

## 1.5 สิทธิ์ GitHub (repo kit เป็น private)
g1test ต้องโคลน `g1_23dof_kit_101` ได้: ใช้บัญชี GitHub ของผู้ทดสอบที่ถูกเพิ่มเป็น collaborator แล้ว ยืนยันตัวตนด้วย token หรือ `gh auth login` **ใน user g1test**
ถ้าขั้นนี้ติด ให้จดไว้ด้วย เพราะรุ่นน้องจะเจอแบบเดียวกัน

## 2. ติดตั้ง Miniconda (README บอกว่าต้องมี)
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/mc.sh
bash /tmp/mc.sh -b -p ~/miniconda3 && ~/miniconda3/bin/conda init bash && exec bash
```

## 3. ทำตามคู่มือ **ตามตัวอักษร**
README → Day 1 ขั้น 1–10 → Day 2 ขั้น 1–4 ใช้ `make clone` / `make envs` (**ห้าม** `set-ws` และห้ามดูโน้ตส่วนตัว)
ถ้าต้องเดาหรือทำนอกคู่มือ = นับเป็นจุดที่ติด แม้จะแก้ได้เองก็ตาม

## 4. จดผล
| เวลา | ขั้น (หน้า/ข้อ) | ผล | ข้อความ error / สิ่งที่ต้องเดา | แก้ที่ไหน |
|---|---|---|---|---|
| | README Quickstart | | | |
| | Day 1 ข้อ 3 `make clone` | | | |
| | Day 1 ข้อ 4 `make envs` | | | |
| | Day 1 ข้อ 6 `make build` | | | |
| | Day 1 ข้อ 7 `make doctor` | | | |
| | Day 1 ข้อ 8 `make smoke` | | | |
| | Day 1 ข้อ 9 `make sim2sim` | | | |
| | Day 2 ข้อ 2 `make train ITERS=500` | | | |
| | Day 2 ข้อ 4 `make play` | | | |

เวลารวมตั้งแต่ `git clone` ถึง `make doctor` 0 FAIL: ____ (เป้า: ภายในวันแรก)

## 5. เก็บกวาด (ผู้ดูแล)
```bash
xhost -SI:localuser:g1test
sudo deluser --remove-home g1test   # ลบ home ทั้งหมดของ g1test (คืนดิสก์ราว 15–20 GB) ย้อนกลับไม่ได้
```
ก่อนลบ: ก๊อปตารางผลออกมาไว้ใน ROADMAP หรือ issue ก่อน
