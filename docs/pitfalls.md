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
| g1pilot sim ไม่เห็นหุ่น | SDK ของ g1pilot ใช้ domain 0 ตายตัว | รัน sim ด้วย domain 0 เฉพาะกรณีนี้ (`make sim SIM_DOMAIN=0`) |
| "The other process is using the lowcmd channel" | มี g1_ctrl หรือ controller ของ Unitree ส่ง lowcmd อยู่แล้ว | ปิดตัวเก่า · บนหุ่นต้องอยู่ debug mode (L2+R2) |
| หุ่นทรุดไปข้างหน้าใน FixStand | FixStand เป็นแค่ PD ค้างท่า ไม่มีการทรงตัว | ปกติ ต้องแขวนเชือกไว้จนเข้า Velocity ดู docs/04-explanation |

## เครื่องมือ

| อาการ | สาเหตุ | แก้ |
|---|---|---|
| หน้าต่าง MuJoCo กระตุก แต่ viser ลื่น | native viewer วาดทุก env บน CPU ใน loop เดียวกับฟิสิกส์ | `VIEWER=viser` หรือ `--num-envs 1` |
| GPU memory เต็ม (6 GB) | env เยอะเกิน หรือเทรนสองงานพร้อมกัน | ลด `ENVS=` · รันทีละงาน |
