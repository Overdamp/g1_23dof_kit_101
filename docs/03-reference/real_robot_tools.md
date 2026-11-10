# Real Robot Tools

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Real Robot Tools.md`) เมื่อ 10/11/2026

ทุกตัวอยู่ใน `unitree_rl_mjlab/deploy/robots/g1_23dof/scripts/` ใช้ env **`g1_sdk`** (มี unitree_sdk2py, onnxruntime, mujoco)

> [!WARNING]
> **ตั้งแต่ 5/11/2026 ค่าเริ่มต้น = sim (`lo`, domain 1)**
> หุ่นจริงต้องใส่ `--network enp43s0` ทุกครั้ง · บรรทัดแรกที่พิมพ์ต้องเป็น `DDS: REAL ROBOT ...` · ดู [DDS and Domains](../04-explanation/dds_and_domains.md) · คำสั่งพร้อมคัดลอก [terminal cmd](../02-how-to/terminal_cmd.md)

## อ่านอย่างเดียว (ปลอดภัยทุกเมื่อ)
| สคริปต์ | อ่าน | ใช้ทำอะไร |
|---|---|---|
| `robot_health.py` | lowstate, lowcmd, motion_switcher, bmsstate | สรุป PASS/WARN/FAIL ก่อนเริ่มวัน: Hz, mode_machine, lowcmd traffic, โหมด, **มอเตอร์ offline**, อุณหภูมิ, IMU, แบต |
| `offset_check.py` | lowstate | เทียบจุดชนสุดข้อต่อกับ 28/10 หาค่าศูนย์ที่เปลี่ยน ([Offset Check](../02-how-to/offset_check.md)) |
| `lowstate_monitor.py` | lowstate | สดทุก slot: q/dq/tau_est/temp, min/max, limit MJCF, gap, `--log` CSV (T1) |
| `lowcmd_monitor.py` | lowcmd | คำสั่งที่ g1_ctrl ส่ง ทั้ง 29 slot บอกว่า gain ตรงกับ Passive/FixStand/Velocity, `MISMATCH`, `--log` (T2) · `--deploy` รับ**ไฟล์** deploy.yaml |
| `motion_mode.py check` | motion_switcher | โหมดปัจจุบัน + lowcmd traffic ([Motion Switcher](../04-explanation/motion_switcher.md)) |
| `analyze_joint_sweep.py` | CSV | หาว่าขยับข้อต่อไหนเมื่อไร, crosstalk, ช่วงเทียบ MJCF |
| `pd_check.py` | CSV state + cmd | `kp x`, `kd x`, delay, `--replay` เทียบ MuJoCo ([kp kd Verification](../02-how-to/kp_kd_verification.md)) |
| `gain_check.py` | ไฟล์ policy | deploy.yaml ตรงกับ ONNX ไหม (ไม่ใช้หุ่น) ([Deploy Contract](deploy_contract.md)) |

## ส่งคำสั่ง / เปลี่ยนสถานะ (ทำตอนแขวนเท่านั้น)
| สคริปต์ | ทำอะไร |
|---|---|
| `motion_mode.py release` / `select ai` | สลับ debug ↔ ai |
| `sysid_motion.py` | สั่งท่าทีละข้อต่อแทน g1_ctrl ([Sysid Motion](../02-how-to/sysid_motion.md)) |
| `fixstand_train_gains.sh` | สร้าง g1_ctrl สำเนาที่ FixStand ใช้ gain ที่เทรน ([FixStand Train Gains](../04-explanation/fixstand_train_gains.md)) |
| `IFACE=enp43s0 deploy_byobu.sh [RUN] [TAG]` | เปิด byobu T1–T4 · **ต้องใส่ IFACE** (`lo` = ซ้อมใน sim) · ไม่ยอมเปิดโหมดหุ่นถ้า sim เปิดอยู่ ([Test Day Procedure](../02-how-to/test_day_procedure.md)) |

## sim
| สคริปต์ | ทำอะไร |
|---|---|
| `vel_eval.py` | sim2sim headless ([Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md)) |
| `sim2sim_policy.sh <folder>` | unitree_mujoco + g1_ctrl สำเนาที่ใช้ policy อื่น |
| `sim_speed_monitor.py` | ความเร็วจาก `rt/sportmodestate` (sim เท่านั้น) |

## อ่านค่าเร็วแบบไม่มีสคริปต์
```bash
env -u CYCLONEDDS_URI python - <<'PY'
import time
from unitree_sdk2py.core.channel import ChannelSubscriber, ChannelFactoryInitialize
from unitree_sdk2py.idl.unitree_hg.msg.dds_ import LowState_
ChannelFactoryInitialize(0, "enp43s0"); buf = []
ChannelSubscriber("rt/lowstate", LowState_).Init(lambda m: buf.append(m), 10)
time.sleep(2)
for i in (24, 25, 26):
    s = buf[-1].motor_state[i]
    print(i, s.q, s.vol, list(s.temperature), hex(s.motorstate))
PY
```

## log ที่เก็บไว้ (home, ไม่อยู่ใน git)
| ไฟล์ | เนื้อหา |
|---|---|
| `~/g1_baseline_20261028_1826.csv` | หุ่นนิ่ง 60 s |
| `~/g1_joints_20261028_1848.csv` (+ `_1927` เข่าขวา) | หมุนทุกข้อต่อจนสุด → reference ของ [Offset Check](../02-how-to/offset_check.md) |
| `~/g1_joints_20261028_1930.csv` | IMU |
| `~/g1_{state,cmd}_20261030_run1*.csv` | kp/kd บนรอก |
| `~/g1_{state,cmd}_20261030_sysid1.csv` | sysid ศอกซ้าย |

## ดูเพิ่ม
[LowState and LowCmd](lowstate_and_lowcmd.md) · ที่มา `doc/g1_23dof_summary/04_real_robot_tools.md`

คู่มือหน้าจอ T1–T4 และปุ่มลัด: [Byobu Guide](../02-how-to/byobu_guide.md)
