# Soft Start

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Soft Start.md`) เมื่อ 10/11/2026

## ปัญหา
ตอนกด R2 + A เข้า Velocity, step แรกของ policy อาจสั่งเป้าห่างจากท่าที่ FixStand ค้างไว้มาก (P3b 0.28 rad, yaw_ft 1.0 rad ที่ shoulder roll) → ข้อต่อกระตุก

สาเหตุ: history ถูกเติมด้วยข้อมูลชุดเดียวกัน และ `last_action` เป็นศูนย์ ซึ่งต่างจากสถานการณ์ตอนเทรน

## วิธีแก้ (ทำแล้ว)
`deploy/robots/g1_23dof/src/State_RLBase.cpp`: **0.5 s แรก** เป้าหมายเริ่มจากท่าที่ FixStand ค้างไว้ แล้วค่อยๆ ผสมเป็นค่าของ policy
- ไม่ส่งค่าค้างจากรอบก่อน (ตรวจการเข้าโหมดใหม่จากช่วงห่างของ `run()` > 50 ms)
- ผลใน `unitree_mujoco` + elastic band: P3b 20 ms แรกขยับ ≤ 0.015 rad (เดิม 0.28)

> [!WARNING]
> **soft start ไม่แก้การเตะขาของสาย Hist5 ตอนแขวน**
> ([Observation History](../03-reference/observation_history.md))

## ดูเพิ่ม
[g1_ctrl FSM](g1_ctrl_fsm.md) · [Stop Mechanisms](stop_mechanisms.md)
