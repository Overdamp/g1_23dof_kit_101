# Day 1: ติดตั้ง และเห็นหุ่นเดินใน sim

> ยังไม่เคยใช้ terminal, conda, make หรือ DDS: อ่าน [พื้นฐาน 8 หน้า](../04-explanation/basics/README.md) ก่อน

**เป้าหมาย:** จบวันนี้ `make doctor` ได้ 0 FAIL และบังคับหุ่นเดินใน sim ด้วยคีย์บอร์ดได้
**เวลา:** ครึ่งวันถึงหนึ่งวัน (ส่วนใหญ่เป็นเวลาดาวน์โหลดและ build)

ทุกขั้นแสดง**คำสั่งเต็ม**ก่อน แล้วจึงบอกทางลัด `make` ที่ทำแบบเดียวกัน ครั้งแรกให้ลองพิมพ์คำสั่งเต็มเพื่อเข้าใจ ครั้งต่อไปใช้ทางลัดได้

---

## 1. โคลน kit และดูเมนู
> [!IMPORTANT]
> repo นี้เป็น **private** (มีข้อมูลภายในแลป) ก่อนโคลนต้อง (ดู README)
> 1. มีบัญชี GitHub และให้ผู้ดูแลเพิ่มเป็น collaborator ของ `Overdamp/g1_23dof_kit_101`
> 2. ตั้งการยืนยันตัวตนบนเครื่องอย่างใดอย่างหนึ่ง: `gh auth login` (GitHub CLI) หรือ personal access token (ใส่แทนรหัสผ่านตอน git ถาม) หรือ SSH key
>
> repo อื่นใน `repos.lock` เป็น public โคลนได้โดยไม่ต้องยืนยันตัวตน

```bash
git clone https://github.com/Overdamp/g1_23dof_kit_101.git ~/nvidia/unitree/g1_23dof_kit
cd ~/nvidia/unitree/g1_23dof_kit
make
```
**ผลที่ต้องเห็น:** รายการ target แบ่งเป็นหมวด (Start here, Setup, Training, ...)

## 2. แพ็กเกจของระบบ (ต้อง sudo)
**คำสั่งเต็ม:**
```bash
sudo apt install -y git cmake build-essential tmux byobu libyaml-cpp-dev \
  libboost-all-dev libeigen3-dev libspdlog-dev libfmt-dev libglfw3-dev zlib1g-dev
```
**ทางลัด:** `make apt` จะพิมพ์คำสั่งนี้ออกมาให้ก๊อป (make ไม่รัน sudo ให้)

**ผลที่ต้องเห็น:** apt จบโดยไม่มีบรรทัดที่ขึ้นต้นด้วย `E:`

## 3. โคลน repo ที่ต้องใช้
**คำสั่งเต็ม:** อ่าน `repos.lock` แล้วทำทีละแถว เช่น
```bash
git clone --branch phase3-delay-dr https://github.com/Overdamp/unitree_rl_mjlab.git repos/unitree_rl_mjlab
git -C repos/unitree_rl_mjlab checkout cba2434
# ... ทำแบบเดียวกันกับ unitree_sdk2 และ unitree_sdk2_python
```
**ทางลัด:** `make clone` (`scripts/clone_repos.sh` ข้ามตัวที่มีอยู่แล้ว ไม่เขียนทับ)

มี repo อยู่แล้วที่อื่น: ข้ามขั้นนี้ แล้วสั่ง `make set-ws WS=<โฟลเดอร์ที่มี unitree_rl_mjlab>` ครั้งเดียว

**ผลที่ต้องเห็น:** `ls repos/` มี 3 โฟลเดอร์

## 4. conda env สองตัว
**คำสั่งเต็ม:**
```bash
conda env create -f envs/unitree_rl_mjlab.yml
conda run -n unitree_rl_mjlab pip install -e repos/unitree_rl_mjlab
conda env create -f envs/g1_sdk.yml
conda run -n g1_sdk pip install -e repos/unitree_sdk2_python
```
**ทางลัด:** `make envs`

**ผลที่ต้องเห็น:** `conda env list` มี `unitree_rl_mjlab` และ `g1_sdk` (ทำไมต้องมีสองตัว: [basics/03](../04-explanation/basics/03_conda_envs.md))

## 5. unitree_sdk2 (library C++ สำหรับคุยกับหุ่น)
**คำสั่งเต็ม:**
```bash
cmake -S repos/unitree_sdk2 -B repos/unitree_sdk2/build -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=/opt/unitree_robotics
cmake --build repos/unitree_sdk2/build -j$(nproc)
sudo cmake --install repos/unitree_sdk2/build
```
**ทางลัด:** `make sdk2` (ทำสองคำสั่งแรก แล้วพิมพ์บรรทัด sudo ให้คุณรันเอง)

**ผลที่ต้องเห็น:** `ls /opt/unitree_robotics/lib` มี `libunitree_sdk2.a` และ `libddsc.so`

## 6. build sim และตัวควบคุม
**คำสั่งเต็ม:**
```bash
cmake -S repos/unitree_rl_mjlab/simulate -B repos/unitree_rl_mjlab/simulate/build -DCMAKE_BUILD_TYPE=Release
cmake --build repos/unitree_rl_mjlab/simulate/build -j$(nproc)
R=repos/unitree_rl_mjlab/deploy/robots/g1_23dof
cmake -S $R -B $R/build -DCMAKE_BUILD_TYPE=Release
cmake --build $R/build -j$(nproc)
```
**ทางลัด:** `make build`

**ผลที่ต้องเห็น:** มีไฟล์ `simulate/build/unitree_mujoco` และ `deploy/robots/g1_23dof/build/g1_ctrl`

## 7. ตรวจเครื่อง
```bash
make doctor          # = bash scripts/doctor.sh (อ่านอย่างเดียว ไม่แก้อะไร)
```
**ผลที่ต้องเห็น:** บรรทัดสุดท้าย `0 FAIL` (WARN มีได้ ถ้าอ่านแล้วเข้าใจว่าทำไม)
ถ้ามี FAIL ใต้บรรทัดนั้นจะมี `->` บอกวิธีแก้ ที่เจอบ่อยคือ `lo multicast off` แก้ด้วย `sudo ip link set lo multicast on`

## 8. ทดสอบเร็ว
```bash
make smoke           # = make check + bash tests/smoke.sh
```
**ผลที่ต้องเห็น:** `check: all PASS` ตามด้วย `PASS` สองครั้ง ใช้เวลาไม่ถึงหนึ่งนาทีบนเครื่องที่ติดตั้งแล้ว

## 9. Sim2sim ด้วยตา
**คำสั่งเต็ม:**
```bash
conda activate g1_sdk
cd repos/unitree_rl_mjlab
unset CYCLONEDDS_URI                       # ทำไม: basics/05
bash deploy/robots/g1_23dof/scripts/sim2sim_policy.sh v0
```
**ทางลัด:** `make sim2sim POLICY=v0`

สคริปต์จะเปิดหน้าต่างภาพ MuJoCo แล้วพาเข้า tmux session ชื่อ `sim2sim` ให้เลย
(ถ้าออกมาแล้วจะกลับเข้าไปใหม่: `tmux attach -t sim2sim`)

ใน session มี 3 pane ในหน้าเดียว (tmux คืออะไร: [basics/08](../04-explanation/basics/08_tmux_and_byobu.md))
```
+----------------------+----------------------+
| unitree_mujoco (log) | g1_ctrl              |
+----------------------+  ← พิมพ์คีย์ที่นี่     |
| sim_speed_monitor    |   (ถูกเลือกไว้แล้ว)    |
+----------------------+----------------------+
```
pane ซ้ายบนเป็นแค่**ข้อความ log** ของ sim ภาพหุ่นอยู่ในหน้าต่าง MuJoCo แยกต่างหาก
เลือก pane: **คลิกเมาส์** (หรือ `Ctrl+b` ปล่อย แล้วกดลูกศร) · ขยาย pane เต็มจอ: `Ctrl+b` ปล่อย แล้ว `z`

1. หน้าต่าง MuJoCo: กด **Pause** แล้ว **Load key 0** (stand_ready)
2. pane g1_ctrl (คลิกที่ terminal ก่อน ไม่ใช่หน้าต่าง MuJoCo): กด `u` (FixStand) แล้ว `v` (Velocity)
3. กลับไป MuJoCo กด **Run**
4. pane g1_ctrl: `w`/`s` เดินหน้า/ถอย, `a`/`d` ซ้าย/ขวา, `q`/`e` หมุน, `x` หรือ space หยุด, `p` กลับ Passive

**ผลที่ต้องเห็น:**
- บรรทัด DDS ของ g1_ctrl เป็น `DDS: domain 1 on lo (SIM, keyboard on)`
- หุ่นเดินตามคีย์ pane speed monitor แสดงความเร็วใกล้กับที่สั่ง (กด `w` ครั้งเดียว ≈ 0.4 m/s)

## 10. ปิดเมื่อเลิกใช้ (อย่าข้าม)
`Ctrl+b` แล้ว `d` แค่**ออก**จาก tmux แต่ g1_ctrl ยังรันต่อ ครั้งหน้าจะเปิดใหม่ไม่ได้ ("already running; stop it first")
```bash
tmux kill-session -t sim2sim     # ทางลัด: make sim2sim-stop
```
**ผลที่ต้องเห็น:** `tmux ls` ไม่มี `sim2sim` และ `make doctor` ไม่มี WARN ว่า g1_ctrl หรือ unitree_mujoco ยังรันอยู่

---

## ทบทวนก่อนไป Day 2
- [ ] `make doctor` ได้ 0 FAIL
- [ ] เดินหุ่นใน sim ได้ และอธิบายได้ว่าบรรทัด `DDS: ... SIM` บอกอะไร
- [ ] รู้ว่า `make sim2sim` รันคำสั่งอะไรจริง (ลอง `make -n sim2sim`)
- [ ] ปิด session เป็น

ถัดไป: [Day 2: เทรน](day2_train.md)
