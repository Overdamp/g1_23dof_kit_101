# 3. conda env

## env คือกล่อง Python แยกห้อง
แต่ละ env มี Python และ library ของตัวเอง ติดตั้งอะไรในกล่องหนึ่งไม่กระทบอีกกล่อง
ใช้เพราะโปรแกรมแต่ละชุดต้องการเวอร์ชันที่ชนกัน เช่น mjlab ต้องการ `mujoco 3.5.0` แต่เครื่องมือหุ่นใช้ `mujoco 3.14.0`

```bash
conda env list              # มี env อะไรบ้าง (* = ตัวที่เปิดอยู่)
conda activate g1_sdk       # เข้ากล่อง (prompt จะขึ้น (g1_sdk) นำหน้า)
which python                # python ตัวนี้มาจากกล่องไหน
conda deactivate            # ออกจากกล่อง
```

## โปรเจคนี้มี 2 กล่อง
| env | Python | ใช้กับ | ของสำคัญข้างใน |
|---|---|---|---|
| `unitree_rl_mjlab` | 3.11 | เทรน, play, TensorBoard | mjlab, mujoco-warp (ฟิสิกส์บน GPU), torch, rsl-rl |
| `g1_sdk` | 3.10 | คุยกับหุ่นหรือ sim: monitor, `vel_eval`, `robot_health` | unitree_sdk2py, cyclonedds, onnxruntime |

**วิธีจำ:** เทรน = `unitree_rl_mjlab` · แตะหุ่นหรือ sim ผ่าน DDS = `g1_sdk`
ส่วน `g1_ctrl` และ `unitree_mujoco` เป็นโปรแกรม C++ ไม่ได้ใช้ conda

`make` เลือกกล่องให้เองทุก target (`in_rl`, `in_sdk` ใน [make_targets](../../03-reference/make_targets.md))

## ข้อควรระวัง
- **เปิดผิดกล่อง** ได้ error แปลกๆ เช่น `AttributeError: ... mjENBL_MULTICCD` (mujoco กับ mujoco-warp คนละรุ่น)
- **อย่าซ้อน conda กับ venv** (เช่นของ Isaac Lab) ให้ `conda deactivate` ก่อน `source .../bin/activate`
- **`pip install` ลงกล่องที่เปิดอยู่** ดู prompt ให้แน่ใจก่อนติดตั้ง

## ลองพิมพ์
```bash
conda activate unitree_rl_mjlab && python -c "import mujoco; print(mujoco.__version__)"   # 3.5.0
conda activate g1_sdk           && python -c "import mujoco; print(mujoco.__version__)"   # 3.14.0
conda deactivate
```
library ชื่อเดียวกัน คนละเวอร์ชัน อยู่คนละกล่อง

## คำถามท้ายบท
1. จะรัน `lowstate_monitor.py` ดูข้อมูลหุ่น ต้องใช้ env ไหน
2. ทำไมไม่รวมเป็น env เดียว

<details><summary>เฉลย</summary>

1. `g1_sdk` เพราะต้องคุยผ่าน DDS ด้วย unitree_sdk2py และ cyclonedds
2. เวอร์ชันของ Python และ mujoco ที่สองฝั่งต้องการชนกัน รวมกันแล้วฝั่งใดฝั่งหนึ่งจะพัง
</details>
