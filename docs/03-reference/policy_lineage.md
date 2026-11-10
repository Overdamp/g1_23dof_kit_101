# Policy Lineage

> ย้ายมาจาก vault ของผู้ดูแล (`03 Training and Sim/Policy Lineage.md`) เมื่อ 10/11/2026

```
P1 (Flat, ศูนย์) ─► P2 (+DR มวล/ข้อต่อ/มอเตอร์) ─┬► P3a (delay 0–40 ms) ✗ พัง
                                               └► P3b (delay 0–20 ms) ✓ deploy ─► Phase 4 (Rough-Blind)
Hist5 (Rough-Blind, actor 5 เฟรม, ศูนย์) ─► yaw_ft (หมุน) ─► yaw_stand (ยืนนิ่ง)
```

| ชื่อ | เริ่มจาก | เปลี่ยนอะไร | ผล | ไฟล์ |
|---|---|---|---|---|
| P1 | ศูนย์ | DR พื้นฐาน | เดินได้ | `policy_phase1_10000.onnx` |
| P2 | P1 | DR มวล/ข้อต่อ/มอเตอร์ | สั่นเมื่อ delay 20–30 ms | `policy_phase2_13000.onnx` |
| P3a | P2 | action delay 0–40 ms | ❌ เดินได้แค่ ~0.25 m/s | tag `phase3a-lag0-40ms-collapsed` |
| **P3b** | P2 | action delay 0–20 ms | ✅ **deploy รอบแรก** | `velocity/v0` (md5 `727da8a2…`) |
| Phase 4 | P3b | พื้นขรุขระ blind, reward linear ×2 | – | `run_phase4_train.sh` |
| Hist5 | ศูนย์ | actor เห็น 5 เฟรม (80 → 400) | เร็วดี หมุนแย่ | DGX `2026-10-28_04-53-15` |
| yaw_ft | Hist5 `model_14999` | reward หมุน ×2, `rel_heading_envs` 0.3 | หมุน ~78% แต่ยืนส่าย | `velocity/hist5_yawft` |
| **yaw_stand** | yaw_ft `model_17998` | `rel_standing_envs` 0.05 → 0.15 | ✅ ยืนนิ่ง, vx 0.8/1.0 ≥ 94%; ❌ เตะขาตอนแขวน | `velocity/hist5_yawstand` (`model_19497`) |

## เลือกใช้ตัวไหน
- **P3b**: deploy แรก แม่นที่ความเร็วต่ำ (vx 0.4: 97%) ยืนนิ่ง แขวนแล้วนิ่ง เลี้ยวขวาเอง ~2°/s
- **yaw_stand**: ตัวที่สอง เดินเร็วและหมุนดีกว่า แต่ **เข้า Velocity เฉพาะเท้าแตะพื้น** ([Observation History](observation_history.md))

## ทำไม P3a พัง
ยังไม่รู้สาเหตุแน่ชัด สมมติฐาน: delay สูงสุด 40 ms = 2 step ของ policy (20 ms) กว้างเกินไป policy จึงเรียนเดินช้าไว้ก่อน ลดช่วงเหลือ 0–20 ms (P3b) แล้วเดินได้ปกติ ([Domain Randomization](../04-explanation/domain_randomization.md))

## ดูเพิ่ม
[Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md) · [Training Practice](../02-how-to/training_practice.md) · [Deploy Contract](deploy_contract.md) · ที่มา `doc/g1_23dof_summary/01_training.md`
