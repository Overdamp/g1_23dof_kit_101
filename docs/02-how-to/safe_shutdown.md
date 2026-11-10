# Safe Shutdown

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Safe Shutdown.md`) เมื่อ 10/11/2026

> [!CAUTION]
> **ปิดเครื่องตอนหุ่นแขวนเท่านั้น**
> 30/10/2026 ปิดที่เก้าอี้ไม่มีรอก หุ่นล้มไปข้างหน้า ([Incident Fall 2026-10-30](../05-history/incident_fall_2026-10-30.md)) และ 2/11 มอเตอร์ 25/26 หลุดตั้งแต่บูต

## ขั้นตอน (หลังใช้ g1_ctrl)
1. g1_ctrl อยู่ใน Passive (L2 + B)
2. คืนให้ ai: [Handover](handover.md) (L1 + R1 ค้าง 1 s → START) **หรือ** Ctrl-C g1_ctrl แล้ว `motion_mode.py select ai`
3. ไฟม่วง (zero torque) หุ่นยังแขวน
4. `python deploy/robots/g1_23dof/scripts/robot_health.py --network enp43s0` จดค่าแบต/อุณหภูมิท้ายวัน
5. ปิดสวิตช์

## ถ้าหุ่นยืนบนพื้นในโหมด ai
1. ปล่อย stick ให้ยืนนิ่ง
2. **ดึงรอกให้ตึงจนรับน้ำหนัก**
3. L2 + B (damping) หุ่นทิ้งตัวลงบนรอก
4. ปิดสวิตช์

## ถ้าไม่มีรอก (ไม่แนะนำ)
L2 + ← ค้าง 2 s (นั่ง) **ต้องมีคนประคอง** และวางเก้าอี้ให้ถูกที่ก่อน

## ดูเพิ่ม
[Remote and LED](../03-reference/remote_and_led.md) · [Stop Mechanisms](../04-explanation/stop_mechanisms.md) · [Motion Switcher](../04-explanation/motion_switcher.md)
