# ปัญหาที่เคยเจอ (pitfalls)

รวมปัญหาจริงที่เจอระหว่างทำโปรเจค เรียงตามหมวด เจอปัญหาใหม่ให้เพิ่มที่นี่

## Environment / ติดตั้ง

| อาการ | สาเหตุ | แก้ |
|---|---|---|
| `AttributeError: ... mjENBL_MULTICCD` ตอน import mjlab | รัน python ผิด env (mujoco กับ mujoco-warp คนละรุ่น) | `conda activate unitree_rl_mjlab` หรือใช้ `make` |
| แก้โค้ดใน git worktree แล้วไม่มีผล หรือ task ใหม่ "invalid choice" | env ติดตั้ง checkout อื่นไว้แบบ editable ทำให้ `import src` ไปโหลดโฟลเดอร์นั้น | `PYTHONPATH=<worktree> python ...` (ทุก target ใน Makefile ตั้งให้แล้ว) |
| isaacsim หายจาก venv ของ Isaac Lab | เผลอรัน `uv sync` | ใน venv นั้นใช้ `uv pip install --no-deps` เท่านั้น |
| conda กับ uv venv ตีกัน (PATH / LD_LIBRARY_PATH) | เปิดทั้งสองพร้อมกัน | `conda deactivate` ก่อน `source .../bin/activate` |
| `python -I` แล้วหา cyclonedds ไม่เจอ | `-I` ตัด site ของ user ออก | ไม่ต้องใส่ `-I` กับสคริปต์ของ repo |

## DDS / sim / หุ่นจริง

| อาการ | สาเหตุ | แก้ |
|---|---|---|
| g1_ctrl ค้างที่ "Waiting for connection" ใน sim | domain ไม่ตรง (sim = 1) หรือ lo ปิด multicast | `make ctrl-sim` · `sudo ip link set lo multicast on` |
| โปรแกรม DDS เห็นแต่ interface เดียว | `CYCLONEDDS_URI` ถูก export ไว้ใน `~/.bashrc` | อย่า export ไว้ทั้งเครื่อง target ของ kit unset ให้แล้ว |
| sim กับหุ่นจริงปนกัน | ใช้ domain เดียวกัน | sim = lo + domain 1, หุ่น = enp43s0 + domain 0 บรรทัดแรกที่โปรแกรมพิมพ์ต้องเป็น `DDS: SIM` หรือ `REAL ROBOT` ตามที่ตั้งใจ |
| ROS 2 ไม่สนใจ `CYCLONEDDS_URI` (ตั้งการ์ดแล้วไม่มีผล) | ROS 2 (Foxy, Humble, Jazzy) ใช้ **Fast DDS** เป็นค่าเริ่มต้น `CYCLONEDDS_URI` มีผลเฉพาะกับ Cyclone DDS | `export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` (ต้องติดตั้ง `ros-<distro>-rmw-cyclonedds-cpp`) ให้ตรงกับ Unitree SDK ที่ใช้ Cyclone |
| ROS จากเครื่องเราไม่เห็นหุ่นหลัง `source unitree_ros2/setup.sh` | ไฟล์ของ Unitree เขียนชื่อการ์ดตายตัวว่า `enp3s0` ไม่ตรงกับการ์ดจริง (เช่น `enp43s0`) | ดูชื่อการ์ดด้วย `ip -br addr` แล้วแก้ `name="..."` ในไฟล์ |
| รัน g1_ctrl แล้ว `--network` ไม่มีผล | terminal นั้นมี `CYCLONEDDS_URI` ค้างอยู่จาก ROS (`export CYCLONEDDS_URI=...` หรือ `source unitree_ros2/setup.sh`) ค่านี้ทับ `--network` | `unset CYCLONEDDS_URI` หรือเปิด terminal ใหม่ (target ของ make unset ให้แล้ว) · terminal ROS กับ terminal Unitree แยกกัน |
| g1pilot sim ไม่เห็นหุ่น | SDK ของ g1pilot ใช้ domain 0 ตายตัว | รัน sim ด้วย domain 0 เฉพาะกรณีนี้ (`make sim SIM_DOMAIN=0`) |
| "The other process is using the lowcmd channel" | มี g1_ctrl หรือ controller ของ Unitree ส่ง lowcmd อยู่แล้ว | ปิดตัวเก่า · บนหุ่นต้องอยู่ debug mode (L2+R2) |
| หุ่นทรุดไปข้างหน้าใน FixStand | FixStand เป็นแค่ PD ค้างท่า ไม่มีการทรงตัว | ปกติ ต้องแขวนเชือกไว้จนเข้า Velocity ดู docs/04-explanation |

## เครื่องมือ

| อาการ | สาเหตุ | แก้ |
|---|---|---|
| `make: *** No rule to make target` หรือ make ทำอะไรไม่ตรงกับที่คาด | `make` อ่าน `Makefile` ในโฟลเดอร์ที่ยืนอยู่เท่านั้น ถ้าอยู่ใน `build/` จะไปรัน Makefile ของ cmake (compile ใหม่) | `cd` ไปที่โฟลเดอร์ kit หรือใช้ `make -C <โฟลเดอร์ kit> <target>` |
| `cd: .../g1_23dof_kit/repos/unitree_rl_mjlab: No such file` / "No repos at WS=" | ยังไม่ได้ `make clone` และ repo อยู่ที่อื่น | `make set-ws WS=<โฟลเดอร์ที่มี unitree_rl_mjlab>` (ทำครั้งเดียวต่อเครื่อง) |
| `g1_ctrl or unitree_mujoco is already running; stop it first.` ตอน `make sim2sim` | tmux session `sim2sim` รอบก่อนยังค้างอยู่ (`Ctrl+b d` แค่ออกจาก tmux โปรแกรมยังรันต่อ) | `make sim2sim-stop` (= `tmux kill-session -t sim2sim`) · `tmux ls` ดูว่ามี session ไหนค้าง |
| `Session g1deploy already exists, attaching` | session ของ deploy รอบก่อนยังค้างอยู่ | ถ้า g1_ctrl ใน T3 หยุดแล้ว ให้ `tmux kill-session -t g1deploy` (สคริปต์ไม่ปิดให้ เพราะบนหุ่นจริง g1_ctrl อาจกำลังพยุงหุ่น) |
| `rm: cannot remove '/tmp/g1_...': Permission denied` ตอน `make sim2sim` / `sim-band` หรือ `make smoke` ขึ้น `FAIL: training` ทั้งที่ log ที่พิมพ์ออกมาดูปกติ (เป็น log เก่าของคนอื่น) | เครื่องที่หลายคนใช้ร่วมกัน: `/tmp` ใช้ร่วมกันทุก user และโฟลเดอร์ชื่อเดียวกันเป็นของคนอื่น | สคริปต์รุ่นใหม่ใส่ชื่อ user ในชื่อโฟลเดอร์แล้ว (`/tmp/g1_sim2sim_<user>_<policy>`, `/tmp/kit_smoke_<user>/`) · ถ้ายังเจอ ให้ตรวจว่า `repos.lock` ล็อก commit ใหม่แล้ว |
| `make envs`: `CondaToSNonInteractiveError: Terms of Service have not been accepted` | Miniconda รุ่นใหม่ตั้ง channel `defaults` ของ Anaconda ไว้ ซึ่งต้องกดยอมรับ ToS ก่อน (`nodefaults` ใน yml ไม่พอสำหรับ conda 26) | `scripts/make_envs.sh` ให้ `defaults` ชี้ไป conda-forge เฉพาะตอนสร้าง env แล้ว · ถ้าเจออีก: `git pull` ใน kit แล้ว `make envs` ใหม่ |
| `ModuleNotFoundError: No module named 'scipy'` (ตอน train) หรือ `'onnx'` (ตอน `gain-check`) | env เก่าที่สร้างก่อน `envs/*.yml` จะมีสองตัวนี้ (mjlab ใช้ scipy แต่ไม่ได้ประกาศไว้) · `make envs` ข้าม env ที่มีอยู่แล้ว | `conda run -n unitree_rl_mjlab pip install scipy==1.17.1` และ `conda run -n g1_sdk pip install onnx==1.23.2` |
| เครื่อง aarch64 (DGX Spark, Jetson): `make doctor` ขึ้น `env g1_sdk: ImportError: libddsc.so.11: cannot open shared object file` | ไม่มี wheel สำเร็จรูปของ `cyclonedds` 0.10.2 สำหรับ aarch64 pip จึง build เองหรือหยิบ wheel เก่าจาก cache ที่ลิงก์กับ Cyclone C รุ่นอื่น | 1) build Cyclone C ลง home: `git clone https://github.com/eclipse-cyclonedds/cyclonedds -b releases/0.10.x ~/cyclonedds` แล้ว `cmake -S ~/cyclonedds -B ~/cyclonedds/build -DCMAKE_INSTALL_PREFIX=$HOME/cyclonedds/install -DBUILD_EXAMPLES=OFF && cmake --build ~/cyclonedds/build --target install -j` · 2) `CYCLONEDDS_HOME=~/cyclonedds/install LDFLAGS="-Wl,-rpath,$HOME/cyclonedds/install/lib" conda run -n g1_sdk pip install --force-reinstall --no-deps --no-cache-dir --no-binary cyclonedds cyclonedds==0.10.2` · 3) ทำแถวถัดไปด้วย |
| เครื่อง aarch64: เครื่องมือ Python (speed monitor, lowstate monitor, health) ตายด้วย `*** buffer overflow detected ***: terminated` · บางทีใช้ได้ใน terminal หนึ่งแต่พังในอีก terminal | package `cyclonedds` เลือก `libddsc` ตอนรันเอง: ถ้าไม่มีตัวแปร `CYCLONEDDS_HOME` จะไปหยิบของ apt (`/lib/aarch64-linux-gnu/libddsc.so.0debian`) ซึ่งพังตอนเขียน log ที่ `unitree_sdk2py` เปิดไว้ · terminal ที่เคย `export CYCLONEDDS_HOME` จึงใช้ได้ | ตั้งถาวรใน env: `conda env config vars set -n g1_sdk CYCLONEDDS_HOME=$HOME/cyclonedds/install` · ถ้ามี tmux เปิดค้างให้ `tmux kill-server` ก่อน (pane ใหม่ใช้ตัวแปรของ server เดิม) · ไม่ต้องแก้ไฟล์ของ Unitree |
| `make build`: `'basic_runtime' is not a member of 'fmt'` (ใน `/usr/include/spdlog`) | CMake หา lib จากทุกโฟลเดอร์ใน PATH และ Miniconda รุ่นใหม่มี `yaml-cpp` + `fmt` ติดมา ทำให้ header ของ conda บังของระบบ | `make build-sim` / `build-ctrl` สั่ง CMake ไม่ให้หาใน conda แล้ว (`NO_CONDA_FIND`) และล้างค่าเก่าที่จำไว้ · ถ้ายังเจอ: `rm -rf <โฟลเดอร์>/build` แล้ว build ใหม่ |
| `make build-ctrl`: `fatal error: unitree/dds_wrapper/robots/go2/go2.h: No such file` | CMakeLists ของ g1_ctrl ไม่ได้บอกว่า sdk2 อยู่ที่ไหน (เครื่องที่ build ได้คือเครื่องที่เคยพิมพ์ flag เองแล้ว CMake จำไว้) | `make build-ctrl` ส่ง `-I$(SDK2_PREFIX)/include` ให้แล้ว · ถ้า sdk2 ไม่ได้อยู่ที่ `/opt/unitree_robotics` ใส่ `SDK2_PREFIX=...` |
| `make doctor`: `docker daemon not reachable as <user>` | user ไม่ได้อยู่กลุ่ม `docker` | ไม่ต้องใช้ Docker ก็ข้ามได้ · ถ้าต้องใช้: ผู้ดูแล `sudo usermod -aG docker <user>` แล้ว logout/login |
| หน้าต่าง MuJoCo กระตุก แต่ viser ลื่น | native viewer วาดทุก env บน CPU ใน loop เดียวกับฟิสิกส์ | `VIEWER=viser` หรือ `--num-envs 1` |
| GPU memory เต็ม (6 GB) | env เยอะเกิน หรือเทรนสองงานพร้อมกัน | ลด `ENVS=` · รันทีละงาน |
