# g1_23dof_kit

ชุดเริ่มต้นสำหรับโปรเจค Unitree G1 23-DoF: เทรน policy เดินด้วย mjlab → ทดสอบ sim2sim → deploy ขึ้นหุ่นจริง
โคลนแล้วทำตามหน้านี้ จะเห็นหุ่นเดินใน sim ภายใน ~30 นาที (ไม่รวมเวลาดาวน์โหลด)

> [!warning] ความปลอดภัย
> ทุกคำสั่งใช้ **sim เป็นค่าเริ่มต้น** หุ่นจริงต้องสั่ง `make deploy-real IFACE=enp43s0` และพิมพ์ `real` ยืนยัน
> ทดสอบหุ่นจริงเฉพาะเป็นกลุ่ม หุ่นแขวนบน gantry และมีคนถือรีโมทพร้อมกด damp เสมอ

## สิ่งที่ต้องมี
- Ubuntu 22.04, การ์ดจอ NVIDIA (driver ≥ 550), Miniconda
- (ถ้าใช้ Docker) Docker + nvidia-container-toolkit

## Quickstart
```bash
git clone <url ของ repo นี้> g1_23dof_kit && cd g1_23dof_kit
make            # ดูคำสั่งทั้งหมด
make apt        # พิมพ์คำสั่ง apt ให้ ก๊อปไปรันเอง (ต้อง sudo)
make clone      # โคลน repo ตาม repos.lock ลง ./repos
make envs       # สร้าง conda env: unitree_rl_mjlab (เทรน), g1_sdk (เครื่องมือหุ่น/sim2sim)
make sdk2       # build unitree_sdk2 แล้วรันคำสั่ง sudo ที่มันพิมพ์ให้
make build      # build unitree_mujoco (sim) + g1_ctrl (controller)
make doctor     # ต้องได้ 0 FAIL
make smoke      # เทรน 3 iteration + sim2sim แบบไม่มีหน้าจอ ต้องได้ PASS ทั้งสองข้อ
make sim2sim POLICY=v0   # เปิด sim + g1_ctrl ใน tmux แล้วเดินด้วยคีย์บอร์ด
```
มี repo อยู่แล้วที่อื่น: ใส่ `WS=<โฟลเดอร์>` ต่อท้ายทุกคำสั่ง เช่น `make doctor WS=~/nvidia/unitree`

ถ้าขั้นไหนไม่ผ่าน ดู [docs/pitfalls.md](docs/pitfalls.md) ก่อน

## โครงสร้าง
```
g1_23dof_kit/
├── Makefile            ← ทางเข้าทางเดียว: make <target>
├── repos.lock          ← repo + commit ที่ทดสอบแล้วว่าใช้ด้วยกันได้
├── envs/               ← conda env (ล็อกเวอร์ชัน)
├── scripts/            ← doctor.sh, clone_repos.sh, make_envs.sh
├── tests/smoke.sh      ← ทดสอบเร็วตั้งแต่ต้นจนจบ
├── docker/             ← Dockerfile + compose (ทางเลือก, ร่าง)
├── docs/               ← คู่มือ (ดูด้านล่าง)
└── repos/              ← make clone ใส่ repo ที่นี่ (ไม่อยู่ใน git)
```

## คู่มือ
| โฟลเดอร์ | ใช้เมื่อ |
|---|---|
| [docs/01-tutorials](docs/01-tutorials) | มาใหม่ ทำตามทีละขั้นตามลำดับวัน |
| [docs/02-how-to](docs/02-how-to) | รู้ว่าจะทำอะไร ต้องการขั้นตอน (runbook) |
| [docs/03-reference](docs/03-reference) | หาค่า, flag, ตาราง |
| [docs/04-explanation](docs/04-explanation) | อยากรู้ว่าทำไมออกแบบแบบนี้ |
| [docs/pitfalls.md](docs/pitfalls.md) | เจอ error |

## กติกาของ repo
- ห้ามใส่รหัสผ่านหรือ token ในไฟล์ใดๆ ใช้ `.env` (อยู่ใน `.gitignore`)
- จะเปลี่ยน commit ใน `repos.lock` ต้องรัน `make smoke` ผ่านก่อน
- ไฟล์ `.pt` / `.onnx` ใหญ่ ไม่เก็บใน git ให้แนบ GitHub Release
