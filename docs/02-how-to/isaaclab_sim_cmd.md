# g1_23_dof isaaclab_sim cmd

> ย้ายมาจาก vault ของผู้ดูแล (`06 my_note/g1_23_dof isaaclab_sim cmd.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-05

คำสั่งรัน G1 23-DoF ใน **Isaac Lab** (PhysX และ Newton/MJWarp) ใช้ทำ **cross-sim**: เอา policy ที่เทรนจาก mjlab ไปรันใน physics engine อื่น ถ้าผลใกล้กัน = policy ไม่ได้พึ่งฟิสิกส์เฉพาะของ MuJoCo · เทรนใน Isaac ก็ทำได้
ฝั่ง MuJoCo: [g1_23_dof mujoco_sim cmd](mujoco_sim_cmd.md) · รายละเอียด/ผล: [Cross-Sim Isaac Lab](../04-explanation/cross_sim_isaac_lab.md)

## ภาพรวม
```
unitree_rl_mjlab (เทรน MuJoCo)  ──policy.onnx + deploy.yaml──▶  unitree_rl_lab/scripts/play_deploy_onnx.py
                                                                     ├── PhysX  (ค่าเริ่มต้น)
                                                                     └── Newton (presets=newton)
unitree_rl_lab/scripts/rsl_rl/train.py  ← เทรนใน Isaac เอง (task Unitree-G1-23dof-Velocity[-Flat])
```

## โครงสร้างโฟลเดอร์
```
~/nvidia/IsaacLab-unitree/                          ← Isaac Lab worktree ที่ unitree_rl_lab ต้องใช้ (commit 207f319d9)
└── env_isaaclab/                                   ← uv venv: Isaac Sim 6.0.0, torch 2.10, newton 1.2.0, mujoco 3.8.1
    └── bin/activate

~/nvidia/unitree/unitree_rl_lab/                    ← repo Unitree (branch isaaclab3.0)
├── scripts/
│   ├── rsl_rl/train.py, play.py, cli_args.py       ← เทรน / ดู checkpoint ของ Isaac
│   ├── play_deploy_onnx.py                         ← เล่น policy.onnx + deploy.yaml จาก mjlab (cross-sim)
│   └── list_envs.py
├── source/unitree_rl_lab/unitree_rl_lab/tasks/locomotion/
│   ├── robots/g1/23dof/
│   │   ├── __init__.py                             ← ลงทะเบียน Unitree-G1-23dof-Velocity / -Velocity-Flat
│   │   └── velocity_env_cfg.py                     ← สืบทอด 29dof แล้ว .replace() robot, gain, armature, action scale
│   ├── robots/g1/29dof/                            ← ต้นฉบับ (ไม่แก้)
│   └── agents/rsl_rl_ppo_cfg.py                    ← PPO (experiment_name = ชื่อ task)
├── logs/rsl_rl/<task>/<วันเวลา>/                   ← checkpoint เมื่อเทรนใน Isaac
├── doc/g1_23dof_cross_sim_plan.md                  ← แผน + บันทึก cross-sim
└── unitree_rl_lab.sh                               ← ❌ อย่าใช้ (เรียก python ของ conda)

~/nvidia/unitree/unitree_rl_mjlab/deploy/robots/g1_23dof/config/policy/velocity/<ชื่อ>/   ← policy ที่จะเอามาเล่น
├── exported/policy.onnx
└── params/deploy.yaml

~/nvidia/IsaacLab/            ← Isaac Lab v3.0.0 มาตรฐาน (.venv ของตัวเอง, Isaac Sim 6.2) ไม่ใช้กับ unitree_rl_lab
~/nvidia/IsaacLab-main/       ← สำหรับ MicroDuck
```

## 0. เปิด env (ทุก terminal ใหม่)
```bash
# conda กับ uv venv ชนกัน (PATH / LD_LIBRARY_PATH) ต้องปิด conda ก่อน
conda deactivate
source ~/nvidia/IsaacLab-unitree/env_isaaclab/bin/activate
# ยอมรับ EULA ของ Omniverse ไม่งั้น Isaac ค้างรอถาม
export OMNI_KIT_ACCEPT_EULA=YES
cd ~/nvidia/unitree/unitree_rl_lab
# path ไปยัง policy ที่เทรนจาก mjlab
P=~/nvidia/unitree/unitree_rl_mjlab/deploy/robots/g1_23dof/config/policy/velocity
```

## 1. cross-sim: เล่น policy จาก mjlab ใน Isaac
```bash
# PhysX แบบไม่มีหน้าจอ · วัดหลายกรณีความเร็วแล้วพิมพ์ JSON (% ของคำสั่ง, ล้มไหม)
python scripts/play_deploy_onnx.py --headless --policy-dir $P/v0
# Newton (MJWarp) แบบไม่มีหน้าจอ
python scripts/play_deploy_onnx.py --headless --policy-dir $P/v0 presets=newton
# ดูด้วยตา: viewer ของ Newton · เดินหน้า 0.4 m/s นาน 30 s
python scripts/play_deploy_onnx.py --visualizer newton --policy-dir $P/v0 --cases "0.4,0,0" --walk 30 presets=newton
# policy อื่น เช่น yaw_stand
python scripts/play_deploy_onnx.py --headless --policy-dir $P/hist5_yawstand
```
option ที่ใช้บ่อย: `--cases "vx,vy,wz;..."` · `--settle` (วินาทีก่อนเดิน, 2) · `--walk` (12) · `--measure` (8) · `--task` (ค่าเริ่มต้น `Unitree-G1-23dof-Velocity-Flat`) · `--no-smooth` (ไม่ทำ smoothing คำสั่งแบบ g1_ctrl)

เกณฑ์: ผลต่างจาก `vel_eval.py` (MuJoCo) ไม่เกิน ~±8 pp และไม่ล้ม

## 2. เทรน / play ใน Isaac
```bash
# ทดสอบว่า env ใช้ได้: 64 envs, 2 iteration
python scripts/rsl_rl/train.py --task Unitree-G1-23dof-Velocity --headless --num_envs 64 --max_iterations 2
# เทรนจริง (1024 envs ≈ 1.14 s/iteration บน RTX 3060)
python scripts/rsl_rl/train.py --task Unitree-G1-23dof-Velocity --headless --num_envs 1024
# พื้นเรียบ + Newton
python scripts/rsl_rl/train.py --task Unitree-G1-23dof-Velocity-Flat --headless --num_envs 1024 presets=newton
# เทรนต่อ
python scripts/rsl_rl/train.py --task Unitree-G1-23dof-Velocity --headless --resume --load_run <วันเวลา> --checkpoint model_<n>.pt
# ดู checkpoint ของ Isaac (Kit GUI ยังพังบน Isaac Sim 6.0.0 → ใช้ headless หรือ --visualizer newton)
python scripts/rsl_rl/play.py --task Unitree-G1-23dof-Velocity --num_envs 16 --headless
```
ช่วงแรก episode สั้นมาก (~10 step) เป็นปกติ 29dof ต้นฉบับก็เป็น

## 3. ปัญหาที่เจอแล้ว
| อาการ | สาเหตุ / แก้ |
|---|---|
| `No module named omni.physics.tensors.api` | Isaac Sim 6.0.0 ย้ายไป `impl.api` → มีไฟล์ shim `api.py` ใน extscache แล้ว (ลบ = กลับสภาพเดิม) |
| isaacsim หายจาก env | เผลอ `uv sync` → **ใน env_isaaclab ใช้ `uv pip install --no-deps` เท่านั้น** |
| Kit GUI / อัดวิดีโอไม่ได้ | ข้อจำกัด Isaac Sim 6.0.0 ใช้ `--visualizer newton` แทน |
| ใช้ `./unitree_rl_lab.sh` แล้วพัง | สคริปต์นั้นใช้ python จาก `$CONDA_PREFIX` ให้เรียก `python scripts/...` หลัง source venv |
| GPU memory เต็ม (6 GB) | ลด `--num_envs` · ปิด sim ตัวอื่น |

ย้อน newton/mujoco กลับรุ่นเดิม: `uv pip install --no-deps newton==1.0.0 mujoco==3.5.0 mujoco-warp==3.5.0.2`

## ดูเพิ่ม
[Cross-Sim Isaac Lab](../04-explanation/cross_sim_isaac_lab.md) · [Environments Map](../03-reference/environments_map.md) · [Deploy Contract](../03-reference/deploy_contract.md) · [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md)
