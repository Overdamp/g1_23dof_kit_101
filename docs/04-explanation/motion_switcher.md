# Motion Switcher

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Motion Switcher.md`) เมื่อ 10/11/2026

บริการ `motion_switcher` ในหุ่นเลือกว่า **ใครคุมมอเตอร์** อ่าน/เปลี่ยนผ่าน RPC (`MotionSwitcherClient`)

```
           ┌──────────────── หุ่น G1 ─────────────────┐
 รีโมท ──► │  motion_switcher                          │
           │   ├─ name='ai' → controller ในตัว Unitree │ ──► มอเตอร์
           │   └─ name=''   → ไม่มีใครคุม (debug)      │ ◄── rt/lowcmd จาก PC
           └──────────────────────────────────────────┘
```

| | **`ai`** | **debug / development / released** |
|---|---|---|
| `motion_mode.py check` | `form='0' name='ai'` | `name=''` |
| ใครคุม | controller เดิน/ยืนของ Unitree | โปรแกรมเรา (g1_ctrl, sysid) |
| ปุ่มรีโมท | ปุ่ม Unitree ทั้งหมด ([Remote and LED](../03-reference/remote_and_led.md)) | เฉพาะปุ่มที่ g1_ctrl อ่าน |
| ไฟหัว | หลัง select ใหม่: ม่วง (zero torque) | เหลือง |
| เข้าอย่างไร | **ค่าเริ่มต้นตอนเปิดเครื่อง** · `select ai` · [Handover](../02-how-to/handover.md) | `motion_mode.py release` |

## สิ่งที่พิสูจน์แล้ว (2/11/2026)
- เปิดเครื่องโดยไม่กดอะไร → `name='ai'` ⇒ **ai คือโหมดเริ่มต้น ไม่ใช่ debug**
- กด L2 + B → L2 + R2 หุ่นพูดว่า "development mode" แต่ยังอ่านได้ `ai` (เหมือน 30/10) ⇒ **L2 + R2 ไม่ปลด motion_switcher**
  - สมมติฐาน (ยังไม่ยืนยัน): L2 + R2 ทำให้ ai หยุดสั่งมอเตอร์แต่ยังลงทะเบียนอยู่
- `motion_mode.py release` → `name=''` แล้ว g1_ctrl คุมได้ปกติ (30/10)
- `select ai` → ไฟม่วง (30/10)

> [!IMPORTANT]
> **กฎของเรา**
> ก่อนรัน g1_ctrl หรือ sysid ต้องได้ **`name=''` เท่านั้น** ใช้ `motion_mode.py release` ไม่พึ่ง L2 + R2
> `sysid_motion.py` ปฏิเสธเริ่มบนหุ่นจริงถ้า name ไม่ว่าง

## คำสั่ง
```bash
python deploy/robots/g1_23dof/scripts/motion_mode.py --network enp43s0 check        # อ่านอย่างเดียว
python deploy/robots/g1_23dof/scripts/motion_mode.py --network enp43s0 release      # → debug (หุ่นต้องแขวน)
python deploy/robots/g1_23dof/scripts/motion_mode.py --network enp43s0 select ai    # → ai (ปฏิเสธถ้ายังมี lowcmd)
```

## API อื่นในโหมด ai (ยังไม่ได้ทดสอบ)
`LocoClient`: `GetFsmId/GetFsmMode` (อ่าน), `Damp`, `ZeroTorque`, `Start`, `Sit`, `Move(vx,vy,vyaw)` … หลายตัวทำให้หุ่นขยับ

## ดูเพิ่ม
[g1_ctrl FSM](g1_ctrl_fsm.md) · [Handover](../02-how-to/handover.md) · [Remote and LED](../03-reference/remote_and_led.md)
