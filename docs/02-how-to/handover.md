# Handover

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Handover.md`) เมื่อ 10/11/2026

## ปัญหาที่แก้
จะกลับไปบังคับด้วยรีโมท Unitree เดิมต้อง Ctrl-C g1_ctrl แล้วรัน `motion_mode.py select ai` ที่คอม → Handover ทำจากรีโมทได้เลย

## การทำงาน
```
Passive ──(L1 + R1 ค้าง 1 s แล้วกด START)──► Handover
   1. หยุดส่ง rt/lowcmd ทันที (post_run ไม่ publish)
   2. รอ 0.5 s (ไม่ให้สอง controller ส่งซ้อน)
   3. MotionSwitcherClient::SelectMode("ai")
   ├─ สำเร็จ → CheckMode (log) → g1_ctrl ปิดตัว (_Exit 0) → หุ่น zero torque (ไฟม่วง)
   └─ ล้มเหลว (ไม่ตอบใน 5 s, code 3104) → ส่ง damping ของ Passive ต่อ → L2 + B กลับ Passive
```

## ออกแบบให้ปลอดภัย
| ข้อ | เหตุผล |
|---|---|
| เข้าได้จาก **Passive เท่านั้น** | ถ้าเข้าตอนยืน (FixStand/Velocity) หุ่นจะ zero torque แล้วล้ม |
| ต้องกดค้างก่อนแล้ว START | ไม่ซ้ำปุ่ม Unitree / g1_ctrl ไม่เผลอกด |
| สำเร็จแล้ว g1_ctrl ปิดตัว | ไม่ให้รับปุ่มรีโมทซ้อนกับ controller ของ Unitree |
| ล้มเหลวกลับ damping | ไม่ปล่อยหุ่นไม่มีใครคุม |
| ⚠️ zero torque อ่อนกว่า Passive | **ทำตอนแขวนเท่านั้น** |

## ไฟล์ (เฉพาะ g1_23dof ไม่แตะไฟล์ร่วม)
- `deploy/robots/g1_23dof/include/State_Handover.h` (ใหม่)
- `config/config.yaml`: state id 4, `Passive.transitions.Handover: LB(1s) + RB(1s) + start.on_pressed`, `Handover.mode: ai`
- `main.cpp`: include + คีย์ sim `h` (เข้า) / `p` (ออก)

## ทดสอบใน sim (2/11/2026)
| กรณี | ผล |
|---|---|
| `h` ตอน FixStand | ไม่เข้า ✅ |
| `h` จาก Passive ไม่มี service | lowcmd หยุด 6.9 s → ล้มเหลว 3104 → damping ✅ |
| `h` จาก Passive มี service ปลอม | lowcmd หยุด → SelectMode 0.6 s ต่อมา → `name='ai'` → exit 0 → ไม่มี lowcmd อีก ✅ |
| `gain_check`, `fixstand_train_gains` กับ config ใหม่ | PASS ✅ |

service ปลอม: Python `unitree_sdk2py.rpc.server.Server("motion_switcher")` ตอบ api 1001/1002/1003

> [!WARNING]
> **ปุ่ม**
> **LB = L1, RB = R1** (ตัวอักษรบนรีโมท) ไม่ใช่ L2 / R2 · 3/11 กด "LB + RB" หลายรอบไม่ติด เพราะกดปุ่มที่หุ่นอ่านเป็น L2 / R2 (L2 + R2 + START ใน Passive ไม่มีผลอะไร) · ตรวจด้วยตัวอ่านปุ่มจาก `wireless_remote` (byte 2: R1 0x01, L1 0x02, start 0x04, R2 0x10, L2 0x20)

## ทดสอบบนหุ่นจริง (3/11/2026) ✅
แขวน → g1_ctrl ตัวปกติ Passive → **L1 + R1 ค้าง 1 s → START**
```
20:17:23.674  FSM: Change state from Passive to Handover
20:17:23.674  Handover: rt/lowcmd stopped, selecting motion mode 'ai' ...
20:17:27.322  Handover: SelectMode('ai') ok, CheckMode code 0 form '0' name 'ai'. g1_ctrl exits
```
- ใช้เวลา 3.6 s (เงียบ 0.5 s + SelectMode ~3.1 s; sim 0.6 s) · g1_ctrl ปิดเอง · **ไฟม่วง** · `robot_health`: `name='ai'`, 23 มอเตอร์ online
- หลังสำเร็จ rt/lowcmd กลับมา ~1 kHz เป็น kp 0 / kd 0 (zero torque) ทั้งที่ไม่มี g1_ctrl → น่าจะเป็น controller `ai` ของ Unitree เอง ดู [Network Setup](network_setup.md)
- ถ้า failed: จด code แล้วใช้ `motion_mode.py select ai` แทน

## ดูเพิ่ม
[Motion Switcher](../04-explanation/motion_switcher.md) · [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md) · [Safe Shutdown](safe_shutdown.md) · [Remote and LED](../03-reference/remote_and_led.md)
