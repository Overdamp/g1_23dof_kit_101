# Day 3: export policy แล้วทดสอบ sim2sim

**เป้าหมาย:** เอา policy จากการเทรนไปทำเป็น "โฟลเดอร์ policy" แบบที่ `g1_ctrl` ใช้ ตรวจว่าไฟล์ถูกต้อง แล้ววัดผลใน sim ทั้งแบบไม่มีหน้าจอและแบบครบระบบ
**ก่อนเริ่ม:** Day 2 ผ่านแล้ว (มีโฟลเดอร์ run ที่มี `policy.onnx`)

## ภาพรวม: จากการเทรนถึงตัวควบคุม
```
logs/rsl_rl/g1_23dof_velocity/<run>/policy.onnx         ← การเทรน export ให้อัตโนมัติทุก 100 รอบ
                    │ ก๊อป
                    ▼
deploy/robots/g1_23dof/config/policy/velocity/<ชื่อ>/
├── exported/policy.onnx       ← โครงข่ายประสาท (obs เข้า → action ออก)
└── params/deploy.yaml         ← "สัญญา" ระหว่าง policy กับหุ่น: ลำดับ joint, kp, kd, scale, obs แต่ละตัว
                    │
                    ▼
g1_ctrl (C++) อ่านทั้งสองไฟล์ แล้วควบคุม sim หรือหุ่นจริงด้วยวิธีเดียวกัน
```
`deploy.yaml` ไม่ได้สร้างจากการเทรน มันเป็นไฟล์ที่เขียนไว้ให้ตรงกับนิยาม task ถ้า task ที่เทรนมี obs และ action แบบเดียวกับ v0 (Flat และ Rough-Blind เป็นแบบนั้น) ก็ใช้ `deploy.yaml` ของ v0 ได้เลย **แต่ต้องตรวจด้วย `gain-check` ทุกครั้ง**

---

## 1. สร้างโฟลเดอร์ policy
ตั้งชื่อสื่อความหมาย เช่น `myrun_500` ห้ามเขียนทับ `v0` (เป็นตัวที่ใช้ deploy จริง)
```bash
cd repos/unitree_rl_mjlab
P=deploy/robots/g1_23dof/config/policy/velocity
RUN=logs/rsl_rl/g1_23dof_velocity/<วันเวลา>          # โฟลเดอร์ run จาก Day 2
mkdir -p $P/myrun_500/exported $P/myrun_500/params
cp $RUN/policy.onnx  $P/myrun_500/exported/policy.onnx
cp $P/v0/params/deploy.yaml $P/myrun_500/params/deploy.yaml
```
ขั้นนี้ไม่มีทางลัด make โดยตั้งใจ ให้เห็นว่าโฟลเดอร์ policy ประกอบด้วยอะไร

**ผลที่ต้องเห็น:** `ls $P/myrun_500/*` มี `policy.onnx` และ `deploy.yaml`

## 2. ตรวจว่าไฟล์เข้ากันได้
ตอน export, mjlab ฝังค่า kp, kd, action scale ที่ใช้เทรนไว้ใน `policy.onnx` ด้วย `gain_check.py` จะเทียบค่าเหล่านี้กับ `deploy.yaml`
**คำสั่งเต็ม:**
```bash
conda activate g1_sdk
python deploy/robots/g1_23dof/scripts/gain_check.py $P/myrun_500
```
**ทางลัด:** `make gain-check POLICY=myrun_500`

**ผลที่ต้องเห็น:** ทุกบรรทัด `OK` (ต่างกันเล็กน้อยจากการปัดเศษได้) ปิดท้ายด้วย `PASS`
```
scale                                    OK  (max diff 0.36%, rounding)
action offset == default_joint_pos       OK
obs size vs ONNX input                   OK  (80 / 80)
PASS
```
**ถ้าไม่ PASS ห้ามเอาไปใช้ต่อ** เช่น `obs size` ไม่ตรง แปลว่า task ที่เทรนมี obs ต่างจาก `deploy.yaml`

## 3. วัดผลแบบไม่มีหน้าจอ (`vel_eval`)
จำลองสิ่งที่ `g1_ctrl` ทำ (obs/action ตาม `deploy.yaml`, policy 50 Hz, PD 500 Hz) บน MuJoCo แล้วสั่งความเร็วหลายแบบ
**คำสั่งเต็ม:**
```bash
python deploy/robots/g1_23dof/scripts/vel_eval.py \
  --policy $P/myrun_500/exported/policy.onnx --deploy $P/myrun_500/params/deploy.yaml
```
**ทางลัด:** `make eval POLICY=myrun_500` (ใส่ `CASES="0.4,0,0"` ถ้าจะทดสอบกรณีเดียว)

**ผลที่ต้องเห็น:** JSON หนึ่งบรรทัดต่อกรณี ช่องที่ต้องดู:
| ช่อง | ความหมาย | v0 (P3b) ได้ |
|---|---|---|
| `fell` | ล้มไหม | `false` ทุกกรณี |
| `vx` / `wz` เทียบกับ `cmd` | เดินได้เร็วกี่ % ของที่สั่ง | vx 0.4 → 0.388 (97%) |
| `tilt_max_deg` | เอียงมากสุด | ≤ 5.7° |
| `safety.max_torque_ratio` | แรงบิดสูงสุด / ลิมิตมอเตอร์ | ≤ 66% |
| `safety.entry_jump_rad` | กระตุกตอนเข้า Velocity | 0.28 rad |

เกณฑ์ของโปรเจคก่อนยอมให้ policy ขึ้นหุ่น: ไม่ล้มเลยสักกรณี และค่า safety ไม่แย่กว่า v0 อย่างมีนัยสำคัญ (ผลเต็มของทุก policy อยู่ใน `doc/g1_23dof_summary/02_sim2sim_eval.md` ของ repo)
policy 500 รอบจาก Day 2 คาดว่าจะยังไม่ผ่าน ให้ลองเทียบกับ `make eval POLICY=v0` ดู

## 4. ทดสอบครบระบบ (`g1_ctrl` + `unitree_mujoco`)
`vel_eval` ไม่ได้รันโค้ด C++ จริง ขั้นนี้ทดสอบ `g1_ctrl` ตัวที่จะใช้บนหุ่นจริง (FSM, obs history, DDS)
```bash
make sim2sim POLICY=myrun_500      # คำสั่งเต็มเหมือน Day 1 ขั้น 9 แค่เปลี่ยนชื่อ policy
```
`sim2sim_policy.sh` ก๊อป `g1_ctrl` กับ config ไปไว้ใน `/tmp/g1_sim2sim_<ชื่อ>` แล้วชี้ไปที่ policy นี้ **ไม่แตะ config จริง** (`config.yaml` ยัง pin ไว้ที่ `v0`)

**ผลที่ต้องเห็น:** g1_ctrl พิมพ์ว่าโหลด policy จากโฟลเดอร์ `myrun_500` ทำตาม Day 1 ขั้น 9 แล้วเทียบความเร็วในหน้าต่าง 2 กับผลของ `vel_eval`

ปิดเมื่อเลิกใช้: `make sim2sim-stop`

## 5. เก็บกวาด
โฟลเดอร์ทดลองอย่าง `myrun_500` ไม่ต้อง commit ถ้าจะเก็บ policy ไว้ใช้จริง ให้ตั้งชื่อตามที่มา (เช่น `phase4_stairs_3000`) แล้วเขียนบันทึกไว้ใน doc ของ repo ว่าเทรนจากอะไร และได้ผล `vel_eval` เท่าไร

---

## ทบทวนก่อนไป Day 4
- [ ] อธิบายได้ว่าโฟลเดอร์ policy มีไฟล์อะไร และแต่ละไฟล์ทำหน้าที่อะไร
- [ ] `gain-check` ตรวจอะไร และทำไมต้อง PASS ก่อน
- [ ] อ่าน JSON ของ `vel_eval` เป็น และรู้ว่า v0 ได้เท่าไร
- [ ] รู้ว่า `vel_eval` กับ `sim2sim` ต่างกันอย่างไร

ถัดไป: [Day 4: ซ้อมวันทดสอบใน sim](day4_real_robot_rehearsal.md)
