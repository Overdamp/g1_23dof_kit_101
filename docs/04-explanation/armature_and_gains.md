# Armature and Gains

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Armature and Gains.md`) เมื่อ 10/11/2026

## สูตร (BeyondMimic ผ่าน mjlab)
```
armature = ความเฉื่อยโรเตอร์ × (อัตราทดเกียร์)²
kp = armature × ω²             ω = 2π × 10 Hz
kd = 2 × ζ × armature × ω      ζ = 2
```
ไฟล์: `unitree_rl_mjlab/src/assets/robots/unitree_g1/g1_23dof_constants.py`

## ตาราง gain ที่ใช้จริง
| มอเตอร์ | ข้อต่อ | armature | kp | kd | effort (Nm) | [action scale](../03-reference/action_scale.md) |
|---|---|---|---|---|---|---|
| 7520-14 | hip pitch/yaw, waist yaw | 0.01018 | 40.18 | 2.558 | 88 | 0.548 |
| 7520-22 | hip roll, knee | 0.02510 | 99.10 | 6.309 | 139 | 0.351 |
| 5020 ×2 (linkage) | ankle pitch/roll | 0.00722 | 28.50 | 1.814 | 50 | 0.439 |
| 5020 | shoulder, elbow, wrist roll | 0.00361 | 14.25 | 0.907 | 25 | 0.439 |

ปัดเป็นตัวเลขจำง่าย: **ขา 40.2 / 99.1 / 28.5, แขน 14.3 / 0.9**

## ทำไมเป็นสูตรนี้
1. **ทุกข้อต่อตอบสนองที่ 10 Hz เท่ากัน** ไม่ว่ามอเตอร์ใหญ่หรือเล็ก (ค่าปรับมือให้ kp 100 ทั้งกลุ่มแม้มอเตอร์ต่างขนาด)
2. **ข้อต่อนุ่ม ช่วย sim2real** แรงกระแทกตอนเท้าลงเบา ไวต่อความต่าง sim/จริงน้อยลง
3. **ζ = 2 (หน่วงเกินวิกฤต)** เพราะ armature นับแค่โรเตอร์ ไม่นับมวล link ความเฉื่อยจริงสูงกว่า จึงหน่วงเผื่อ
4. ส่วนอื่นของระบบตั้งให้เข้ากับ gain ชุดนี้ (action scale, reward, DR)

**เราไม่ได้เลือกเอง** เป็นค่า default ของ unitree_rl_mjlab ตั้งแต่ commit แรก

## เทียบกับชุดอื่น
| ข้อต่อ (kp/kd) | **ของเรา** | unitree_rl_gym / rl_lab | FixStand (Unitree) |
|---|---|---|---|
| hip pitch/yaw | **40.2 / 2.56** | 100 / 2 | 100 / 2 |
| hip roll | **99.1 / 6.31** | 100 / 2 | 100 / 2 |
| knee | **99.1 / 6.31** | 150 / 4 | 150 / 4 |
| ankle | **28.5 / 1.81** | 40 / 2 | 40 / 2 |
| waist yaw | **40.2 / 2.56** | 200 / 5 (rl_lab) | 200 / 5 |
| แขน | **14.3 / 0.91** | 40 / 1 (rl_lab) | 40 / 10 |

> [!WARNING]
> **ห้ามเอา gain ชุดอื่นไปใช้กับ policy ของเรา**
> ไม่มีชุดไหน "ถูกที่สุด" แต่ policy ผูกกับชุดที่เทรน ถ้าจะเปลี่ยนต้องเทรนใหม่

## ข้อเสียที่รู้แล้ว
- ข้อต่ออ่อน ไปไม่ถึงเป้าพอดี policy เรียนสั่งเผื่อเอง
- แขน kp 14.3 ห้อยตกจากท่าเล็กน้อย (sim: ~0.05 rad ที่ไหล่) ดู [FixStand Train Gains](fixstand_train_gains.md)
- ความเฉื่อยโรเตอร์ในสูตร **ยังไม่ยืนยันกับมอเตอร์จริง** (ไม่พบเอกสาร Unitree) วัดด้วย [Sysid Motion](../02-how-to/sysid_motion.md) + `pd_check --replay`

## ผลวัดจริง
30/10/2026 FixStand (gain Unitree) `kp x` 0.89–1.09 → มอเตอร์ทำตาม gain ที่ส่ง ([Real Robot Results](../05-history/real_robot_results.md))

## ดูเพิ่ม
[PD Control](pd_control.md) · [Action Scale](../03-reference/action_scale.md) · [kp kd Verification](../02-how-to/kp_kd_verification.md) · ที่มา `doc/g1_23dof_summary/03_kp_kd.md`
