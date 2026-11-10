# Observations

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Observations.md`) เมื่อ 10/11/2026

policy ทุกตัวเป็น **blind** ไม่ใช้กล้องหรือ lidar ข้อมูลทั้งหมดมาจาก [rt/lowstate](lowstate_and_lowcmd.md) + จอย

| term | มิติ | มาจาก | หมายเหตุ |
|---|---|---|---|
| `base_ang_vel` | 3 | gyro ของ IMU (ในเชิงกราน) | noise ตอนเทรน ±0.2 rad/s |
| `projected_gravity` | 3 | quaternion ของ IMU | ยืนตรง ≈ (0, 0, −1) |
| `velocity_commands` | 3 | จอย (vx, vy, wz) | sim ใช้คีย์บอร์ด |
| `gait_phase` | 2 | นาฬิกาใน g1_ctrl (sin, cos) | รอบ 0.6 s, **เป็น 0 เมื่อ \|cmd\| < 0.1** |
| `joint_pos_rel` | 23 | encoder − `default_joint_pos` | noise ±0.01 rad |
| `joint_vel_rel` | 23 | encoder | noise ±1.5 rad/s |
| `last_action` | 23 | action รอบก่อน | |
| **รวม** | **80** | | Hist5 = 80 × 5 = 400 |

## ข้อควรรู้
- `encoder_bias` DR ตอนเทรน ±0.015 rad → policy ทนค่าศูนย์คลาดได้ประมาณนี้ ถ้าคลาดมากกว่า ~0.03 rad ควรสงสัย ([Offset Check](../02-how-to/offset_check.md))
- ทิศของ IMU: pitch+ ↔ gyro y+ ↔ projected gravity x+; roll+ ↔ gyro x+ ↔ projected gravity y− (ตรวจกับหุ่นจริง 28/10)
- `Unitree-G1-23Dof-Rough` (ไม่มีคำว่า Blind) ใช้ `height_scan` → deploy กับ g1_ctrl ไม่ได้
- lidar ใช้ทีหลังในระดับนำทาง: g1pilot ส่ง vx, vy, wz แทนจอย

## ดูเพิ่ม
[Observation History](observation_history.md) · [Deploy Contract](deploy_contract.md) · [Domain Randomization](../04-explanation/domain_randomization.md)
