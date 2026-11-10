# PD Control

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/PD Control.md`) เมื่อ 10/11/2026

## แนวคิด
มอเตอร์ทุกตัวของ G1 มี **PD controller ในตัว driver** เราไม่ได้ส่งแรงบิดโดยตรง แต่ส่ง "เป้าหมาย + ความแข็ง" แล้ว driver คำนวณแรงบิดเองที่ความถี่สูงมาก:

```
τ = kp·(q_des − q) + kd·(dq_des − dq) + τ_ff
```

| สัญลักษณ์ | ความหมาย | หน่วย |
|---|---|---|
| `q_des`, `q` | มุมเป้าหมาย / มุมจริง | rad |
| `dq_des`, `dq` | ความเร็วเป้าหมาย / จริง (ปกติ `dq_des` = 0) | rad/s |
| `kp` | stiffness: ห่างเป้า 1 rad ดึงกลับกี่ Nm | Nm/rad |
| `kd` | damping: หนืดตามความเร็ว | Nm·s/rad |
| `τ_ff` | แรงบิดป้อนตรง (feed-forward) ปกติ 0 | Nm |

**นึกภาพ:** kp คือสปริงที่ดึงข้อต่อไปหาเป้า kd คือโช้คที่หน่วงไม่ให้แกว่ง

## kp/kd อยู่ที่ไหน
- **ไม่ได้อยู่ใน firmware** เราส่ง kp/kd ไปพร้อมทุกข้อความ [rt/lowcmd](../03-reference/lowstate_and_lowcmd.md) (~500–1000 ครั้ง/วินาที) เปลี่ยนได้ทุกเมื่อ
- ค่าเก็บในไฟล์ฝั่งเรา:
  - `config.yaml` สำหรับ Passive และ FixStand ([g1_ctrl FSM](g1_ctrl_fsm.md))
  - `deploy.yaml` ของแต่ละ policy สำหรับ Velocity ([Deploy Contract](../03-reference/deploy_contract.md))
- firmware ไม่ตรวจว่าค่าสมเหตุสมผล ส่งผิด slot ก็ทำตาม → ต้องมีเครื่องมือตรวจ ([kp kd Verification](../02-how-to/kp_kd_verification.md))

| ใน firmware (เราไม่แตะ) | เราส่งเองทุกรอบ |
|---|---|
| สูตร PD + loop ความถี่สูง | kp, kd |
| แปลงข้อเท้า PR ↔ มอเตอร์ 2 ตัว | q, dq เป้าหมาย |
| จำกัดกระแส, ป้องกันความร้อน | τ_ff |
| watchdog เมื่อคำสั่งขาด | `mode` เปิด/ปิดมอเตอร์ |

## กรณีพิเศษที่ใช้บ่อย
| ชื่อ | ค่า | พฤติกรรม |
|---|---|---|
| **damping (Passive)** | kp = 0, kd > 0 | หนืด ไม่ดึงกลับที่ไหน หมุนช้าเบา หมุนเร็วหนัก |
| **zero torque** | kp = 0, kd = 0 | ปล่อยอิสระ ไม่มีแรงเลย |
| **position hold** | kp สูง | ค้างท่า สู้แรงโน้มถ่วง (ห่างเป้า ≈ แรงโน้มถ่วง / kp) |

## ทำไม kp/kd สำคัญกับ RL
policy เรียนรู้ว่า "สั่งเป้าเท่านี้ ข้อต่อจะไปถึงแค่ไหน" ภายใต้ kp/kd ชุดหนึ่ง **gain จึงเป็นส่วนหนึ่งของ policy** ต้อง deploy ด้วยชุดเดียวกับที่เทรนเท่านั้น ([Armature and Gains](armature_and_gains.md))

## ดูเพิ่ม
- [Armature and Gains](armature_and_gains.md): ที่มาของตัวเลข
- [kp kd Verification](../02-how-to/kp_kd_verification.md): วัดว่ามอเตอร์ใช้ gain ตามที่ส่งจริงไหม
- ที่มา: `doc/g1_23dof_summary/03_kp_kd.md`
