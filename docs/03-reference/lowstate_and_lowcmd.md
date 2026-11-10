# LowState and LowCmd

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/LowState and LowCmd.md`) เมื่อ 10/11/2026

topic ระดับต่ำสองตัวที่ใช้คุมหุ่น (type `unitree_hg` LowState_ / LowCmd_)

## `rt/lowstate` (หุ่น → เรา, ~1 kHz)
| ฟิลด์ | ใช้ทำอะไร |
|---|---|
| `motor_state[i].q / dq` | มุม / ความเร็วข้อต่อ (encoder) |
| `motor_state[i].tau_est` | แรงบิดประมาณจากกระแส (คลาด ±10–20%) |
| `motor_state[i].temperature[2]` | อุณหภูมิ 2 จุด |
| `motor_state[i].vol` | แรงดันที่มอเตอร์ (~52 V) **0 = มอเตอร์ไม่ตอบ** |
| `motor_state[i].motorstate` | flag error (0 = ปกติ, เคยเห็น `0x80000000`) |
| `imu_state` | quaternion, rpy, gyroscope, temperature |
| `wireless_remote` | ปุ่มรีโมท (g1_ctrl อ่านปุ่มจากตรงนี้) |
| `mode_machine`, `mode_pr`, `tick` | รุ่นหุ่น, โหมดข้อเท้า, ตัวนับ |

> [!NOTE]
> **unitree_mujoco รายงาน `vol` = 0 ทุกตัว**
> สคริปต์ของเราจึงถือว่า "vol 0 ทุกตัว = sim" และ "vol 0 บางตัว = offline"

## `rt/lowcmd` (เรา → หุ่น)
ต่อมอเตอร์: `mode` (1 = เปิด), `q`, `dq`, `kp`, `kd`, `tau` + `mode_machine` + CRC32 ทั้งข้อความ

- **ต้องมีคนส่งแค่คนเดียว** ถ้า g1_ctrl สองตัว หรือ g1_ctrl + controller ในตัวส่งพร้อมกัน → แย่งกัน หุ่นล้มได้
- g1_ctrl ตอนเริ่มเช็คว่ามีคนส่งอยู่ไหม แต่**แค่เตือน ไม่ปิดตัว** (`exit(0)` ถูก comment) → ใช้ `motion_mode.py check` / `robot_health.py` ดู lowcmd traffic ก่อน

## topic อื่น
| topic | อะไร |
|---|---|
| `rt/lf/bmsstate` | แบต: soc, soh, cycle, bmsvoltage (mV), current, temperature |
| `rt/sportmodestate` | ความเร็ว base (มีเฉพาะใน sim) |

## ดูเพิ่ม
[PD Control](../04-explanation/pd_control.md) · [Real Robot Tools](real_robot_tools.md) · [DDS and Domains](../04-explanation/dds_and_domains.md)
