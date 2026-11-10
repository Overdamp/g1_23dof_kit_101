# Cross-Sim Isaac Lab

> ย้ายมาจาก vault ของผู้ดูแล (`03 Training and Sim/Cross-Sim Isaac Lab.md`) เมื่อ 10/11/2026

## เป้าหมาย
เอา policy เดียวกัน (ONNX + deploy.yaml) ไปรันใน physics engine อื่น ถ้าผลใกล้กันทุก engine = policy ไม่ได้ "โกง" ฟิสิกส์ของ MuJoCo

## สิ่งที่ทำ
- **task ใหม่ใน unitree_rl_lab**: `Unitree-G1-23dof-Velocity` / `-Flat` (`tasks/locomotion/robots/g1/23dof/`) สืบทอด env cfg ของ 29dof (rewards ฯลฯ) แต่แทน robot, gain (armature·ω², ζ 2), armature, action scale **ด้วย `.replace()` ไม่แตะไฟล์ 29dof**
- **`scripts/play_deploy_onnx.py`**: ประเมิน ONNX ด้วย torch (ไม่ต้องมี onnxruntime) สร้าง obs จาก deploy.yaml ปิด events/terminations/curriculum/rewards พิมพ์ JSON ต่อกรณี

```bash
conda deactivate ; source ~/nvidia/IsaacLab-unitree/env_isaaclab/bin/activate
export OMNI_KIT_ACCEPT_EULA=YES ; cd ~/nvidia/unitree/unitree_rl_lab
P=~/nvidia/unitree/unitree_rl_mjlab/deploy/robots/g1_23dof/config/policy/velocity
python scripts/play_deploy_onnx.py --headless --policy-dir $P/v0                       # PhysX
python scripts/play_deploy_onnx.py --headless --policy-dir $P/v0 presets=newton        # Newton (MJWarp)
python scripts/play_deploy_onnx.py --visualizer newton --policy-dir $P/v0 --cases "0.4,0,0" --walk 30 presets=newton
```

## ผล (% ของคำสั่ง ไม่มีล้มทุกกรณี)
| P3b | 0.4 | 0.8 | 1.0 | หมุน | ข้าง |
|---|---|---|---|---|---|
| PhysX | 102 | 79 | 45 | 77 | 67 |
| Newton | 100 | 73 | 43 | 79–81 | 65 |
| MuJoCo | 97 | 74 | 41 | 69–73 | 59 |

| yaw_stand | 0.4 | 0.8 | 1.0 | หมุน | ข้าง |
|---|---|---|---|---|---|
| PhysX | 90 | 94 | 92 | 72–78 | 60 |
| Newton | 90 | 93 | 94 | 76–87 | 60 |
| MuJoCo | 88 | 94 | 95 | 72–80 | 56 |

**สรุป:** 3 engine ต่างกันไม่เกิน ~±8 pp → policy ทนต่อความต่างของ physics

## เทรนใน Isaac
ใช้ได้ทั้ง PhysX และ Newton (1024 envs ≈ 1.14 s/iteration บน RTX 3060) ช่วงต้น episode สั้นลงเหลือ ~10 step ซึ่ง 29dof ต้นฉบับก็เป็นเหมือนกัน ไม่ใช่ bug

## การแก้ env (2/11/2026)
| ปัญหา | แก้ |
|---|---|
| `omni.physics.tensors.api` ไม่มี | ไฟล์ shim `api.py` (`from .impl.api import *`) ใน extscache |
| Newton viewer: `Camera` ไม่มี `look_at`, contact sensor `measure_total` | อัป **newton 1.0.0 → 1.2.0** (รุ่นที่ worktree pin) + **mujoco 3.5 → 3.8.1** ด้วย `--no-deps` |
| Kit GUI / อัดวิดีโอ | ยังพัง (ติด Isaac Sim 6.0.0) ต้อง env Isaac Sim 6.2 |

ย้อนกลับ: `uv pip install --no-deps newton==1.0.0 mujoco==3.5.0 mujoco-warp==3.5.0.2` (freeze เดิม: `~/env_isaaclab_before_newton.txt`)

## ดูเพิ่ม
[Environments Map](../03-reference/environments_map.md) · [Deploy Contract](../03-reference/deploy_contract.md) · [Sim2Sim Evaluation](sim2sim_evaluation.md)
