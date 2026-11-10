# g1_23_dof mujoco_sim cmd

> ย้ายมาจาก vault ของผู้ดูแล (`06 my_note/g1_23_dof mujoco_sim cmd.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-05

คำสั่งรัน sim ฝั่ง **MuJoCo** ของ G1 23-DoF: เทรน/play ด้วย mjlab, sim2sim headless (`vel_eval`), และ sim ครบระบบ (`unitree_mujoco` + `g1_ctrl` คุยผ่าน DDS เหมือนหุ่นจริง)
ฝั่ง Isaac: [g1_23_dof isaaclab_sim cmd](isaaclab_sim_cmd.md) · ฝั่งหุ่นจริง: [terminal cmd](terminal_cmd.md)

## ภาพรวม: sim ไหนใช้ทำอะไร
```
เทรน (mjlab, GPU)            ──export──▶  policy.onnx + deploy.yaml
  scripts/train.py / play.py                    │
                                                ├─▶ vel_eval.py          (headless, เร็ว, ไม่มี DDS)
                                                └─▶ unitree_mujoco + g1_ctrl (DDS บน lo = เหมือนหุ่นจริง)
```

| อยากทำ | ใช้ | env |
|---|---|---|
| เทรน / ดู policy ใน viewer ของ mjlab | `scripts/train.py`, `scripts/play.py` | conda `unitree_rl_mjlab` |
| วัดความเร็ว / ยืนนิ่ง / แขวน แบบเร็ว | `vel_eval.py` | conda `g1_sdk` |
| ทดสอบโค้ด C++ `g1_ctrl` + DDS + รีโมท | `unitree_mujoco` + `g1_ctrl` | ไบนารี (ไม่ใช้ conda) + `g1_sdk` สำหรับสคริปต์ |
| ทดสอบสคริปต์ที่ส่ง lowcmd (sysid, pd_check) ตอนหุ่นแขวน | `unitree_mujoco` สำเนาที่เปิด elastic band | เหมือนข้างบน |

## โครงสร้างโฟลเดอร์
```
~/nvidia/unitree/unitree_rl_mjlab/                 ← repo หลัก (branch phase3-delay-dr)
├── scripts/
│   ├── train.py                                   ← เทรน (mjlab + rsl_rl)
│   ├── play.py                                    ← ดู policy จาก checkpoint
│   └── list_envs.py                               ← รายชื่อ task
├── src/
│   ├── assets/robots/unitree_g1/
│   │   ├── g1_23dof_constants.py                  ← gain, armature, action scale ตอนเทรน
│   │   └── xmls/g1_23dof.xml, scene_g1_23dof.xml  ← โมเดล MuJoCo
│   └── tasks/velocity/config/g1_23dof/
│       ├── __init__.py                            ← ลงทะเบียน task: -Flat, -Rough, -Rough-Blind
│       ├── env_cfgs.py                            ← obs, reward, DR ของ 23dof
│       └── rl_cfg.py                              ← PPO
├── logs/rsl_rl/g1_23dof_velocity/<วันเวลา>/       ← checkpoint model_*.pt จากการเทรน
├── run_phase{2,3,4}_train.sh                      ← คำสั่งเทรนแต่ละ phase
├── simulate/                                      ← unitree_mujoco (sim ที่คุย DDS)
│   ├── config.yaml                                ← robot, scene, **domain_id 1**, interface lo, joystick, elastic band
│   └── build/unitree_mujoco                       ← ไบนารี
└── deploy/robots/g1_23dof/
    ├── main.cpp, src/, include/                   ← โค้ด g1_ctrl (FSM)
    ├── build/g1_ctrl                              ← ไบนารี (อ่าน ../config/config.yaml)
    ├── config/
    │   ├── config.yaml                            ← FSM: Passive / FixStand / Velocity / Handover, gain, ปุ่ม
    │   └── policy/velocity/
    │       ├── v0/                                ← P3b (ตัวหลัก)
    │       │   ├── exported/policy.onnx
    │       │   ├── params/deploy.yaml             ← obs, gain, scale ที่ g1_ctrl ใช้
    │       │   └── checkpoints/model_phase3b_15998.pt
    │       ├── hist5_yawft/, hist5_yawstand/      ← สาย Hist5 (ห้ามเข้า Velocity ตอนแขวน)
    └── scripts/                                   ← vel_eval, sim2sim_policy.sh, monitor, pd_check, sysid ...

~/nvidia/unitree/unitree_rl_mjlab-hist5/           ← worktree สาย Hist5 (ต้องตั้ง PYTHONPATH)
~/nvidia/unitree/unitree_mujoco/                   ← unitree_mujoco ต้นฉบับ (โมเดล unitree_robots/g1/scene_23dof.xml)
```

## sim = domain 1, หุ่นจริง = domain 0 (ตั้งแต่ 5/11/2026)
| | sim | หุ่นจริง |
|---|---|---|
| การ์ด | `lo` | `enp43s0` |
| DDS domain | **1** (`simulate/config.yaml`) | **0** |
| g1_ctrl | ค่าเริ่มต้น (ไม่ใส่อะไร = `lo`, 1) | `--network enp43s0` (domain 0 ให้เอง) |
| สคริปต์ python | ค่าเริ่มต้น (ไม่ใส่อะไร = `lo`, 1) | `--network enp43s0` (domain 0 ให้เอง) · ชื่อเก่า `--network` ยังใช้ได้ |
| บรรทัดแรกที่พิมพ์ | `DDS: SIM ...` / `(SIM, keyboard on)` | `DDS: REAL ROBOT ...` |
| คีย์บอร์ด g1_ctrl | เปิด | ปิด (รีโมทเท่านั้น) |

**ไม่ต้องใส่ `--domain`** โปรแกรมเลือกให้จากการ์ด (`lo` → 1, `enp43s0` → 0) ใส่ได้แต่ไม่จำเป็น ยกเว้นกรณีพิเศษ เช่น g1pilot sim (domain 0 บน lo) · กั้นกันสองชั้น (การ์ด + domain) ลืม flag ตัวเดียวก็ไม่ข้ามไปอีกฝั่ง · **ค่าเริ่มต้นของทุกโปรแกรม = sim** ลืมใส่ flag = ไป sim ไม่ใช่หุ่น (ตั้งแต่ 5/11) · ผิด domain = g1_ctrl ขึ้น warning แล้วรอเฉยๆ ไม่ส่งอะไร

### g1pilot sim (ROS 2) ต้องใช้ sim domain 0
Unitree SDK ใน g1pilot เขียน `ChannelFactoryInitialize(0, ...)` ไว้ตายตัว ถ้าจะรัน g1pilot กับ sim ตัวนี้:
```bash
make sim SIM_DOMAIN=0          # terminal 1: unitree_mujoco -i 0
make ctrl-sim SIM_DOMAIN=0     # terminal 2: g1_ctrl --network lo --domain 0 (ถ้าใช้)
export ROS_DOMAIN_ID=1 CYCLONEDDS_URI='<CycloneDDS><Domain><General><Interfaces><NetworkInterface name="lo" /></Interfaces></General></Domain></CycloneDDS>'
                               # terminal ROS: ROS_DOMAIN_ID=1 + CycloneDDS บน lo (เฉพาะ terminal นี้)
src/docker/run_sim.sh          # g1pilot (ROS domain 1, SDK domain 0)
```

### ROS 2 กับตัวแปร environment (5/11)
- **อย่า export** `CYCLONEDDS_URI` และ `ROS_DOMAIN_ID` ไว้ใน `~/.bashrc` (จะบังคับทุกโปรแกรม DDS รวม SDK ที่คุยกับหุ่นให้อยู่บน `lo`) ดู [basics/05](../04-explanation/basics/05_dds_domain_interface.md)
- terminal ที่จะใช้ ROS 2: ตั้งสองตัวนี้ใน terminal นั้น (คำสั่งข้างบน)
- terminal หุ่นจริงหรือ Unitree SDK: `unset CYCLONEDDS_URI` (target ของ make ทำให้แล้ว)

## 0. เตรียม (หลังรีบูตทุกครั้ง)
```bash
# DDS บนเครื่องเดียวกันต้องใช้ multicast บน lo · ไม่เปิด = sim กับ g1_ctrl หากันไม่เจอ (ไม่มี error)
sudo ip link set lo multicast on
cd ~/nvidia/unitree/unitree_rl_mjlab
S=deploy/robots/g1_23dof/scripts
```

## 1. เทรน / play (mjlab)
```bash
conda activate unitree_rl_mjlab
# ดูรายชื่อ task ที่มี
python scripts/list_envs.py
# เทรนพื้นเรียบจากศูนย์ (1024 envs พอสำหรับ RTX 3060 6 GB) · log ไปที่ logs/rsl_rl/g1_23dof_velocity/
python scripts/train.py Unitree-G1-23Dof-Flat --env.scene.num-envs=1024 --agent.logger=tensorboard
# เทรนต่อจาก checkpoint เดิม (ตัวอย่างจาก run_phase3_train.sh)
python scripts/train.py Unitree-G1-23Dof-Flat --env.scene.num-envs=1024 \
  --agent.resume=True --agent.load-run=2026-10-21_11-41-28 --agent.load-checkpoint=model_12999.pt \
  --agent.max-iterations=3000 --agent.logger=tensorboard
# ดู policy ใน viewer (native = หน้าต่าง MuJoCo, viser = เว็บ)
python scripts/play.py Unitree-G1-23Dof-Flat --checkpoint_file=logs/rsl_rl/g1_23dof_velocity/<วันเวลา>/model_<n>.pt
# ดูกราฟระหว่างเทรน
tensorboard --logdir logs/rsl_rl
```
task ที่มี: `Unitree-G1-23Dof-Flat`, `-Rough`, `-Rough-Blind` (+ สาย Hist5 ใน worktree) · ดู [Training Practice](training_practice.md)

## 2. sim2sim headless (`vel_eval.py`)
```bash
conda activate g1_sdk
P=deploy/robots/g1_23dof/config/policy/velocity
# ทดสอบความเร็วหลายกรณี (vx, vy, wz) ตาม obs/action ใน deploy.yaml · พิมพ์ % ที่ทำได้เทียบคำสั่ง
python $S/vel_eval.py --policy $P/v0/exported/policy.onnx --deploy $P/v0/params/deploy.yaml
# ยืนนิ่ง (คำสั่ง 0) แบบแขวนกลางอากาศ · ทุก policy ใหม่ต้องผ่าน (Hist5 เตะแรงจนเกิน limit)
python $S/vel_eval.py --policy $P/v0/exported/policy.onnx --deploy $P/v0/params/deploy.yaml --cases "0,0,0" --hang
# เช็คว่า deploy.yaml ตรงกับ ONNX
python $S/gain_check.py $P/v0
```
ดู [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md)

## 3. sim ครบระบบ: `unitree_mujoco` + `g1_ctrl`
### 3a. แบบสคริปต์เดียว (แนะนำ)
```bash
# เปิด tmux 3 pane ในหน้าเดียว: ซ้ายบน log ของ mujoco · ซ้ายล่าง ความเร็ว · ขวา g1_ctrl (พิมพ์ปุ่มที่นี่ ถูกเลือกไว้แล้ว, คลิกเมาส์ได้)
# เลิกใช้: tmux kill-session -t sim2sim
# ใช้สำเนาของ g1_ctrl + config ใน /tmp/g1_sim2sim_<user>_<policy> → ไม่แตะ config จริง
$S/sim2sim_policy.sh v0      # เข้า tmux ให้เอง (ออกแล้วกลับเข้า: tmux attach -t sim2sim)
```
ขั้นตอนใน sim:
1. หน้าต่าง MuJoCo: **Pause** → Load key 0 (`stand_ready`)
2. pane g1_ctrl: กด `u` (FixStand) แล้ว `v` (Velocity)
3. MuJoCo: **Run**
4. pane g1_ctrl: `w/s` หน้า-หลัง · `a/d` ข้าง · `q/e` หมุน · `x` หยุด
5. ปิด: `tmux kill-session -t sim2sim`

### 3b. แบบรันเองทีละตัว
ทางลัดใน kit:
```bash
make sim       # terminal 1: unitree_mujoco (lo, domain 1) · ไม่ยอมเปิดซ้ำ
make ctrl-sim  # terminal 2: g1_ctrl กับ sim (lo, domain 1)
make sim-band  # แทน make sim: sim ที่มีเชือก (ข้อ 4)
(cd /tmp/g1_fixstand_train/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./g1_ctrl --network lo --domain 1)   # ใช้ g1_ctrl สำเนาอื่น
```
หรือพิมพ์เต็ม:
```bash
# terminal 1: sim (อ่าน simulate/config.yaml: domain 1, lo) · env -u / LD_LIBRARY_PATH กันไบนารี Unitree crash กับ DDS ของ ROS
cd ~/nvidia/unitree/unitree_rl_mjlab/simulate/build
env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./unitree_mujoco
# terminal 2: g1_ctrl ตัวจริง (ใช้ config/config.yaml ของ repo)
cd ~/nvidia/unitree/unitree_rl_mjlab/deploy/robots/g1_23dof/build
env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./g1_ctrl      # ไม่ใส่ flag = lo + domain 1
# terminal 3 (ไม่บังคับ): ดูข้อมูล / บันทึก log เหมือนวันเทสจริง
conda activate g1_sdk && unset CYCLONEDDS_URI
python $S/lowstate_monitor.py          # ไม่ใส่ flag = sim
python $S/lowcmd_monitor.py
python $S/sim_speed_monitor.py          # ค่าเริ่มต้น lo + domain 1 อยู่แล้ว
# ซ้อมวันเทสใน sim: byobu 4 ช่องแบบเดียวกับวันจริง (IFACE=lo → domain 1 ให้เอง)
IFACE=lo $S/deploy_byobu.sh 1 simtest
```
> [!WARNING]
> - **ห้ามรัน g1_ctrl สองตัวพร้อมกัน** บน lo จะแย่งกันส่ง lowcmd (ไม่มี error)
> - **ห้ามรัน sim สองตัวบน domain เดียวกัน** (`make sim` กับ `make sim-band` เป็น domain 1 ทั้งคู่ เปิดทีละตัว)
> - ห้ามเปิด sim ตอนหุ่นจริงกำลังถูกสั่ง (CPU + สับสนช่อง) ซ้อมใน sim ก่อน แล้วปิด แล้วค่อยขึ้นหุ่น

### 3c. build ใหม่หลังแก้โค้ด
```bash
# g1_ctrl
cd ~/nvidia/unitree/unitree_rl_mjlab/deploy/robots/g1_23dof/build && cmake .. && make -j8
# unitree_mujoco
cd ~/nvidia/unitree/unitree_rl_mjlab/simulate/build && cmake .. && make -j8
```

## 4. sim แบบหุ่นแขวน (elastic band = เชือก) สำหรับทดสอบสคริปต์ที่ส่งแรง
ใช้ทดสอบ sysid_motion, FixStand, Handover, L2 + B ก่อนขึ้นหุ่นจริง · `make sim-band` ทำสำเนา sim ไว้ที่ `/tmp/g1_sim_band_<user>` (`config.yaml` ที่ `enable_elastic_band: 1`, `robot_scene` เป็น path เต็ม, domain 1) ไม่แตะ config ของ repo
```bash
make sim-band
# คำสั่งเต็มอยู่ใน scripts/sim_band.sh ของ kit
# แล้วรันสคริปต์ได้เลย (ค่าเริ่มต้น = sim) เช่น
python $S/sysid_motion.py --groups armL --kinds chirp --dry-run
```
ในหน้าต่าง MuJoCo (คลิกที่หน้าต่างก่อน): `9` = เปิด/ปิดเชือก · `7` / ↑ = ดึงขึ้น 10 cm · `8` / ↓ = หย่อน 10 cm · Space = หยุด/เล่น
`make sim-band` ก๊อป binary ใหม่ทุกครั้งที่เปิด build `simulate/` ใหม่แล้วไม่ต้องทำอะไรเพิ่ม

### ทดลอง: FixStand ยืนบนพื้นเองได้ไหม (5–6/11)
```bash
$S/fixstand_train_gains.sh                               # g1_ctrl สำเนา FixStand = gain เทรน (/tmp, สร้างใหม่หลังรีบูต)
make sim-band                                            # terminal 1
(cd /tmp/g1_fixstand_train/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./g1_ctrl --network lo --domain 1)
                                                         # terminal 2 รอบ A (gain เทรน) · รอบ B ใช้ make ctrl-sim (gain Unitree)
```
ขั้นตอน: terminal 2 กด `u` (FixStand) → หน้าต่าง MuJoCo กด `8` ทีละครั้งจนเท้าแตะพื้น → กด `8` ต่อ (เชือกรับน้อยลง) → `9` ปลดเชือก

**ผล: ล้มไปข้างหน้าทั้งสองชุด** (~1.5 s หลังเชือกหมด) เพราะยืนนิ่งเป็นลูกตุ้มกลับหัว ข้อเท้าต้องแข็งอย่างน้อย m·g·h = 32.1 × 9.81 × 0.65 ≈ **206 Nm/rad** แต่ kp ข้อเท้า 2 ข้างรวม = 80 (Unitree) / 57 (เทรน) และจุดศูนย์ถ่วงอยู่หน้าข้อเท้า ~3.3 cm · ต่างกันแค่ gain เทรนยุบตัวมากกว่าระหว่างล้ม (ตอนเชือกยังกันล้ม: ขารับ 100% gain เทรนยุบ ~515 mm, Unitree ~7 mm)
→ **FixStand ยืนเองบนพื้นไม่ได้ไม่ว่า gain ไหน** เชือกต้องรับไว้จนเข้า Velocity · FixStand ใช้ gain Unitree ต่อไป (ยุบน้อยกว่าตอนเชือกช่วย)


## ข้อจำกัดของ sim (ต่างจากหุ่นจริง)
- armature ใน `scene_g1_23dof.xml` = 0.01 ทุกข้อ (ตอนเทรน 0.0036–0.025)
- FixStand แขนสั่นใน sim (kd 10 + PD explicit 2 ms) หุ่นจริงไม่เป็น
- ไม่มี motion_switcher, `vol` = 0, bmsstate ปลอม
- FixStand ยืนเองบนพื้นไม่ได้ (ไม่มีการทรงตัว) ต้องให้เชือกรับ หรือเริ่มด้วย Pause → key 0 → `u` `v` → Run แบบข้อ 3a
- รีโมทใน sim มาจาก gamepad เท่านั้น (`use_joystick: 1`) ไม่มีจอยใช้คีย์บอร์ดใน g1_ctrl

## ดูเพิ่ม
[Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md) · [Training Practice](training_practice.md) · [Environments Map](../03-reference/environments_map.md) · [Troubleshooting](troubleshooting.md) · [DDS and Domains](../04-explanation/dds_and_domains.md)
