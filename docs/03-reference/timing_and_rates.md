# Timing and Rates

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Timing and Rates.md`) เมื่อ 10/11/2026

| อะไร | ความถี่ | หมายเหตุ |
|---|---|---|
| policy (ทุกที่) | **50 Hz** (`step_dt` 0.02 s) | sim และหุ่นจริงเท่ากัน |
| physics ตอนเทรน (mjlab) | 200 Hz (dt 0.005 s, decimation 4) | |
| `unitree_mujoco` | 500 Hz (dt 2 ms) | PD แบบ explicit → แขนสั่นใน FixStand kd 10 (ข้อจำกัด sim) |
| FSM thread ของ g1_ctrl | 1 kHz | ตรวจ transition ทุก 1 ms |
| `rt/lowstate` หุ่นจริง | **~1000–1056 Hz** | ~350 Hz ตอนเพิ่งบูต |
| `rt/lowcmd` จาก g1_ctrl | ~820–880 Hz | |
| `rt/lowcmd` จาก `sysid_motion.py` | ~530–560 Hz | Python |
| PD ใน driver มอเตอร์ | สูงกว่ามาก (ไม่ระบุ) | ทำไมหุ่นจริงไม่สั่นแบบ sim |
| delay ที่วัดได้ (คำสั่ง → แรงบิด) | ~3 ms | `pd_check` 30/10 |
| DR action delay ของ P3b | 0–20 ms | P3a (0–40 ms) พัง |

## timeout ที่ต้องรู้
- LowState หาย **100 ms** → g1_ctrl เข้า Passive ([Stop Mechanisms](../04-explanation/stop_mechanisms.md)) ค่า default ของ SDK คือ 1000 ms เราลดเหลือ 100 ms
- `sysid_motion.py` หยุดเองเมื่อ LowState ขาด > 50 ms

## ดูเพิ่ม
[Domain Randomization](../04-explanation/domain_randomization.md) (action delay) · [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md)
