# Training Practice

> ย้ายมาจาก vault ของผู้ดูแล (`03 Training and Sim/Training Practice.md`) เมื่อ 10/11/2026

## สองแบบที่ใช้กันทั่วไป
| แบบ | ทำอย่างไร | เราใช้กับ |
|---|---|---|
| A. ขรุขระตั้งแต่ต้น + terrain curriculum | เริ่มระดับง่าย เดินได้ไกล → ยากขึ้น | Hist5 (บังคับ เพราะ input 400 โหลด P3b ไม่ได้) |
| B. เรียบก่อน แล้ว fine-tune ขรุขระ | resume checkpoint (obs ต้องขนาดเท่าเดิม) | สายหลัก P1 → P3b → Phase 4 |

- terrain 10 ระดับ (0–9) หุ่นที่ผ่านสูงสุดถูกสุ่มกลับ → ค่าเฉลี่ยตอนผ่านหมด ~4.5 ไม่ใช่ 9 (Hist5 จบ 5.3 = ผ่านเกือบครบ)
- ทุก run: `num_envs` 1024, seed 42, dt 0.005, decimation 4

## DGX (`edgexpert-cc54`, aarch64)
```bash
cd <worktree> ; git pull ; conda activate unitree_rl_mjlab
byobu new -s train                     # กัน ssh หลุด
./run_hist5_yaw_stand_finetune.sh 2>&1 | tee train.log
```
- DGX มีการแก้ ARM MuJoCo/CMake เฉพาะเครื่อง ซ่อนด้วย `.git/info/exclude` + skip-worktree (`doc/dgx_aarch64_local_git_setup.md`) **ห้าม force-checkout/restore**
- worktree ต้องตั้ง `PYTHONPATH=<worktree>` (conda env มี repo หลักแบบ editable → `import src` ไปเจอ checkout หลัก)
- resume ต้อง experiment เดียวกันและ run เดิมอยู่ใน `logs/rsl_rl/<experiment>/`
- ดูระหว่างเทรน: `Metrics/twist/error_vel_yaw`, `error_vel_xy`, `Episode_Termination/fell_over`
- รอบสุดท้ายจอค้าง: ถ้ามี `model_<last>.pt` + `policy.onnx` เวลาตรงกัน กด Ctrl-C ได้

## ทุก policy ใหม่ต้องผ่านก่อนขึ้นหุ่น
1. `gain_check.py` PASS ([Deploy Contract](../03-reference/deploy_contract.md))
2. `vel_eval.py` ความเร็ว/ยืนนิ่ง + **`--hang`** ([Sim2Sim Evaluation](../04-explanation/sim2sim_evaluation.md))
3. `sim2sim_policy.sh` กับ g1_ctrl จริง

## ดูเพิ่ม
[Policy Lineage](../03-reference/policy_lineage.md) · [Domain Randomization](../04-explanation/domain_randomization.md) · [Environments Map](../03-reference/environments_map.md)
