# Observation History

> ย้ายมาจาก vault ของผู้ดูแล (`01 Concepts/Observation History.md`) เมื่อ 10/11/2026

## คืออะไร
actor ปกติเห็นแค่ obs ของ step ปัจจุบัน (80 ตัว) **Hist5** ให้ actor เห็น 5 step ล่าสุด (400 ตัว) เพื่อให้ "รู้สึก" พลวัตได้ เช่น delay, ความเร็ว, การลื่น

- `history_length = 5`, `flatten_history_dim = True` → ต่อแต่ละ term จากเก่าไปใหม่ ตรงกับ deploy `use_gym_history: false`

## ผลที่ตามมา
| | P3b (ไม่มี history) | สาย Hist5 |
|---|---|---|
| input | 80 | 400 → **โหลด weight ของ P3b ไม่ได้ ต้องเทรนจากศูนย์** |
| เดินเร็ว (vx 1.0) | 41% | 94–95% |
| หมุน | ~70% | Hist5 30–40% → แก้ด้วย yaw_ft / yaw_stand |
| แขวนกลางอากาศ | นิ่ง | **เตะขาแรง** (ความเร็วข้อต่อ 87–131% ของ limit) |
| step แรกตอนเข้า Velocity | 0.28 rad | 1.0 rad (history ถูกเติมด้วยค่าซ้ำ, `last_action` = 0) |

**ทำไมเตะขาตอนแขวน:** history บอกว่า "ไม่มีพื้นรับ" ซึ่งไม่เคยเจอตอนเทรน → **ห้ามเข้า Velocity ตอนแขวนด้วยสาย Hist5** ตรวจ policy ใหม่ทุกตัวด้วย `vel_eval.py --hang`

## ดูเพิ่ม
[Policy Lineage](policy_lineage.md) · [Soft Start](../04-explanation/soft_start.md) · [Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md)
