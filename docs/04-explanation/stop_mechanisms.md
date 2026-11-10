# Stop Mechanisms

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Stop Mechanisms.md`) เมื่อ 10/11/2026

| กลไก | ทำงานเมื่อ | เร็วแค่ไหน | ข้อจำกัด |
|---|---|---|---|
| **L2 + B → Passive** (g1_ctrl) | ทุก state | FSM ตรวจทุก 1 ms + รอ policy thread ≤ 20 ms · sim 4/11: kp 0 ภายใน 1.3 ms (FixStand), 5.9 ms (Velocity) | Passive = kp 0 บนพื้นหุ่นทรุด → ให้เชือกรับก่อนกด |
| LowState timeout → Passive | ไม่ได้ `rt/lowstate` 100 ms | 100 ms | เน็ตขาด คำสั่ง Passive ก็ไปไม่ถึง |
| bad_orientation → Passive | Velocity, เอียง > 0.85 rad (49°) | ทันที | **ช้าเกินกันล้ม** คนต้องกดที่ ~15° |
| `sysid_motion.py` → damping | L2 + B, Ctrl-C, LowState > 50 ms, ห่างเป้า > 0.5 rad, > 70 °C, มอเตอร์หลุด, จบแผน | ทันที (sim 4/11: 0.6–0.8 ms) | ทดสอบ L2 + B บนหุ่นจริงแล้ว (30/10, 3/11) |
| Handover ล้มเหลว → damping | SelectMode ไม่ตอบ ~5 s | ~6.9 s ไม่มีคำสั่ง | ([Handover](../02-how-to/handover.md)) |
| ในโหมด ai: L2 + B ค้าง 5 s | ระหว่างเดิน | – | damping protection = ทรุด |

## หยุดทันทีเมื่อเห็น
ข้อต่อไปผิดทิศ · สั่นถี่ · เสียงเกียร์ผิดปกติ · `MISMATCH` / `STALE` / gap > 100 ms ใน monitor · มอเตอร์ > 70 °C · เอียง > ~15° · มีคนพูด "หยุด"

## ที่ยังไม่มีการป้องกัน
| เรื่อง | สถานะ |
|---|---|
| ตำแหน่งเป้าหมายไม่ถูก clip | เสนอใส่ `clip` = limit MJCF |
| controller สองตัวส่ง lowcmd | g1_ctrl แค่เตือน (เสนอให้ปิดตัว) |
| g1_ctrl crash | ยังไม่รู้อาการบนหุ่นจริง |
| lowcmd หยุดมา (สคริปต์จบ/ตาย) | ยังไม่รู้ว่ามอเตอร์คงคำสั่งสุดท้ายหรือปล่อย (sim คงไว้) จะดูในขั้น 4 ของ แผนทดสอบ (เอกสารแยกของผู้ดูแล) |

## ทดสอบปุ่มรีโมทใน sim (4/11)
เครื่องนี้ไม่มีจอยจริง (`/dev/input/js0` เป็นเมาส์จำลอง) จึงใช้ 2 วิธี:
| วิธี | ใช้กับ | ทางที่ปุ่มวิ่ง |
|---|---|---|
| จอย Xbox เสมือนผ่าน `/dev/uinput` (`vpad.py`, python-evdev) + sim `use_joystick: 1` | g1_ctrl (C++) | จอย → unitree_mujoco → `wireless_remote` → FSM เหมือนของจริงทุกขั้น |
| ตัวครอบ `fake_l2b.py` ใส่บิต L2 (byte 2, 0x20) + B (byte 3, 0x02) ใน LowState | `sysid_motion.py` | ข้ามส่วนจอย ทดสอบ `fault()` → damping |

- ตั้งแต่ 5/11: g1_ctrl มี `--domain` · sim (`simulate/config.yaml`) = domain 1 → `g1_ctrl --network lo --domain 1` · หุ่นจริง = domain 0 (ก่อนหน้านี้ `Init(0, ...)` ตายตัว)
- ลำดับปุ่ม/แกนของจอย Xbox ใน sim: ปุ่ม A B X Y LB RB back start = 0–7, แกน LX LY **LT** RX RY RT hatX hatY = 0–7 (LT กด = แกน 2 > 0, up = แกน 7 < 0)
- สคริปต์อยู่ใน scratchpad ของ session (หายเมื่อรีบูต)

## ดูเพิ่ม
[g1_ctrl FSM](g1_ctrl_fsm.md) · [Test Day Procedure](../02-how-to/test_day_procedure.md) · [Safe Shutdown](../02-how-to/safe_shutdown.md)
