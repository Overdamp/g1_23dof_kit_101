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
> [!IMPORTANT]
> repo นี้เป็น **private** (มีข้อมูลภายในแลป) ก่อนโคลนต้อง
> 1. มีบัญชี GitHub และให้ผู้ดูแลเพิ่มเป็น collaborator ของ `Overdamp/g1_23dof_kit_101`
> 2. ตั้งการยืนยันตัวตนบนเครื่องอย่างใดอย่างหนึ่ง: `gh auth login` (GitHub CLI) หรือ personal access token (ใส่แทนรหัสผ่านตอน git ถาม) หรือ SSH key
>
> repo อื่นใน `repos.lock` เป็น public โคลนได้โดยไม่ต้องยืนยันตัวตน

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
มี repo อยู่แล้วที่อื่น (ไม่ใช้ `make clone`): บอก kit ครั้งเดียวด้วย `make set-ws WS=~/nvidia/unitree` ค่าจะถูกเก็บใน `local.mk` (ไม่เข้า git) หลังจากนั้นพิมพ์ `make <target>` ได้เลย
ไม่ต้อง `conda activate` เอง ทุก target เปิด env ที่ถูกต้องให้

อยากสั่งจากโฟลเดอร์ไหนก็ได้ (ไม่บังคับ): เพิ่มใน `~/.bashrc`
```bash
alias g1k='make -C ~/nvidia/unitree/g1_23dof_kit'   # แก้ path ให้ตรงกับที่โคลนไว้
```
แล้วใช้ `g1k doctor`, `g1k sim2sim POLICY=v0` ได้ทุกที่ (`make` ปกติอ่าน `Makefile` ในโฟลเดอร์ที่ยืนอยู่เท่านั้น)

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
| [docs/04-explanation/basics](docs/04-explanation/basics/README.md) | **มือใหม่อ่านก่อน:** terminal, env var, conda, make, DDS, ROS 2, worktree, tmux |
| [docs/01-tutorials](docs/01-tutorials) | มาใหม่ ทำตามทีละขั้นตามลำดับวัน |
| [docs/02-how-to](docs/02-how-to) | รู้ว่าจะทำอะไร ต้องการขั้นตอน (runbook) |
| [docs/03-reference](docs/03-reference) | หาค่า, flag, ตาราง · [make_targets.md](docs/03-reference/make_targets.md) = แต่ละ `make` รันอะไรจริง |
| [docs/04-explanation](docs/04-explanation) | อยากรู้ว่าทำไมออกแบบแบบนี้ |
| [docs/05-history](docs/05-history/README.md) | เหตุการณ์และผลทดสอบหุ่นจริงที่ผ่านมา |
| [docs/pitfalls.md](docs/pitfalls.md) | เจอ error |
| [docs/ROADMAP.md](docs/ROADMAP.md) | แผนพัฒนา kit + checklist |

## กติกาของ repo
- ห้ามใส่รหัสผ่านหรือ token ในไฟล์ใดๆ ใช้ `.env` (อยู่ใน `.gitignore`)
- จะเปลี่ยน commit ใน `repos.lock` ต้องรัน `make smoke` ผ่านก่อน
- ไฟล์ `.pt` / `.onnx` ใหญ่ ไม่เก็บใน git ให้แนบ GitHub Release
