# Code Map: ไฟล์ที่เราสร้างและแก้ (G1 23-DoF)

> ย้ายมาจาก vault ของผู้ดูแล (`04 Code Map/00 Code Map.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-04
>
> คำสั่งในหน้านี้รันจากโฟลเดอร์ `<WS>/unitree_rl_mjlab` ใน env `g1_sdk` · `$S` = `deploy/robots/g1_23dof/scripts` (ตั้งด้วย `S=deploy/robots/g1_23dof/scripts`)

รวมทุกไฟล์ที่เราสร้าง (**A**) หรือแก้ (**M**) ตั้งแต่ 19/10/2026 ถึง 4/11/2026 ใน 4 repo พร้อมลำดับที่ควรอ่าน ใช้เป็นสารบัญเวลาเจาะเข้าไปศึกษาโค้ดทีละไฟล์
ที่มาของรายการ: `git log --author=Overdamp` และ `git status` ของแต่ละ repo (4/11/2026) ถ้าโค้ดเปลี่ยนหลังจากนี้ ให้รันคำสั่งในหัวข้อ › 11. วิธีอัพเดทแผนที่นี้

> [!TIP]
> **วิธีใช้**
> 1. อ่าน › 1. ภาพรวม repo ให้รู้ว่าแต่ละ repo ทำหน้าที่อะไร
> 2. เดินตาม › 2. ลำดับการศึกษา (แนะนำ) ทีละด่าน
> 3. เจอไฟล์ไหน เปิดหัวข้อของ repo นั้น (3–9) ดูว่าไฟล์ทำอะไรและ commit ไหนสร้าง
> 4. เวลาจดบันทึกการศึกษาแต่ละไฟล์ ให้สร้างโน้ตใหม่ในโฟลเดอร์ `04 Code Map/` นี้ แล้วลิงก์กลับมาที่ตาราง
> 5. โน้ตไล่โค้ดที่มีแล้ว: [FSM Code Walkthrough](fsm_code_walkthrough.md)

## สารบัญ
1. › 1. ภาพรวม repo
2. › 2. ลำดับการศึกษา (แนะนำ)
3. › 3. unitree_rl_mjlab: เทรน policy (Python, mjlab)
4. › 4. unitree_rl_mjlab: g1_ctrl ตัว deploy (C++)
5. › 5. unitree_rl_mjlab: สคริปต์เครื่องมือ (Python / bash)
6. › 6. unitree_rl_mjlab: เอกสาร
7. › 7. g1pilot: ROS 2 (state, RViz, teleop)
8. › 8. unitree_rl_lab: Isaac Lab cross-sim (ยังไม่ commit)
9. › 9. g1_sim2sim: benchmark และเอกสารแผน
10. › 10. ไฟล์นอก git (log, scratch, vault)
11. › 11. วิธีอัพเดทแผนที่นี้

---

## 1. ภาพรวม repo
| repo | path | branch | หน้าที่ | สถานะ git |
|---|---|---|---|---|
| **unitree_rl_mjlab** (fork) | `~/nvidia/unitree/unitree_rl_mjlab` | `phase3-delay-dr` (หลัก), `hist5-from-scratch` | เทรน policy + `g1_ctrl` (deploy C++) + เครื่องมือหุ่นจริง **← งานหลัก 90%** | commit + push แล้ว (ล่าสุด d9194fd, 4/11) |
| **g1pilot** (fork) | `~/Ros2_Directory/g1pilot_ws/src` | `g1-23dof` (sim), `g1-23dof-real` | ROS 2: อ่านสถานะ, RViz, keyboard teleop ผ่าน `loco_client` | commit + push แล้ว (เหลือ `docs/STATUS_2026-10-26.md`) |
| **unitree_rl_lab** | `~/nvidia/unitree/unitree_rl_lab` | – | Isaac Lab: 23dof task เพื่อเทียบข้าม sim | **ยังไม่ commit ทั้งหมด** |
| **g1_sim2sim** | `~/nvidia/unitree/g1_sim2sim` | – | benchmark sim2sim, เอกสารแผนเริ่มต้น | commit แล้ว (เหลือ `docs/knowledge_vault_g1.md`) |
| unitree_mujoco | `~/nvidia/unitree/unitree_mujoco` | – | simulator ที่คุย DDS เหมือนหุ่นจริง | **ไม่ได้แก้** (ใช้สำเนาใน scratchpad) |

```
          เทรน (mjlab, GPU/DGX)                       deploy
 src/tasks/velocity/config/g1_23dof/  ──export──►  deploy/robots/g1_23dof/config/policy/velocity/v0/
   env_cfgs.py, rl_cfg.py                            exported/policy.onnx + params/deploy.yaml
                                                              │ โหลดโดย
                                                              ▼
 unitree_mujoco (sim, lo) ◄──── DDS rt/lowstate / rt/lowcmd ────► g1_ctrl (C++ FSM)
 หุ่นจริง 161 (enp43s0)   ◄────────────────────────────────────┘     ▲
                                                              สคริปต์ Python อ่าน/ตรวจ DDS
                                                              (monitor, pd_check, sysid ...)
```

---

## 2. ลำดับการศึกษา (แนะนำ)
เรียงจาก "ภาพใหญ่" ไป "รายละเอียด" แต่ละด่านมีคำถามที่ควรตอบได้หลังอ่าน

### ด่าน 0: เข้าใจสิ่งที่ policy ต้องการ (30 นาที, ไม่ต้องอ่านโค้ด)
1. [Deploy Contract](deploy_contract.md), [Joint Map and Slots](joint_map_and_slots.md), [PD Control](../04-explanation/pd_control.md)
2. `unitree_rl_mjlab/doc/g1_23dof_summary/README.md` และ `01_training.md`
- ตอบได้: policy รับ observation อะไร ส่ง action อะไร ทำไม SDK มี 29 ช่องแต่ใช้ 23

### ด่าน 1: policy ถูกเทรนอย่างไร (Python)
| ลำดับ | ไฟล์ | ดูอะไร |
|---|---|---|
| 1.1 | `src/tasks/velocity/config/g1_23dof/__init__.py` | ชื่อ task ที่ register (`Unitree-G1-23Dof-Rough`, `-Flat`, `-Rough-Blind`) |
| 1.2 | `src/tasks/velocity/config/g1_23dof/env_cfgs.py` | ฟังก์ชัน `unitree_g1_23dof_rough_env_cfg()`: robot, sensor, reward, DR ต่อ phase |
| 1.3 | `src/tasks/velocity/mdp/events.py` | `delayed_effort_limits` = DR ความหน่วงของ action (Phase 3) |
| 1.4 | `src/tasks/velocity/config/g1_23dof/rl_cfg.py` | ขนาด network, PPO |
| 1.5 | `run_phase2_train.sh` → `run_phase3_train.sh` → `run_phase4_train.sh` | คำสั่งเทรนแต่ละ phase / resume |
| อ่านประกอบ | `doc/g1_23dof_dr_code_guide.md`, `doc/domain_randomization_phases_g1_23dof.md`, manager docs | |
- ตอบได้: P3b ต่างจาก P2 ตรงไหน ([Policy Lineage](policy_lineage.md)), DR อะไรบ้าง ([Domain Randomization](../04-explanation/domain_randomization.md))

### ด่าน 2: g1_ctrl รัน policy อย่างไร (C++) **สำคัญที่สุดก่อนขึ้นหุ่น**
| ลำดับ | ไฟล์ | ดูอะไร |
|---|---|---|
| 2.1 | `deploy/robots/g1_23dof/config/config.yaml` | state ทั้งหมด, ปุ่ม transition, kp/kd ของ Passive/FixStand, `policy_dir` |
| 2.2 | `deploy/robots/g1_23dof/main.cpp` | ลำดับเริ่มต้น: DDS → FSM → คีย์ sim |
| 2.3 | `deploy/include/FSM/CtrlFSM.h`, `FSMState.h`, `BaseState.h` (upstream + แก้บางส่วน) | loop ของ FSM, `pre_run/run/post_run`, การเช็ค transition |
| 2.4 | `deploy/include/FSM/State_Passive.h`, `State_FixStand.h` | damping / ค่อยๆ เข้าท่ายืน (`ts`, `qs`) |
| 2.5 | `deploy/include/FSM/State_RLBase.h` + `deploy/robots/g1_23dof/src/State_RLBase.cpp` | รัน ONNX ที่ 50 Hz, soft start 0.5 s, เช็คเอียง 0.85 rad |
| 2.6 | `deploy/include/isaaclab/envs/mdp/actions/joint_actions.h`, `observations/observations.h` | แปลง action → q_des (`action_scale`), สร้าง observation ให้ตรงกับตอนเทรน |
| 2.7 | `deploy/robots/g1_23dof/include/State_Handover.h` | state ใหม่: คืนการควบคุมให้ `ai` จากรีโมท |
| 2.8 | `deploy/robots/g1_23dof/config/policy/velocity/v0/params/deploy.yaml` | สัญญาระหว่างเทรนกับ deploy: joint map, stiffness/damping, scale |
- ตอบได้: กด L2 + ↑ แล้วเกิดอะไรในโค้ด, ทำไม LowState ขาด 100 ms แล้วเข้า Passive ([g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md), [Soft Start](../04-explanation/soft_start.md), [Handover](../02-how-to/handover.md))

### ด่าน 3: ตรวจ policy ใน sim ก่อนขึ้นหุ่น
| ลำดับ | ไฟล์ | ดูอะไร |
|---|---|---|
| 3.1 | `deploy/robots/g1_23dof/scripts/gain_check.py` | deploy.yaml ตรงกับค่าใน ONNX ไหม |
| 3.2 | `deploy/robots/g1_23dof/scripts/sim2sim_policy.sh` | รัน g1_ctrl สำเนาใน /tmp กับ policy โฟลเดอร์อื่น |
| 3.3 | `deploy/robots/g1_23dof/scripts/vel_eval.py` | วัด velocity tracking แบบ headless, `--hang` (ห้อยแล้วขาตีไหม) |
| 3.4 | `deploy/robots/g1_23dof/scripts/sim_speed_monitor.py` | ความเร็วเดินจริงใน sim2sim |
- ตอบได้: ทำไม Hist5 ห้ามเข้า Velocity ตอนแขวน ([Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md))

### ด่าน 4: อ่านและตรวจหุ่นจริงแบบไม่สั่งมอเตอร์ (read-only)
| ลำดับ | ไฟล์ | ดูอะไร |
|---|---|---|
| 4.1 | `scripts/lowstate_monitor.py` | โครงหลักที่สคริปต์อื่น import: `G1_23DOF_JOINTS`, การ subscribe, log CSV |
| 4.2 | `scripts/lowcmd_monitor.py` | จำแนกว่า lowcmd ตรงกับ gain ชุดไหน (`classify`, `expected_gains`) |
| 4.3 | `scripts/robot_health.py` | เช็คก่อนวันทดสอบ (PASS/WARN/FAIL) |
| 4.4 | `scripts/motion_mode.py` | MotionSwitcher RPC: check / release / select |
| 4.5 | `scripts/offset_check.py` | เทียบจุดชนสุดกับ 28/10 เพื่อตรวจค่าศูนย์ |
| 4.6 | `scripts/analyze_joint_sweep.py` | สรุปช่วงหมุนของข้อต่อจาก log |
| 4.7 | `scripts/deploy_byobu.sh` | จัดหน้าจอ 4 ช่อง T1–T4 ของวันทดสอบ |

### ด่าน 5: สั่งมอเตอร์และวัด kp/kd (actuating, บนรอก)
| ลำดับ | ไฟล์ | ดูอะไร |
|---|---|---|
| 5.1 | `scripts/sysid_motion.py` | step / chirp ต่อข้อต่อ, ระบบหยุด (`fault()`), ตรวจแผนก่อนส่ง |
| 5.2 | `scripts/pd_check.py` | fit `kp x` / `kd x`, delay, `--segments` (fit ต่อการทดสอบ + offset), `--replay` |
| 5.3 | `scripts/fixstand_train_gains.sh` | สร้าง g1_ctrl สำเนาที่ FixStand ใช้ gain เทรน |
- ตอบได้: ทำไม `pd_check` ทั้งหน้าต่างอ่านได้ 0.6 แต่ `--segments` ได้ 0.96 ([kp kd Verification](../02-how-to/kp_kd_verification.md))

### ด่าน 6: ROS 2 และการมองเห็น (ทางเลือก)
`g1pilot`: `launch/robot_state_23dof.launch.py` → `g1pilot/state/robot_state.py` → `g1pilot/teleoperation/keyboard_teleop.py` → `docker/run_real.sh`

### ด่าน 7: ข้าม sim (ทางเลือก)
`unitree_rl_lab/doc/g1_23dof_cross_sim_plan.md` → task 23dof → `scripts/play_deploy_onnx.py` ([Cross-Sim Isaac Lab](../04-explanation/cross_sim_isaac_lab.md))

---

## 3. unitree_rl_mjlab: เทรน policy (Python, mjlab)
branch `phase3-delay-dr`

| ไฟล์ | A/M | ทำอะไร | commit หลัก |
|---|---|---|---|
| `src/tasks/velocity/config/g1_23dof/__init__.py` | M | register task 23dof (Rough, Flat, Rough-Blind) | 843a27a (Phase 4) |
| `src/tasks/velocity/config/g1_23dof/env_cfgs.py` | M | env config 23dof: gain BeyondMimic, sensor, reward, DR, Phase 4 blind | 233aac8, 4f78cb0, 8035771, f96f209, 843a27a |
| `src/tasks/velocity/config/g1_23dof/rl_cfg.py` | (upstream) | PPO config (แก้ใน branch hist5) | – |
| `src/tasks/velocity/mdp/events.py` | M ⚠️ไฟล์ร่วม | `delayed_effort_limits`: DR action latency | 4f78cb0 |
| `src/tasks/velocity/mdp/__init__.py` | M ⚠️ไฟล์ร่วม | export ฟังก์ชันข้างบน | 4f78cb0 |
| `src/assets/robots/unitree_g1/xmls/scene_g1_23dof.xml` | M | ฉากของ 23dof | 233aac8 |
| `src/assets/robots/unitree_g1/xmls/scene_g1.xml` | M | ฉาก 29dof (แก้ตอนต้นโครงการ) | 233aac8 |
| `run_phase2_train.sh`, `run_phase3_train.sh`, `run_phase4_train.sh` | A | คำสั่งเทรน/resume แต่ละ phase | 233aac8 / 4f78cb0, 8035771 / 843a27a |

**branch `hist5-from-scratch`** (actor มี observation history 5 เฟรม, worktree `~/nvidia/unitree/unitree_rl_mjlab-hist5`)
| ไฟล์ | A/M | ทำอะไร |
|---|---|---|
| `src/tasks/velocity/config/g1_23dof/__init__.py`, `env_cfgs.py`, `rl_cfg.py` | M | task Hist5, Hist5-Yaw, Hist5-YawStand |
| `run_hist5_train.sh`, `run_hist5_yaw_finetune.sh`, `run_hist5_yaw_stand_finetune.sh` | A | คำสั่งเทรน (ตั้ง `PYTHONPATH=<worktree>`) |
| `scripts/check_hist5_obs_layout.py` | A | ตรวจลำดับ observation ที่มี history |
| `deploy/robots/g1_23dof/config/policy/velocity/hist5/params/deploy.yaml` | A | deploy contract ของ Hist5 |
| `deploy/robots/g1_23dof/scripts/vel_eval.py` | M | รองรับ history |

> [!WARNING]
> **ไฟล์ร่วม**
> `events.py` และ `mdp/__init__.py` เป็นไฟล์ที่ทุกหุ่นใช้ แก้ไปก่อนตั้งกติกา "แก้เฉพาะไฟล์ของ g1_23dof" (เพิ่มฟังก์ชันใหม่ ไม่ได้เปลี่ยนของเดิม) ถ้า merge จาก upstream ให้ดูตรงนี้ก่อน

---

## 4. unitree_rl_mjlab: g1_ctrl ตัว deploy (C++)
build: `cd deploy/robots/g1_23dof/build && make` (โฟลเดอร์ `build/` ไม่อยู่ใน git)

### 4.1 เฉพาะ g1_23dof
| ไฟล์ | A/M | ทำอะไร | commit |
|---|---|---|---|
| `deploy/robots/g1_23dof/main.cpp` | M | เริ่ม DDS + FSM, คีย์ sim `u/v/p/h`, LowState timeout 100 ms, ข้อความวิธีใช้ · **`--domain` + ค่าเริ่มต้น sim (lo, 1), บรรทัด `DDS: ... SIM/REAL ROBOT`** | 233aac8, e0851be, 77ddcd8, 4fc50cc |
| `deploy/robots/g1_23dof/config/config.yaml` | M | FSM: Passive / FixStand / Velocity / Handover, ปุ่ม, kp/kd, `policy_dir: .../v0` | 233aac8, 32a9f5e, 77ddcd8 |
| `deploy/robots/g1_23dof/src/State_RLBase.cpp` | M | soft start 0.5 s, เช็คเอียง (bad_orientation 0.85 rad) แบบ local | 233aac8, 2febdec, 32a9f5e |
| `deploy/robots/g1_23dof/include/State_Handover.h` | **A** | Passive → `SelectMode("ai")` → ปิดตัว (ทดสอบจริง 3/11) | 77ddcd8 |
| `deploy/robots/g1_23dof/include/keyboard_velocity_command.h` | A | คำสั่งความเร็วจากคีย์บอร์ด (sim) | 233aac8 |
| `deploy/robots/g1_23dof/include/keyboard_observation_config.h` | A | ตั้งค่า observation ตอนใช้คีย์บอร์ด | 233aac8 |
| `deploy/robots/g1_23dof/include/State_Mimic.h`, `Types.h`, `CMakeLists.txt` | (upstream) | ไม่ได้แก้ | – |

### 4.2 policy ที่ deploy (โฟลเดอร์ `config/policy/velocity/`)
| โฟลเดอร์ | เนื้อหา | ใช้ |
|---|---|---|
| `v0/` | `exported/policy.onnx` (= P3b), `policy_phase1_10000.onnx`, `policy_phase2_13000.onnx`, `policy_phase3b_16000.onnx`, `checkpoints/model_phase3b_15998.pt`, `params/deploy.yaml` | **ตัวหลักสำหรับหุ่นจริง** |
| `hist5_yawft/` | ONNX + deploy.yaml ของ Hist5 yaw fine-tune | sim เท่านั้น (ขาตีตอนแขวน) |
| `hist5_yawstand/` | ONNX + deploy.yaml ของ Hist5 YawStand | sim เท่านั้น |

### 4.3 ไฟล์ร่วมที่เคยแก้ (`deploy/include/`, ทุกหุ่นใช้) ⚠️
แก้ใน commit 233aac8 (22/10) ก่อนตั้งกติกา
| ไฟล์ | สิ่งที่แก้ |
|---|---|
| `deploy/include/FSM/FSMState.h` | Zero-Kp safety damping, ตัวแปรคีย์บอร์ด |
| `deploy/include/FSM/State_Passive.h` | damping |
| `deploy/include/FSM/State_RLBase.h` | โครงของ RLBase |
| `deploy/include/isaaclab/assets/articulation/articulation.h` | joint map |
| `deploy/include/isaaclab/envs/mdp/actions/joint_actions.h` | mapping gain 23dof |
| `deploy/include/isaaclab/envs/mdp/observations/observations.h` | observation |
| `deploy/robots/g1/main.cpp`, `deploy/robots/g1/src/State_RLBase.cpp`, `deploy/robots/g1/include/keyboard_*.h`, `deploy/robots/g1/tests/*` | ของหุ่น 29dof (ทดสอบ headless, คีย์บอร์ด) |
| `simulate/config.yaml` | ตั้งค่า sim ของ repo |
| `.gitignore` | ไม่ track `build/`, `__pycache__` |

---

## 5. unitree_rl_mjlab: สคริปต์เครื่องมือ (Python / bash)
ทั้งหมดอยู่ที่ `deploy/robots/g1_23dof/scripts/` (ย่อเป็น `$S`) รันด้วย `conda activate g1_sdk` ทุกไฟล์มี docstring บอกวิธีใช้ที่หัวไฟล์ (`python $S/<ไฟล์> -h`)

| ไฟล์ | บรรทัด | สั่งมอเตอร์? | ทำอะไร | commit | โน้ต |
|---|---|---|---|---|---|
| `lowstate_monitor.py` | 319 | ❌ | อ่าน `rt/lowstate`, ตาราง 23 ข้อต่อ, log CSV, `tau_est` **(โมดูลกลาง: สคริปต์อื่น import)** | 67353a7, 54df935, 4fc50cc | [LowState and LowCmd](lowstate_and_lowcmd.md) |
| `analyze_joint_sweep.py` | 143 | ❌ | สรุปช่วงหมุน/ทิศจาก log การหมุนมือ | 67353a7 | [Joint Map and Slots](joint_map_and_slots.md) |
| `lowcmd_monitor.py` | 223 | ❌ | อ่าน `rt/lowcmd`, บอก `gains match: ...` / `MISMATCH` | 54df935 | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| `pd_check.py` | 358 | ❌ | fit kp/kd จาก log คู่ state + cmd, `--replay`, `--segments` (fit ต่อการทดสอบ + offset), `fit_pd()` เก็บ P และ D ใน fit เสมอ | 54df935, fd8d80f, ece6d7a, d9194fd | [kp kd Verification](../02-how-to/kp_kd_verification.md) |
| `gain_check.py` | 115 | ❌ | deploy.yaml เทียบกับค่าใน ONNX | 32a9f5e | [Deploy Contract](deploy_contract.md) |
| `vel_eval.py` | 243 | ❌ (sim) | วัด velocity tracking, `--hang` | 54df935, 32a9f5e | [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md) |
| `sim_speed_monitor.py` | 92 | ❌ | ความเร็วเดินใน sim2sim | 32a9f5e | |
| `motion_mode.py` | 131 | ⚠️ เปลี่ยนโหมด | check / release / select `ai` | c0265df, 4fc50cc | [Motion Switcher](../04-explanation/motion_switcher.md) |
| `robot_health.py` | 132 | ❌ | เช็คสุขภาพหุ่น PASS/WARN/FAIL | b9c3eaa | [Real Robot Tools](real_robot_tools.md) |
| `offset_check.py` | 194 | ❌ | ค่าศูนย์ข้อต่อเทียบจุดชนสุด 28/10, เซฟผลลงไฟล์ | b9c3eaa | [Offset Check](../02-how-to/offset_check.md) |
| `sysid_motion.py` | 387 | ✅ | step / chirp ต่อข้อต่อบนรอก แทน g1_ctrl | 5cc5a13, 4fc50cc | [Sysid Motion](../02-how-to/sysid_motion.md) |
| `deploy_byobu.sh` | 99 | – | byobu 4 ช่อง (T1 lowstate, T2 lowcmd, T3 g1_ctrl, T4 คำสั่ง) · **ต้องใส่ `IFACE=`**, ไม่เปิดโหมดหุ่นถ้า sim เปิด | fd8d80f, 5cc5a13, 4fc50cc, 4318176 | [Test Day Procedure](../02-how-to/test_day_procedure.md) |
| `fixstand_train_gains.sh` | 80 | – | g1_ctrl สำเนาที่ FixStand ใช้ gain เทรน, ตัด Velocity | 5cc5a13 | [FixStand Train Gains](../04-explanation/fixstand_train_gains.md) |
| `sim2sim_policy.sh` | 46 | – | g1_ctrl สำเนาสำหรับลอง policy โฟลเดอร์อื่นใน sim | 32a9f5e | [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md) |

**ความสัมพันธ์ (ใคร import ใคร)**
```
lowstate_monitor.py ◄── analyze_joint_sweep, offset_check, robot_health, sysid_motion, pd_check
lowcmd_monitor.py   ◄── pd_check (classify, expected_gains, CONFIG_YAML, DEFAULT_DEPLOY)
```
อ่าน `lowstate_monitor.py` ก่อน แล้วสคริปต์อื่นจะเข้าใจง่ายขึ้นมาก

---

## 6. unitree_rl_mjlab: เอกสาร
| ไฟล์ | เนื้อหา |
|---|---|
| `doc/g1_23dof_summary/README.md` + `01`–`06` | **สรุปโครงการ 6 บท** (เทรน, sim2sim, kp/kd, เครื่องมือหุ่นจริง, ความปลอดภัย, cross-sim) เริ่มอ่านที่นี่ |
| `doc/g1_23dof_real_robot_setup_checklist.md` | checklist + ผลหุ่นจริงทุกวัน (ไฟล์ใหญ่สุด 431 บรรทัด) |
| `doc/g1_23dof_{action,command,curriculum,event,metrics,observation,reward,termination}_manager.md` | อธิบาย manager ของ mjlab ทีละตัว |
| `doc/g1_23dof_scene.md` | ฉาก/sensor |
| `doc/g1_23dof_dr_code_guide.md`, `doc/domain_randomization_g1_23dof.md`, `doc/domain_randomization_phases_g1_23dof.md` | DR ทั้งหมด ต่อ phase |
| `doc/g1_23dof_lowcmd_safety_reference.md` | ความปลอดภัยของ LowCmd |
| `doc/dgx_aarch64_local_git_setup.md` | DGX: ซ่อนไฟล์ build ARM จาก git (ห้าม force-checkout) |
| `doc/remote/remote_buttons_comparison.md` + PDF ของ Unitree | ปุ่มรีโมท 5 เวอร์ชัน firmware |
| `doc/print/*.html/.pdf` | แผ่นพิมพ์: deploy-day checklist, ตาราง manager config, ปุ่มรีโมท, แผ่นงาน 3/11 |

---

## 7. g1pilot: ROS 2 (state, RViz, teleop)
`~/Ros2_Directory/g1pilot_ws/src` · fork ของ hucebot/g1pilot · commit ของเรา 75f6336 → f8fc4a1 (26–28/10)

| ไฟล์ | A/M | ทำอะไร |
|---|---|---|
| `launch/robot_state_23dof.launch.py` | A | อ่านสถานะ + RViz (อ่านอย่างเดียว) **เริ่มที่นี่** |
| `launch/bringup_23dof.launch.py` | A | bringup เต็ม (มี `loco_client` ซึ่ง damp มอเตอร์ทันที) |
| `launch/bringup_23dof_sim.launch.py` | A | สำหรับ unitree_mujoco บน `lo` |
| `config/config_23dof.yaml`, `config/23dof.rviz` | A | พารามิเตอร์ / RViz 23dof |
| `description_files/urdf/g1_23dof_rev_1_0.urdf` | A | URDF 23dof Rev 1.0 |
| `g1pilot/state/robot_state.py` | M | motor index map 23dof, ปิดโปรแกรมเรียบร้อยตอน Ctrl-C |
| `g1pilot/navigation/loco_client.py` | M | ปิดโปรแกรมเรียบร้อยตอน Ctrl-C |
| `g1pilot/teleoperation/keyboard_teleop.py` | A | ขับด้วยคีย์บอร์ด (ปุ่มเดียวกับ g1_ctrl, เริ่มที่ครึ่งความเร็ว) |
| `docker/run.sh`, `run_sim.sh`, `run_real.sh`, `setup_uri.sh`, `cbuild`, `Dockerfile` | M/A | เปิด container, `ROS_DOMAIN_ID=1`, เช็คสาย LAN |
| `docker/validate_byobu.sh`, `docker/validate_viewer.py` | A | หน้าจอตรวจข้อต่อ (ใช้ 28/10) |
| `setup.py`, `package.xml`, `README.md`, `docs/PROJECT_OVERVIEW.md` | M/A | entry point, เอกสาร |
| `docs/STATUS_2026-10-26.md` | A (ยังไม่ commit) | สถานะ ณ 26/10 + บทเรียน DDS domain / multicast |

---

## 8. unitree_rl_lab: Isaac Lab cross-sim (ยังไม่ commit)
| ไฟล์ | A/M | ทำอะไร |
|---|---|---|
| `doc/g1_23dof_cross_sim_plan.md` | A | แผนเทียบ mjlab กับ Isaac Lab **เริ่มที่นี่** |
| `source/unitree_rl_lab/unitree_rl_lab/tasks/locomotion/robots/g1/23dof/__init__.py`, `velocity_env_cfg.py` | A | task 23dof ของ Isaac Lab (แยกจาก 29dof) |
| `source/unitree_rl_lab/unitree_rl_lab/assets/robots/unitree.py` | M | path โมเดล 23dof |
| `scripts/play_deploy_onnx.py` | A | เล่น ONNX จาก deploy ใน Isaac (`--visualizer newton`) |
| `unitree_model/` | A | ไฟล์โมเดลหุ่น |
env: `source ~/nvidia/IsaacLab-unitree/env_isaaclab/bin/activate` ([Environments Map](environments_map.md))

---

## 9. g1_sim2sim: benchmark และเอกสารแผน
commit ของเรา 72da704 → 44eceae (19–22/10) เป็นโครงการแรกก่อนย้ายมา unitree_rl_mjlab
| ส่วน | เนื้อหา |
|---|---|
| `docs/` | architecture, setup, training, sim2sim, evaluation, experiments, แผน Phase 2, safety, `knowledge_vault_g1.md` (ลิงก์มา vault นี้, ยังไม่ commit) |
| `scripts/` | `train.py`, `play.py`, `evaluate.py`, `export_policy.py`, `launch_sim.py`, `capture_lowstate.py`, `run_benchmark_suite.py` |
| `configs/`, `controller/`, `src/`, `tests/` | โครงของ benchmark harness (Exp 2, Exp 5 latency sweep) |
(เอกสารแผนเดิมอยู่ใน repo `g1_sim2sim` ของผู้ดูแล ไม่ได้ย้ายเข้า kit)

---

## 10. ไฟล์นอก git (log, scratch, vault)
| ที่ | อะไร | หมายเหตุ |
|---|---|---|
| `~/g1_state_<วันที่>_<tag><run>.csv`, `~/g1_cmd_...csv` | log จาก T1/T2 | ใหญ่ (สูงสุด 1.4 GB) |
| `~/sysid_seg_<วันที่>_*.csv` | ช่วงเวลาของแต่ละการทดสอบ sysid | ใช้กับ `pd_check --segments` |
| `~/offset_20261103_right.txt`, `~/offset_check_*.txt` | ผล offset_check | |
| `~/g1_joints_20261028_*.csv` | การหมุนข้อต่อ 28/10 (reference ของ offset_check) | |
| `/tmp/g1_fixstand_train/` | g1_ctrl สำเนาจาก `fixstand_train_gains.sh` | หายเมื่อรีบูต |
| `g1_23dof_kit/docs/` | ความรู้ + ผลทดสอบ (ย้ายมาจาก vault ของผู้ดูแล 10/11/2026) | อยู่ใน git |
| `~/env_isaaclab_before_newton.txt` | pip freeze ก่อนอัพเกรด newton | ใช้ rollback |

---

## 11. วิธีอัพเดทแผนที่นี้
```bash
# ไฟล์ที่เราสร้าง/แก้ ทั้งหมดใน unitree_rl_mjlab (เทียบกับก่อน commit แรกของเรา)
cd ~/nvidia/unitree/unitree_rl_mjlab
git diff --name-status 233aac8^ HEAD
git log --format='%h %ad %s' --date=short --author=Overdamp -- <ไฟล์>   # commit ที่แตะไฟล์นั้น
git status --short                                                      # ที่ยังไม่ commit

cd ~/Ros2_Directory/g1pilot_ws/src && git diff --stat 75f6336^ HEAD
cd ~/nvidia/unitree/unitree_rl_lab && git status --short
cd ~/nvidia/unitree/g1_sim2sim && git status --short
```

## ดูเพิ่ม
[README ของ kit](../../README.md) · [Real Robot Tools](real_robot_tools.md) · [Environments Map](environments_map.md) · [Policy Lineage](policy_lineage.md)
