# Environments Map

> ย้ายมาจาก vault ของผู้ดูแล (`03 Training and Sim/Environments Map.md`) เมื่อ 10/11/2026

| งาน | env | ชนิด | activate |
|---|---|---|---|
| **unitree_rl_mjlab** (เทรน, sim2sim) | `unitree_rl_mjlab` | conda | `conda activate unitree_rl_mjlab` |
| สคริปต์ต่อหุ่น/sim (monitor, vel_eval, pd_check, sysid) | `g1_sdk` | conda | `conda activate g1_sdk` |
| unitree_rl_lab + Isaac (23dof task) | `~/nvidia/IsaacLab-unitree/env_isaaclab` | uv venv | `source .../bin/activate` |
| Isaac Lab v3.0.0 มาตรฐาน | `~/nvidia/IsaacLab/.venv` | uv | `uv run ...` |
| MicroDuck | `~/nvidia/IsaacLab-main/.venv` (ว่าง) | uv | – |

## รุ่นสำคัญ (2/11/2026)
| env | Isaac Sim | newton / warp | mujoco | torch |
|---|---|---|---|---|
| `IsaacLab/.venv` | 6.2.0 | 1.6.1 / 1.17 | 3.12 | 2.11 cu130 |
| `env_isaaclab` | 6.0.0 | **1.2.0** / 1.13 | **3.8.1** | 2.10 cu128 |
| conda `unitree_rl_mjlab` | – | – / 1.12 | 3.5 (mjlab 1.2.0) | 2.14 |

## กฎ
1. **`conda deactivate` ก่อน source uv venv** (PATH / LD_LIBRARY_PATH ชนกัน)
2. `source .../activate` = เอา `bin/` ของ env ไว้หน้า PATH ให้ `python` เป็นตัวของ env (ไม่ source ก็ได้ ถ้าเรียก path เต็ม)
3. ใน env_isaaclab ติดตั้งด้วย `uv pip install --no-deps` **ห้าม `uv sync`** (ลบ isaacsim)
4. ใน `~/nvidia/IsaacLab` ต้อง `uv sync --extra isaacsim` เสมอ
5. รัน Isaac: `export OMNI_KIT_ACCEPT_EULA=YES`
6. สคริปต์ Unitree SDK: `env -u CYCLONEDDS_URI` ([DDS and Domains](../04-explanation/dds_and_domains.md))
7. ดิสก์ /home เหลือน้อย (~50 GB) uv ใช้ cache ร่วม conda ดาวน์โหลดซ้ำ

## ทางลัดใน kit (แทน alias ใน `~/.bashrc` ของผู้ดูแล)
| ต้นฉบับ (bashrc ผู้ดูแล) | ใน kit | ทำอะไร |
|---|---|---|
| `g1net` | `sudo ip addr replace 192.168.123.123/24 dev enp43s0 && sudo ip link set enp43s0 up && sudo ip link set lo multicast on` | IP บน `enp43s0` + multicast บน `lo` (ต้อง sudo จึงไม่มี make target) |
| `g1env` | `conda activate g1_sdk && cd <WS>/unitree_rl_mjlab && unset CYCLONEDDS_URI && S=deploy/robots/g1_23dof/scripts D=$(date +%Y%m%d)` | repo + env `g1_sdk` + unset `CYCLONEDDS_URI` + ตัวแปร `$S` `$D` |
| `g1sim` | `make sim` (`SIM_DOMAIN=0` สำหรับ g1pilot) | unitree_mujoco (lo, domain 1) |
| `g1sim_band` | `make sim-band` | sim ที่มีเชือก · ปุ่ม 9 / 7 / 8 |
| `g1ctrl_sim` | `make ctrl-sim` | g1_ctrl กับ sim |
| `g1ctrl_real` | `make deploy-real IFACE=enp43s0` | ด่านตรวจ + พิมพ์ `real` แล้วเปิดชุดเครื่องมือวันทดสอบ |
| `ros_lo` | `export ROS_DOMAIN_ID=1 CYCLONEDDS_URI='<CycloneDDS><Domain><General><Interfaces><NetworkInterface name="lo" /></Interfaces></General></Domain></CycloneDDS>'` | ROS 2 บน lo + `ROS_DOMAIN_ID=1` เฉพาะ terminal นั้น |

- อย่า export `CYCLONEDDS_URI` / `ROS_DOMAIN_ID` ไว้ใน `~/.bashrc` · `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` ตั้งทั่วไปได้
- แนะนำ: เพิ่ม history ใน `~/.bashrc` (`HISTSIZE=100000`, `HISTFILESIZE=200000`, `PROMPT_COMMAND="history -a"`) แล้วค้นด้วย Ctrl + R

## ดูเพิ่ม
[Cross-Sim Isaac Lab](../04-explanation/cross_sim_isaac_lab.md) · [Training Practice](../02-how-to/training_practice.md) · [Troubleshooting](../02-how-to/troubleshooting.md)
