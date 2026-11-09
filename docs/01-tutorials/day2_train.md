# Day 2: เทรน policy เอง แล้วดูผล

**เป้าหมาย:** เทรน task `Unitree-G1-23Dof-Flat` เอง, อ่านกราฟใน TensorBoard เป็น, เปิดดู checkpoint ใน viewer ได้
**ก่อนเริ่ม:** Day 1 ผ่านแล้ว (`make doctor` 0 FAIL)

> **คาดหวังให้ถูก:** policy ที่ใช้จริง (P3b) เทรนรวมกว่า 16,000 iteration ต่อกันหลาย phase ([doc ใน repo](https://github.com/Overdamp/unitree_rl_mjlab/blob/phase3-delay-dr/doc/g1_23dof_summary/01_training.md))
> วันนี้เทรนสั้นๆ เพื่อดูว่ากระบวนการทำงานอย่างไร หุ่นจะยังเดินไม่ดี เป็นเรื่องปกติ

---

## 1. ดูว่ามี task อะไรบ้าง
**คำสั่งเต็ม:**
```bash
conda activate unitree_rl_mjlab
cd repos/unitree_rl_mjlab
PYTHONPATH=$PWD python scripts/list_envs.py      # ทำไมต้อง PYTHONPATH: basics/07
```
**ทางลัด:** `make tasks`

**ผลที่ต้องเห็น:** มี `Unitree-G1-23Dof-Flat`, `Unitree-G1-23Dof-Rough-Blind` และอื่นๆ (task ของ G1 23-DoF นิยามไว้ใน `src/tasks/velocity/config/g1_23dof/`)

## 2. เทรนสั้นๆ
**คำสั่งเต็ม:**
```bash
PYTHONPATH=$PWD python scripts/train.py Unitree-G1-23Dof-Flat \
  --env.scene.num-envs=1024 --agent.max-iterations=500 --agent.logger=tensorboard
```
**ทางลัด:** `make train ITERS=500`

| ตัวเลือก | ความหมาย |
|---|---|
| `num-envs=1024` | จำลองหุ่น 1024 ตัวพร้อมกันบน GPU ยิ่งมากยิ่งเรียนเร็ว แต่กิน VRAM (GPU 6 GB ถ้าเต็มให้ลดเป็น 512: `make train ENVS=512 ITERS=500`) |
| `max-iterations=500` | รอบการเรียน แต่ละรอบ = เก็บข้อมูลจากทุก env แล้วอัปเดต policy หนึ่งครั้ง |
| `logger=tensorboard` | บันทึกกราฟไว้ในเครื่อง (ไม่ต้องมีบัญชี wandb) |

**ผลที่ต้องเห็น:** ทุกรอบจะพิมพ์บล็อกแบบนี้
```
Learning iteration 0/500
          Mean reward: -1.60
  Mean episode length: 13.57
       Iteration time: 1.94s
                  ETA: ...
```
บน RTX 3060 laptop ใช้ราว 2 วินาทีต่อรอบ (500 รอบ ≈ 15–20 นาที) ดูเวลาที่เหลือได้จาก `ETA`

**ไฟล์ที่ได้:** `logs/rsl_rl/g1_23dof_velocity/<วันเวลา>/`
- `model_<n>.pt`: checkpoint บันทึกทุก 100 รอบ
- `policy.onnx`: export ใหม่ทุกครั้งที่บันทึก checkpoint (ใช้ใน Day 3)
- `params/env.yaml`, `params/agent.yaml`: ค่าตั้งที่ใช้เทรนจริง

## 3. ดูกราฟระหว่างเทรน
เปิดอีก terminal หนึ่ง
**คำสั่งเต็ม:**
```bash
conda activate unitree_rl_mjlab && cd repos/unitree_rl_mjlab
tensorboard --logdir logs/rsl_rl
```
**ทางลัด:** `make tensorboard` แล้วเปิด http://localhost:6006

| กราฟ | ดีขึ้นแปลว่า |
|---|---|
| `Train/mean_reward` | ขึ้น = เรียนรู้ได้ |
| `Train/mean_episode_length` | ขึ้นจนชนเพดาน = ล้มน้อยลง อยู่ได้จนหมดเวลา |
| `Episode_Termination/fell_over` | ลง = ล้มน้อยลง |
| `Metrics/twist/error_vel_xy` | ลง = เดินตามคำสั่งความเร็วแม่นขึ้น |

## 4. ดู checkpoint ใน viewer
**คำสั่งเต็ม:**
```bash
PYTHONPATH=$PWD python scripts/play.py Unitree-G1-23Dof-Flat \
  --checkpoint-file logs/rsl_rl/g1_23dof_velocity/<วันเวลา>/model_500.pt --num-envs 16 --viewer viser
```
**ทางลัด:** `make play CKPT=<path ของ model_500.pt>`

viser เปิดใน browser ที่ http://localhost:8080 ถ้าอยากใช้หน้าต่าง MuJoCo ให้ใส่ `VIEWER=native`
| | viser (ค่าเริ่มต้น) | native |
|---|---|---|
| ความลื่น | ลื่น (browser เป็นคนวาด) | กระตุกเมื่อมีหลาย env (Python วาดเองใน loop ฟิสิกส์) |
| ใช้เมื่อ | ดูภาพรวม, ดูจากเครื่องอื่นผ่าน `ssh -L 8080:localhost:8080` | อยากเอาเมาส์ผลักหุ่น: ดับเบิลคลิกที่ตัวหุ่น แล้วกด Ctrl ค้างพร้อมลากเมาส์ขวา |

**ผลที่ต้องเห็น:** หุ่น 16 ตัวพยายามเดินตามคำสั่ง (หลัง 500 รอบส่วนใหญ่จะยังล้มหรือก้าวไม่เป็น)

เทียบกับ policy ที่เทรนเสร็จแล้ว:
```bash
make play CKPT=repos/unitree_rl_mjlab/deploy/robots/g1_23dof/config/policy/velocity/v0/checkpoints/model_phase3b_15998.pt
```

## 5. (ไม่บังคับ) เทรนต่อจาก checkpoint
```bash
PYTHONPATH=$PWD python scripts/train.py Unitree-G1-23Dof-Flat --env.scene.num-envs=1024 \
  --agent.resume=True --agent.load-run=<ชื่อโฟลเดอร์วันเวลา> --agent.load-checkpoint=model_500.pt
```
โปรเจคใช้วิธีนี้ต่อ phase กัน ดูตัวอย่างได้ใน `run_phase3_train.sh` และ `run_phase4_train.sh` ใน repo

---

## ทบทวนก่อนไป Day 3
- [ ] เทรนได้ และหาโฟลเดอร์ run ของตัวเองเจอ
- [ ] อธิบายได้ว่า `mean_reward` กับ `mean_episode_length` บอกอะไร
- [ ] เปิด viewer ได้ทั้งแบบ viser และ native
- [ ] รู้ว่า `policy.onnx` ถูกสร้างไว้ที่ไหน

ถัดไป: [Day 3: export และ sim2sim](day3_export_and_sim2sim.md)
