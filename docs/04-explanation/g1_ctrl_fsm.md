# g1_ctrl FSM

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/g1_ctrl FSM.md`) เมื่อ 10/11/2026

`g1_ctrl` = โปรแกรม C++ ที่รัน policy บน PC แล้วส่ง [rt/lowcmd](../03-reference/lowstate_and_lowcmd.md) ไปหุ่น
โค้ด: `unitree_rl_mjlab/deploy/robots/g1_23dof/` (main.cpp, config/config.yaml, src/, include/) ส่วน `deploy/include/` ใช้ร่วมกับหุ่นทุกรุ่น **ห้ามแก้**

## แผนภาพ state
```
             (L2 + ↑)               (R2 + A)
  Passive ───────────► FixStand ───────────► Velocity (policy)
   ▲  │                    │                     │
   │  │(LB+RB 1 s + START) └──────(L2 + B)───────┤
   │  ▼                                          │
   │ Handover ──สำเร็จ──► g1_ctrl ปิดตัว, หุ่นเป็น ai (ไฟม่วง)
   │    │ล้มเหลว (L2 + B)
   └────┴─────────────────(L2 + B)───────────────┘
```
ทุก state: LowState หาย 100 ms → Passive · Velocity: เอียง > 0.85 rad → Passive

ปุ่มบนรีโมท: LT = L2, RT = R2, LB = L1, RB = R1

## แต่ละ state
| state | gain | ทำอะไร |
|---|---|---|
| **Passive** | kp 0, kd 4/4/4/6/2.5/2.5 (ขา), 4.5 (เอว), 2.5 (แขน) | หนืดอย่างเดียว คัดลอก q จริงเป็นคำสั่งทุกรอบ → เข้า FixStand แล้วเริ่มจากท่าจริงไม่กระโดด |
| **FixStand** | Unitree: ขา 100/150/40, เอว 200, แขน 40 (kd 2–10) | ไล่จากท่าปัจจุบันไป `qs` (= ท่ายืนของ policy) ใน 3 s แล้วค้าง ไม่ใช่ RL |
| **Velocity** | จาก `deploy.yaml` ([Armature and Gains](armature_and_gains.md)) | policy คุม มี [Soft Start](soft_start.md) 0.5 s ตอนเข้า |
| **Handover** | (ไม่ส่งคำสั่ง) | คืนการควบคุมให้ controller ในตัว ดู [Handover](../02-how-to/handover.md) |

## คีย์บอร์ดใน sim (`--network lo` เท่านั้น)
`u` FixStand · `v` Velocity · `p` Passive · `h` Handover · `w/s/a/d/q/e/x` ความเร็ว

## กฎ
- **ต้องเข้า debug ก่อนรัน** (`motion_mode.py release` → `name=''`) ไม่อย่างนั้นแย่งกับ controller ในตัว ([Motion Switcher](motion_switcher.md))
- **ห้ามเข้า Velocity ตอนแขวน** ด้วย policy สาย Hist5 (เตะขา) P3b นิ่ง แต่ก็ไม่จำเป็น
- รันจาก shell ที่ไม่ source ROS หรือใช้ `env -u CYCLONEDDS_URI LD_LIBRARY_PATH=/opt/unitree_robotics/lib`
- สำเนาสำหรับทดสอบ: `sim2sim_policy.sh` (policy อื่น), `fixstand_train_gains.sh` ([FixStand Train Gains](fixstand_train_gains.md)) ทั้งคู่คัดลอก binary+config ไป `/tmp` ไม่แตะของจริง

## ดูเพิ่ม
[Stop Mechanisms](stop_mechanisms.md) · [Test Day Procedure](../02-how-to/test_day_procedure.md) · ที่มา `doc/g1_23dof_summary/05_deploy_safety.md`
