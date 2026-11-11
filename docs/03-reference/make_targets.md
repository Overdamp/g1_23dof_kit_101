# make targets: แต่ละคำสั่งรันอะไรจริง

`make` ใน kit นี้เป็นแค่**ทางลัด** แต่ละ target รันคำสั่ง 1–3 คำสั่ง ที่ไปเรียกสคริปต์หรือโปรแกรมจริงในตารางข้างล่าง
ไม่มี make ก็ทำงานได้: ก๊อปคอลัมน์ "คำสั่งจริง" ไปพิมพ์เองได้เลย

ดูคำสั่งจริงบนเครื่องตัวเอง (แทน path ให้แล้ว) โดยไม่รัน:
```bash
make -n <target>          # เช่น make -n sim2sim POLICY=v0
```

> ตารางนี้ถูกตรวจโดย `make check` ถ้าเพิ่ม target ใน Makefile แล้วไม่เพิ่มแถวที่นี่ (หรือ target ยาวเกิน 3 คำสั่ง) `make check` จะ FAIL

## ตัวย่อในตาราง

| ตัวย่อ | หมายถึง |
|---|---|
| `KIT` | โฟลเดอร์ของ kit นี้ (ที่มี `Makefile`) |
| `WS` | โฟลเดอร์ที่เก็บ repo: ค่าเริ่มต้น `KIT/repos` หรือค่าใน `local.mk` (ตั้งด้วย `make set-ws`) |
| `RL` | `WS/unitree_rl_mjlab` |
| `ROBOT` | `RL/deploy/robots/g1_23dof` |
| `SCRIPTS` | `ROBOT/scripts` |

## ตัวช่วย 3 ตัวที่ขึ้นต้นเกือบทุก target

| ใน Makefile | ทำอะไร | ทำไม |
|---|---|---|
| `$(need_ws)` | `test -d RL` ถ้าไม่มีให้หยุด แล้วบอกให้ `make clone` หรือ `make set-ws` | ข้อความชัดกว่า `cd: No such file` |
| `$(in_rl)` | `source conda.sh && conda activate unitree_rl_mjlab && cd RL && PYTHONPATH=RL` | env นี้ติดตั้ง checkout หนึ่งไว้แบบ editable ถ้าไม่ตั้ง `PYTHONPATH` จะโหลดโค้ดจาก checkout นั้นแทน (เช่นตอนอยู่ใน git worktree) |
| `$(in_sdk)` | `source conda.sh && conda activate g1_sdk && cd RL && env -u CYCLONEDDS_URI` | ถ้ามี `CYCLONEDDS_URI` ค้างจาก terminal ROS จะทับ `--network` (ดู [pitfalls](../pitfalls.md)) |

## Start here

| target | ทำอะไร | คำสั่งจริง | ไฟล์ที่ทำงานจริง |
|---|---|---|---|
| `help` | แสดงรายการ target (พิมพ์ `make` เฉยๆ ก็ได้) | `awk` อ่านบรรทัด `## ...` ใน Makefile | `KIT/Makefile` |
| `set-ws` | จำที่อยู่ repo ของเครื่องนี้ | `echo "WS := <path>" > KIT/local.mk` | `KIT/local.mk` (ไม่เข้า git) |
| `doctor` | ตรวจเครื่อง PASS / WARN / FAIL ไม่แก้อะไร | `bash KIT/scripts/doctor.sh` | `KIT/scripts/doctor.sh` |

## Setup (ครั้งเดียวต่อเครื่อง)

| target | ทำอะไร | คำสั่งจริง | ไฟล์ที่ทำงานจริง |
|---|---|---|---|
| `apt` | **พิมพ์**คำสั่ง apt ให้ก๊อปไปรันเอง (ต้อง sudo) | `echo "sudo apt install -y ..."` | – |
| `clone` | โคลน repo ตาม commit ที่ล็อกไว้ ตัวที่มีอยู่แล้วข้าม | `bash KIT/scripts/clone_repos.sh KIT/repos.lock WS` | `KIT/scripts/clone_repos.sh`, `KIT/repos.lock` |
| `envs` | สร้าง conda env 2 ตัว ตัวที่มีอยู่แล้วข้าม | `bash KIT/scripts/make_envs.sh WS` | `KIT/scripts/make_envs.sh`, `KIT/envs/*.yml` |
| `sdk2` | build unitree_sdk2 แล้ว**พิมพ์**คำสั่ง sudo install ให้ | `cmake -S WS/unitree_sdk2 -B .../build -DCMAKE_INSTALL_PREFIX=/opt/unitree_robotics` → `cmake --build ...` | `WS/unitree_sdk2/CMakeLists.txt` |
| `build` | `build-sim` + `build-ctrl` | (สองแถวถัดไป) | – |
| `build-sim` | build ตัว sim | `cmake -S RL/simulate -B RL/simulate/build` → `cmake --build ...` | `RL/simulate/CMakeLists.txt` → `RL/simulate/build/unitree_mujoco` |
| `build-ctrl` | build ตัวควบคุมหุ่น | `cmake -S ROBOT -B ROBOT/build` → `cmake --build ...` | `ROBOT/CMakeLists.txt` → `ROBOT/build/g1_ctrl` |

## Training (mjlab, GPU)

| target | ทำอะไร | คำสั่งจริง | ไฟล์ที่ทำงานจริง |
|---|---|---|---|
| `tasks` | รายชื่อ task ที่ลงทะเบียนไว้ | `$(in_rl) python scripts/list_envs.py` | `RL/scripts/list_envs.py` |
| `train` | เทรน `TASK` (ค่าเริ่มต้น `Unitree-G1-23Dof-Flat`) | `$(in_rl) python scripts/train.py TASK --env.scene.num-envs=ENVS --agent.logger=tensorboard [--agent.max-iterations=ITERS]` | `RL/scripts/train.py`, task อยู่ใน `RL/src/tasks/velocity/config/g1_23dof/` |
| `play` | ดู checkpoint ใน viewer | `$(in_rl) python scripts/play.py TASK --checkpoint-file CKPT --num-envs 16 --viewer VIEWER` | `RL/scripts/play.py` |
| `tensorboard` | กราฟการเทรน http://localhost:6006 | `$(in_rl) tensorboard --logdir logs/rsl_rl` | `RL/logs/rsl_rl/` |

## Sim2sim (unitree_mujoco + g1_ctrl คุยผ่าน DDS บน lo, domain 1)

| target | ทำอะไร | คำสั่งจริง | ไฟล์ที่ทำงานจริง |
|---|---|---|---|
| `eval` | วัดการเดินตามคำสั่งความเร็วแบบไม่มีหน้าจอ พิมพ์ผลเป็น JSON | `$(in_sdk) python SCRIPTS/vel_eval.py --policy ROBOT/config/policy/velocity/POLICY/exported/policy.onnx --deploy .../params/deploy.yaml [--cases CASES]` | `SCRIPTS/vel_eval.py` |
| `sim2sim` | tmux: sim + g1_ctrl + speed monitor | `$(in_sdk) bash SCRIPTS/sim2sim_policy.sh POLICY` | `SCRIPTS/sim2sim_policy.sh` |
| `sim2sim-stop` | ปิด tmux session `sim2sim` ที่ค้างอยู่ (g1_ctrl + monitor) ถ้าไม่มี session ก็แค่บอก ไม่ error | `tmux kill-session -t sim2sim` | – |
| `gain-check` | ตรวจโฟลเดอร์ policy: kp, kd, scale, offset ใน `deploy.yaml` ตรงกับค่าที่ฝังใน `policy.onnx` ไหม และขนาด obs ตรงไหม | `$(in_sdk) python SCRIPTS/gain_check.py ROBOT/config/policy/velocity/POLICY` | `SCRIPTS/gain_check.py` |
| `sim` | เปิด sim อย่างเดียว | `cd RL/simulate/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib ./unitree_mujoco -i SIM_DOMAIN` | `RL/simulate/build/unitree_mujoco`, `RL/simulate/config.yaml` |
| `sim-band` | sim ที่มีเชือก (elastic band) สำหรับทดสอบสคริปต์ที่ขยับหุ่นเหมือนแขวนบน gantry | `bash KIT/scripts/sim_band.sh WS SIM_DOMAIN` (ทำสำเนาไว้ที่ `/tmp/g1_sim_band_<user>` แล้วเปิด `enable_elastic_band`) | `KIT/scripts/sim_band.sh` |
| `ctrl-sim` | g1_ctrl คุยกับ sim (คีย์บอร์ดใช้ได้) | `cd ROBOT/build && env -u CYCLONEDDS_URI LD_LIBRARY_PATH=... ./g1_ctrl --network lo --domain SIM_DOMAIN` | `ROBOT/build/g1_ctrl`, `ROBOT/config/config.yaml` |
| `deploy-sim` | ซ้อมวันทดสอบ: byobu 4 ช่องบน lo | `$(in_sdk) IFACE=lo bash SCRIPTS/deploy_byobu.sh RUN TAG` | `SCRIPTS/deploy_byobu.sh` |

## Real robot (ทดสอบเป็นกลุ่มเท่านั้น หุ่นแขวนบน gantry)

| target | ทำอะไร | คำสั่งจริง | ไฟล์ที่ทำงานจริง |
|---|---|---|---|
| `deploy-real` | ด่านตรวจ แล้วเปิด byobu 4 ช่องไปหุ่นจริง | `bash KIT/scripts/real_robot_guard.sh IFACE` → `$(in_sdk) IFACE=IFACE bash SCRIPTS/deploy_byobu.sh RUN TAG` | `KIT/scripts/real_robot_guard.sh` (ด่าน 4 ข้อ มีคอมเมนต์ว่าแต่ละข้อกันอะไร), `SCRIPTS/deploy_byobu.sh` |
| `health` | อ่านสถานะหุ่นอย่างเดียว ไม่ส่งคำสั่ง | `$(in_sdk) python SCRIPTS/robot_health.py --network IFACE` | `SCRIPTS/robot_health.py` |

## Checks, Docker

| target | ทำอะไร | คำสั่งจริง | ไฟล์ที่ทำงานจริง |
|---|---|---|---|
| `check` | ตรวจแบบไม่ใช้ GPU: syntax สคริปต์ (+ shellcheck ถ้ามี), กฎของ Makefile, ตารางนี้ครบ, ลิงก์ใน docs, token และ path เฉพาะเครื่อง | `bash KIT/tests/check_kit.sh` | `KIT/tests/check_kit.sh` |
| `smoke` | `check` + เทรน 3 iteration + `vel_eval` ของ v0 | `bash KIT/tests/smoke.sh` | `KIT/tests/smoke.sh` |
| `docker-build` | build image (ร่าง ยังไม่ทดสอบ) | `docker compose -f KIT/docker/compose.yaml build` | `KIT/docker/Dockerfile` |
| `docker-shell` | เข้า shell ใน container | `xhost +local:` → `docker compose -f KIT/docker/compose.yaml run --rm dev` | `KIT/docker/compose.yaml` |

## ตัวแปรที่ส่งได้

| ตัวแปร | ค่าเริ่มต้น | ใช้กับ |
|---|---|---|
| `WS` | `KIT/repos` (หรือค่าใน `local.mk`) | ทุก target |
| `TASK` | `Unitree-G1-23Dof-Flat` | `train`, `play` |
| `ENVS` | `1024` | `train` (GPU 6 GB ลดเหลือ 512 ถ้าไม่พอ) |
| `ITERS` | (ไม่จำกัด) | `train` |
| `CKPT` | (ต้องใส่) | `play` |
| `VIEWER` | `viser` | `play` (`native` = หน้าต่าง MuJoCo) |
| `POLICY` | `v0` | `eval`, `sim2sim`, `gain-check` (ชื่อโฟลเดอร์ใต้ `ROBOT/config/policy/velocity/`) |
| `CASES` | (ชุดในสคริปต์) | `eval` เช่น `"0.4,0,0;0,0,0.5"` |
| `SIM_DOMAIN` | `1` | `sim`, `sim-band`, `ctrl-sim` (`0` เฉพาะกรณี g1pilot) |
| `IFACE` | (ต้องใส่) | `deploy-real`, `health` |
| `RUN`, `TAG` | `1`, `run` | `deploy-sim`, `deploy-real` (ชื่อไฟล์ log) |
