# terminal cmd

> ย้ายมาจาก vault ของผู้ดูแล (`06 my_note/terminal cmd.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-05

คำสั่งที่รันจริงบนหุ่น (ดึงจาก `~/.bash_history`) + คำสั่งสำหรับเทสครั้งถัดไป คัดลอกไปวางได้เลย บรรทัดที่ขึ้นต้นด้วย `#` เป็นคำอธิบาย bash ไม่รัน วางทั้งก้อนได้
ขั้นตอนและเกณฑ์ผ่าน: [Test Day Procedure](test_day_procedure.md) · ผลที่วัดได้: [Real Robot Results](../05-history/real_robot_results.md) · สคริปต์ทั้งหมด: [Real Robot Tools](../03-reference/real_robot_tools.md)

> [!CAUTION]
> **ก่อนรันคำสั่งที่ส่งแรง**
> หุ่นแขวนรอก · คนถือรีโมทพร้อม **L2 + B** · ไม่กด L2 + A · รัน `--dry-run` ก่อนเสมอ · ไม่ใช้ `--yes`

## สคริปต์แต่ละตัวทำอะไร (สรุปสั้น)
| สคริปต์ | ส่งแรงไหม | หน้าที่ |
|---|---|---|
| `robot_health.py` | ไม่ | ฟัง ~3 s แล้วสรุป PASS/WARN/FAIL: Hz ของ lowstate, mode_machine, มีใครส่ง lowcmd อยู่ไหม, motion mode, มอเตอร์ offline, อุณหภูมิ, IMU, แบต |
| `motion_mode.py` | เปลี่ยนโหมด | คุยกับ motion_switcher ของ Unitree: `check` ดูโหมด, `release` ปิด controller ของ Unitree (เข้า debug), `select ai` เปิดกลับ |
| `offset_check.py` | ไม่ | ให้คนหมุนข้อต่อจนชนสุด แล้วเทียบกับจุดชนของ 28/10 ถ้าต่างมาก = ค่าศูนย์ encoder เลื่อน |
| `gain_check.py` | ไม่ (ไม่ใช้หุ่น) | เทียบ kp/kd/scale ใน deploy.yaml กับที่ฝังใน ONNX ว่าตรงกัน |
| `lowstate_monitor.py` | ไม่ | อ่าน `rt/lowstate` (หุ่น → เรา): q, dq, tau_est, อุณหภูมิ ของทุก slot · `--log` เซฟ CSV |
| `lowcmd_monitor.py` | ไม่ | อ่าน `rt/lowcmd` (เรา → หุ่น): q_des, kp, kd, tau_ff ที่ถูกส่งจริง และบอกว่า gain ตรงกับ state ไหนของ g1_ctrl · `--log` เซฟ CSV |
| `deploy_byobu.sh` | ไม่ (แค่เปิดจอ) | เปิด byobu 4 ช่อง พิมพ์คำสั่งรอไว้ให้ ยังไม่กด Enter · **ต้องใส่ `IFACE=`** · โหมดหุ่นไม่ยอมเปิดถ้า sim เปิดอยู่ |
| `sysid_motion.py` | **ส่ง** | ส่ง lowcmd เองแทน g1_ctrl: ท่า step / chirp ทีละข้อต่อ, กด L2 + B แล้วเข้า damping |
| `fixstand_train_gains.sh` | ไม่ (แค่ build) | สร้างสำเนา g1_ctrl ที่ `/tmp/g1_fixstand_train` ให้ FixStand ใช้ gain ตอนเทรน |
| `g1_ctrl` | **ส่ง** | controller ของเรา (FSM: Passive → FixStand → Velocity/policy, Handover) |
| `pd_check.py` | ไม่ (อ่าน CSV) | เอา log state + cmd มา fit หาว่ามอเตอร์ให้แรงตาม kp/kd ที่สั่งกี่เท่า (`kp x`, `kd x`) และ delay |

## 0. เตรียมเครื่อง (ทุกครั้ง)
> [!TIP]
> ทางลัดใน kit: `make deploy-real IFACE=enp43s0` = ด่านตรวจ (ไม่มี sim เปิด, IP ถูกวง, พิมพ์ `real` ยืนยัน) แล้วเปิด byobu 4 ช่องของวันทดสอบ · `make health IFACE=enp43s0` = อ่านสถานะหุ่นอย่างเดียว

> [!NOTE]
> หุ่นจริง = `enp43s0` + **domain 0** · sim = `lo` + **domain 1** (5/11) · **ทุกโปรแกรมค่าเริ่มต้น = sim** ไม่ใส่ flag = ไป sim · หุ่นจริงต้องใส่ `--network enp43s0` (ทุกโปรแกรม ทั้ง g1_ctrl และสคริปต์ python) ทุกครั้ง และดูบรรทัดแรกที่พิมพ์ต้องเป็น `REAL ROBOT` · **ไม่ต้องใส่ `--domain`** (โปรแกรมเลือกให้: `enp43s0` → 0) · **flag ชื่อเดียวกันทุกโปรแกรม: `--network`** (6/11 · สคริปต์ python ยังรับชื่อเก่า `--iface` ได้ เอกสารเก่าที่เขียน `--iface` จึงยังใช้ได้) · ดู [g1_23_dof mujoco_sim cmd](mujoco_sim_cmd.md)

```bash
# ตั้ง IP ให้การ์ดแลนที่ต่อหุ่น (หุ่นอยู่วง 192.168.123.x) และเปิดการ์ด · หายเมื่อรีบูต/ถอดสาย
sudo ip addr add 192.168.123.123/24 dev enp43s0 && sudo ip link set enp43s0 up
# เปิด multicast บน lo · ถ้าไม่เปิด โปรแกรม DDS บนเครื่องเดียวกันจะหากันไม่เจอ (ไม่มี error)
sudo ip link set lo multicast on
# เช็คว่าเห็นหุ่น (161 = บอร์ด motion control) ต้อง 0% packet loss
ping -c 3 192.168.123.161
# เข้า repo + env ที่มี unitree_sdk2py · unset CYCLONEDDS_URI เพราะค่าจาก ROS ทำให้ SDK พัง
cd ~/nvidia/unitree/unitree_rl_mjlab && conda activate g1_sdk && unset CYCLONEDDS_URI
# ตัวแปรย่อ: S = โฟลเดอร์สคริปต์, D = วันที่ (ใช้ตั้งชื่อ log)
S=deploy/robots/g1_23dof/scripts
D=$(date +%Y%m%d)
```

## 0.5 ก่อนเริ่ม: กันสับสน sim / หุ่นจริง (ทุกครั้ง)
```bash
# sim ต้องปิด · ถ้าเปิดอยู่ คำสั่งที่ลืม --network enp43s0 จะอ่านค่าจาก sim แล้วได้ PASS หลอก
pgrep -a unitree_mujoco            # ต้องไม่มีผลลัพธ์
# service บนคอม 164 ที่สั่งหุ่นได้ ต้อง inactive ทั้ง 3 (ถ้า active คุยกับรุ่นพี่ก่อน แล้ว sudo systemctl stop <ชื่อ>)
ssh unitree@192.168.123.164 'systemctl is-active fibo_legged_robot_g1 g1_arm g1_arm_web'
```
ทุกโปรแกรมพิมพ์บรรทัดแรก **ต้องเป็น `DDS: REAL ROBOT ...`** ถ้าเห็น `SIM` = ลืม `--network enp43s0` ให้ Ctrl-C แล้วพิมพ์ใหม่ · ดู [Hi-level cmd](pc164_hi_level_cmd.md)

## 1. เช็คหุ่น (อ่านอย่างเดียว)
```bash
# สรุปสุขภาพหุ่น ต้อง PASS ทุกบรรทัด และ "23 motors online" (ระวัง slot 25/26 แขนขวา)
python $S/robot_health.py --network enp43s0
# ดูโหมดปัจจุบัน ตอนบูตต้องเป็น name='ai' (controller ของ Unitree คุมอยู่)
python $S/motion_mode.py --network enp43s0 check
# เช็คค่าศูนย์เฉพาะแขนขวา: หมุนข้อต่อที่ระบุจนชนทั้งสองฝั่ง ดูว่า OK (|d| เล็ก) · Ctrl-C เพื่อจบและเซฟผล
python $S/offset_check.py --network enp43s0 --joints right_elbow,right_wrist,right_shoulder
# เหมือนข้างบนแต่ทั้ง 23 ข้อ
python $S/offset_check.py --network enp43s0
# (ไม่ใช้หุ่น) เช็คว่า deploy.yaml ของ policy v0 ตรงกับ ONNX · ทำก่อนวันเทสได้
python $S/gain_check.py deploy/robots/g1_23dof/config/policy/velocity/v0
```

## 2. เข้า / ออก debug
```bash
# ปิด controller ของ Unitree เพื่อให้เราส่ง lowcmd เองได้ · ต้องพิมพ์ yes · ไฟเปลี่ยนเป็นเหลือง
python $S/motion_mode.py --network enp43s0 release
# ยืนยันว่าเข้า debug แล้ว: name='' และไม่มี lowcmd จากใคร
python $S/motion_mode.py --network enp43s0 check
# กลับไปให้ Unitree คุม (zero torque, ไฟม่วง) · ใช้เมื่อ Handover จากรีโมทไม่สำเร็จ หรือก่อนปิดเครื่อง
python $S/motion_mode.py --network enp43s0 select ai
```

## 3. byobu (T1 lowstate · T2 lowcmd · T3 g1_ctrl · T4 คำสั่ง)
```bash
# เปิดจอ 4 ช่อง · RUN = เลขรอบ, TAG = ชื่องาน → log ชื่อ ~/g1_{state,cmd}_<วันที่>_<TAG><RUN>.csv
IFACE=enp43s0 $S/deploy_byobu.sh <RUN> <TAG>
```
คำสั่งที่พิมพ์รอไว้ในแต่ละช่อง (กด Enter เอง):
```bash
# T1: บันทึกสิ่งที่หุ่นรายงาน (มุม, ความเร็ว, แรงประมาณจากกระแส) ~1000 Hz · เปิดก่อนส่งแรงเสมอ
python $S/lowstate_monitor.py --network enp43s0 --log ~/g1_state_${D}_${TAG}${RUN}.csv
# T2: บันทึกคำสั่งที่ส่งไปหุ่น · ถ้าเห็น MISMATCH = gain ไม่ตรงกับที่คาด ให้หยุด
python $S/lowcmd_monitor.py --network enp43s0 --log ~/g1_cmd_${D}_${TAG}${RUN}.csv
# T3 (ส่งแรง): g1_ctrl หุ่นจริง · คีย์บอร์ดปิด สั่งด้วยรีโมทเท่านั้น
cd deploy/robots/g1_23dof/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./g1_ctrl --network enp43s0
```
ซ้อมทั้งชุดใน sim ก่อนวันเทส: `IFACE=lo $S/deploy_byobu.sh 1 simtest` (ทุกช่องได้ `--domain 1` ให้เอง)

F6 = detach (โปรแกรมยังรันต่อ) · `byobu attach -t g1deploy` = กลับ · ดู [Byobu Guide](byobu_guide.md)

### 3.1 ตัวอย่างการใช้ `deploy_byobu.sh`
```
IFACE=enp43s0  $S/deploy_byobu.sh  <RUN>  <TAG>
   │                                 │      └─ ชื่องาน (ใช้ตั้งชื่อ log) ไม่ใส่ = run
   │                                 └─ เลขรอบ 1, 2, 3 ... ไม่ใส่ = 1
   └─ ต้องใส่เสมอ: enp43s0 = หุ่นจริง, lo = ซ้อมใน sim
```
```bash
conda activate g1_sdk && cd <WS>/unitree_rl_mjlab && unset CYCLONEDDS_URI && S=deploy/robots/g1_23dof/scripts D=$(date +%Y%m%d)   # ได้ตัวแปร $S และ $D

# 1) chirp วัด kd รอบแรก (sysid ส่งแรงเอง ช่อง T3 ไม่ต้องเปิด g1_ctrl)
IFACE=enp43s0 $S/deploy_byobu.sh 1 chirp
#    → ~/g1_state_<วันที่>_chirp1.csv, ~/g1_cmd_<วันที่>_chirp1.csv
# 2) chirp รอบที่ 2 (เช่น แขนขวา) แยก log คนละไฟล์
IFACE=enp43s0 $S/deploy_byobu.sh 2 chirp
# 3) sysid step
IFACE=enp43s0 $S/deploy_byobu.sh 1 sysid
# 4) FixStand gain เทรน (g1_ctrl สำเนาใน /tmp) ช่อง T3 จะใช้ตัวนั้น · แขวนเท่านั้น
$S/fixstand_train_gains.sh
IFACE=enp43s0 G1_CTRL_DIR=/tmp/g1_fixstand_train/build $S/deploy_byobu.sh 1 bm
# 5) g1_ctrl ตัวปกติ (FixStand → Velocity, Handover)
IFACE=enp43s0 $S/deploy_byobu.sh 1 run
# 6) ซ้อมทั้งชุดใน sim ก่อนวันเทส (เปิด make sim-band ไว้อีก terminal ก่อน)
IFACE=lo $S/deploy_byobu.sh 1 simtest
```

**เปิดแล้วเห็นอะไร**
```
┌ T1 lowstate_monitor (read-only) ┬ T2 lowcmd_monitor (read-only) ┐
│ python ... --network enp43s0    │ python ... --network enp43s0  │
│   --log ~/g1_state_..._chirp1   │   --log ~/g1_cmd_..._chirp1   │
├ T3 g1_ctrl (SENDS MOTOR CMDS) ──┼ T4 checks / motion_mode ──────┤
│ ./g1_ctrl --network enp43s0     │ ลูกศรขึ้น = ดึงคำสั่งที่เตรียมไว้: │
│                                 │ ping, gain_check, motion_mode │
│                                 │ check/release, pd_check รอบนี้ │
└─────────────────────────────────┴───────────────────────────────┘
```

**ลำดับในหนึ่งรอบ (ตัวอย่าง chirp)**
1. **T1** Enter → เริ่มบันทึก lowstate · **T2** Enter → เริ่มบันทึก lowcmd
2. **T3** ไม่ต้องกด (sysid ส่งแรงแทน g1_ctrl ถ้ารันพร้อมกันจะแย่งกัน)
3. **T4** `python $S/sysid_motion.py --network enp43s0 --groups armL --kinds chirp --dry-run` ก่อน แล้วค่อยรันจริงพร้อม `--segments ...`
4. จบรอบ: **Ctrl-C ที่ T1 และ T2** (ไฟล์ CSV ถึงจะปิดสมบูรณ์)
5. **T4** ลูกศรขึ้นหา `pd_check.py ~/g1_state_..._chirp1.csv ~/g1_cmd_..._chirp1.csv` แล้วเพิ่ม `--segments <ไฟล์ seg>`

**เปลี่ยนรอบ / ออก / กลับเข้า**
```bash
# F6 = detach: ออกจากหน้าจอ แต่โปรแกรมยังรันต่อ
byobu attach -t g1deploy                     # กลับเข้าหน้าจอเดิม
tmux kill-session -t g1deploy                # ปิดทั้ง session (Ctrl-C g1_ctrl/monitor ให้เรียบร้อยก่อน)
IFACE=enp43s0 $S/deploy_byobu.sh 2 chirp     # แล้วค่อยเปิดรอบใหม่
```
ย้ายช่อง: คลิก หรือ Shift + ลูกศร (Alt + ลูกศร = สลับ window ไม่ใช่ช่อง)

**สคริปต์ไม่ยอมเปิดเมื่อ**
| ข้อความ | ทำไม | แก้ |
|---|---|---|
| `Set IFACE: ...` | ไม่ได้ใส่ IFACE | ใส่ `IFACE=enp43s0` หรือ `IFACE=lo` |
| `unitree_mujoco is running ...` | โหมดหุ่นตอน sim ยังเปิดอยู่ | ปิด sim ก่อน |
| `g1_ctrl is already running outside this session` | มี g1_ctrl ตัวอื่นรันอยู่ | Ctrl-C ตัวนั้นก่อน |
| `Session g1deploy already exists, attaching` | session เดิมยังอยู่ (พาเข้า session เดิม ไม่ได้เปิดใหม่) | อยากได้ชื่อ log ใหม่ → `tmux kill-session -t g1deploy` ก่อน |

> [!WARNING]
> ถ้า session เดิมยังเปิดอยู่ เลข RUN ใหม่ไม่มีผล (แค่พาเข้า session เดิม) kill session ก่อนทุกครั้งที่อยากได้ชื่อ log ใหม่

## 4. sysid step (3/11)
```bash
# เปิด byobu ชื่องาน sysid · ช่อง T3 ไม่ต้องเปิด g1_ctrl เพราะ sysid_motion ส่ง lowcmd เอง (สองตัวพร้อมกัน = แย่งกัน)
IFACE=enp43s0 $S/deploy_byobu.sh 1 sysid
# ดูแผนก่อน ไม่ส่งอะไร: จะขยับข้อไหน กี่ rad นานเท่าไร
python $S/sysid_motion.py --network enp43s0 --groups armL --joints elbow --kinds step --dry-run
# step ศอกซ้าย (กระโดดมุมเล็กๆ แล้วค้าง) · --segments เซฟเวลาเริ่ม/จบของแต่ละท่า เอาไว้ให้ pd_check fit ทีละช่วง
python $S/sysid_motion.py --network enp43s0 --groups armL --joints elbow --kinds step --segments ~/sysid_seg_20261103_light.csv
# step ศอกขวา (ดูมอเตอร์ 25 ด้วย)
python $S/sysid_motion.py --network enp43s0 --groups armR --joints elbow --kinds step --segments ~/sysid_seg_20261103_lightR.csv
# step เข่าซ้าย: ดูแผนก่อนเพราะขาแรงกว่าแขน
python $S/sysid_motion.py --network enp43s0 --groups legL --joints knee  --kinds step --dry-run
python $S/sysid_motion.py --network enp43s0 --groups legL --joints knee  --kinds step --segments ~/sysid_seg_20261103_kneeL.csv
# รอบเทส L2 + B: กดระหว่างท่า ต้องเข้า damping ทันทีและสคริปต์จบเอง
python $S/sysid_motion.py --network enp43s0 --groups legL --joints knee  --kinds step --segments ~/sysid_seg_20261103_kneeL_stop.csv
# วิเคราะห์: kp x ≈ 1 = มอเตอร์ให้แรงตาม kp ที่สั่ง (ใส่ --segments ไฟล์ข้างบนเพื่อ fit เฉพาะช่วง step)
python $S/pd_check.py ~/g1_state_20261103_sysid1.csv ~/g1_cmd_20261103_sysid1.csv
```
> [!WARNING]
> **`--segments` ตั้งชื่อใหม่ทุกรอบ ไม่งั้นทับไฟล์เดิม (30/10)**

## 5. FixStand ด้วย gain ที่เทรน (3/11)
```bash
# build สำเนา g1_ctrl ที่ FixStand ใช้ gain ตอนเทรน (แขน 14.3/0.9 ...) แทน gain Unitree (เข่า 150/4)
# อยู่ใน /tmp → หายเมื่อรีบูต ต้อง build ใหม่ทุกวันเทส
$S/fixstand_train_gains.sh
# เปิด byobu โดยให้ T3 ใช้ g1_ctrl สำเนานั้น (G1_CTRL_DIR) · ชื่องาน bm (BeyondMimic gains)
IFACE=enp43s0 G1_CTRL_DIR=/tmp/g1_fixstand_train/build $S/deploy_byobu.sh 1 bm
# T3: รัน g1_ctrl บนการ์ดที่ต่อหุ่น · env -u / LD_LIBRARY_PATH = ใช้ DDS ของ Unitree ไม่ใช่ของ ROS
#     เริ่มที่ Passive (damping) → รีโมทเข้า FixStand → ค้างดูว่านิ่ง ไม่สั่น
cd /tmp/g1_fixstand_train/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./g1_ctrl --network enp43s0
# หรือผ่าน kit: G1_CTRL_DIR=/tmp/g1_fixstand_train/build make deploy-real IFACE=enp43s0 TAG=bm
# วิเคราะห์: kp x 0.8–1.2, kd x 0.5–1.5
python $S/pd_check.py ~/g1_state_${D}_bm1.csv ~/g1_cmd_${D}_bm1.csv
```
> [!WARNING]
> FixStand ยืนเองบนพื้นไม่ได้ ไม่ว่า gain ไหน (ทดลองใน sim 6/11: ล้มไปข้างหน้า) ชุดนี้ใช้ตอน**แขวน**เท่านั้น · ยืนบนพื้นต้องให้เชือกรับไว้จนเข้า Velocity · ดู [g1_23_dof mujoco_sim cmd](mujoco_sim_cmd.md) ข้อ 4

ดู [FixStand Train Gains](../04-explanation/fixstand_train_gains.md)

## 6. g1_ctrl ปกติ P3b (30/10)
```bash
# byobu ชื่องาน run · T3 เปิด g1_ctrl ตัวหลัก (FixStand = gain Unitree, Velocity = policy v0)
IFACE=enp43s0 $S/deploy_byobu.sh 1 run
# วิเคราะห์ log รอบนั้น: kp x / kd x ของ Passive และ FixStand + delay
python $S/pd_check.py ~/g1_state_20261030_run1.csv ~/g1_cmd_20261030_run1.csv
```

## 7. Handover + ปิด
- รีโมท: Passive → **L1 + R1** ค้าง 1 s → **START** → g1_ctrl หยุดส่ง lowcmd, สลับเป็น `ai` แล้วปิดตัวเอง → ไฟม่วง ([Handover](handover.md))
- เช็ค:
  ```bash
  # ต้องเห็น name='ai' และ 23 motors online
  python $S/robot_health.py --network enp43s0
  ```
- ปิดเครื่อง: [Safe Shutdown](safe_shutdown.md)

## 8. ครั้งถัดไป: chirp วัด kd (ยังไม่เคยรันบนหุ่นจริง)
แผน: แผนทดสอบ G1 23-DoF (เอกสารแยกของผู้ดูแล) · ค่าเทียบจาก sim ใน [kp kd Verification](kp_kd_verification.md)
chirp = คลื่น sine ที่เร่งความถี่ 0.3 → 2.5 Hz ใน 12 s ข้อต่อขยับเร็วขึ้นเรื่อยๆ ทำให้เทอม D (kd × ความเร็ว) ใหญ่พอจะวัดได้
```bash
# byobu ชื่องาน chirp · T3 ไม่เปิด g1_ctrl
IFACE=enp43s0 $S/deploy_byobu.sh 1 chirp
# ต้อง name='' และไม่มี lowcmd จากใคร ก่อนให้ sysid ส่ง
python $S/motion_mode.py --network enp43s0 check

# ดูแผน chirp แขนซ้ายทั้ง 5 ข้อ (ไม่ส่งอะไร)
python $S/sysid_motion.py --network enp43s0 --groups armL --kinds chirp --dry-run
# chirp แขนซ้าย ~71 s
python $S/sysid_motion.py --network enp43s0 --groups armL --kinds chirp --segments ~/sysid_seg_${D}_chirp_armL.csv
# วิเคราะห์ทีละท่า: เทียบ kp x / kd x กับ sim (0.95–0.99)
python $S/pd_check.py ~/g1_state_${D}_chirp1.csv ~/g1_cmd_${D}_chirp1.csv --segments ~/sysid_seg_${D}_chirp_armL.csv

# รอบเทส L2 + B: กดตอนแขนกำลังแกว่งเร็ว ต้องหยุดทันที · สังเกตแขนหลังหยุด (ค้างหรือตกช้าๆ)
python $S/sysid_motion.py --network enp43s0 --groups armL --kinds chirp --segments ~/sysid_seg_${D}_chirp_armL_stop.csv

# กลุ่มที่เหลือ ทีละกลุ่ม ผ่านค่อยไปต่อ (รัน --dry-run ก่อนทุกกลุ่ม)
python $S/sysid_motion.py --network enp43s0 --groups armR  --kinds chirp --segments ~/sysid_seg_${D}_chirp_armR.csv
python $S/sysid_motion.py --network enp43s0 --groups waist --kinds chirp --segments ~/sysid_seg_${D}_chirp_waist.csv  # ~19 s
python $S/sysid_motion.py --network enp43s0 --groups legL  --kinds chirp --segments ~/sysid_seg_${D}_chirp_legL.csv   # ~84 s
python $S/sysid_motion.py --network enp43s0 --groups legR  --kinds chirp --segments ~/sysid_seg_${D}_chirp_legR.csv
```
- เปลี่ยน RUN ของ byobu ทุกครั้งที่เริ่มกลุ่มใหม่ ถ้าอยากให้ log แยกไฟล์ (`IFACE=enp43s0 deploy_byobu.sh 2 chirp` ...)
- ผ่านเมื่อ `kp x` / `kd x` ห่างจาก sim ไม่เกิน ±0.1 และ corr ≥ 0.9 · เข่าใน sim ได้แค่ 0.85–0.93 (P กับ D หักล้างกัน) อย่าตกใจถ้าต่ำ

## 9. ดูบนตัวหุ่น
```bash
# SSH เข้าบอร์ด 164 (PC บนหุ่น) เช่นดูว่ามีโปรเซสไหนส่ง lowcmd อยู่
ssh unitree@192.168.123.164
```

## ไฟล์ log ที่มีอยู่
| วันที่ | ไฟล์ |
|---|---|
| 28/10 | `~/g1_baseline_20261028_1826.csv`, `~/g1_joints_20261028_1848.csv` |
| 30/10 | `~/g1_{state,cmd}_20261030_run1*.csv`, `_sysid1` |
| 3/11 | `~/g1_{state,cmd}_20261103_{sysid1-4,bm1,run2}.csv`, `~/offset_20261103_right.txt` |

## ดูเพิ่ม
[Real Robot Tools](../03-reference/real_robot_tools.md) · [Sysid Motion](sysid_motion.md) · [Stop Mechanisms](../04-explanation/stop_mechanisms.md) · [Network Setup](network_setup.md)
