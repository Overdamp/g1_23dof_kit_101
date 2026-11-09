# 7. git worktree กับ PYTHONPATH

## worktree = หลายโฟลเดอร์ หลาย branch, repo เดียว
ปกติ 1 โฟลเดอร์ = 1 branch ที่ checkout อยู่ ถ้าอยากทำงานสองเรื่องพร้อมกัน (เช่นปล่อยเทรนบันไดไว้ ขณะเดียวกันซ้อม deploy) การสลับ branch ไปมาจะทำให้ไฟล์เปลี่ยนใต้โปรแกรมที่กำลังรัน
git worktree ให้ branch ที่สองมีโฟลเดอร์ของตัวเอง โดยใช้ประวัติ git ชุดเดียวกัน

```
~/nvidia/unitree/unitree_rl_mjlab          ← phase3-delay-dr (ตัวหลัก ใช้ deploy)
~/nvidia/unitree/unitree_rl_mjlab-stairs   ← phase4-stairs   (ทดลองบันได)
```
```bash
git worktree list                                          # มีกี่โฟลเดอร์ อยู่ branch ไหน
git worktree add -b ชื่อbranch ../โฟลเดอร์ใหม่ branchต้นทาง  # สร้าง
```
commit ฝั่งไหนก็เห็นทุกฝั่งทันที ไม่ต้อง push/pull ข้ามกัน

## กับดัก: Python โหลดโค้ดจากโฟลเดอร์ไหน
`unitree_rl_mjlab` ถูกติดตั้งลง conda env แบบ **editable** (`pip install -e`) ซึ่งหมายถึง "เวลามีใคร `import src` ให้ไปเอาจากโฟลเดอร์หลัก" คำสั่งนี้ชี้ไปที่**โฟลเดอร์เดียว**

ผลคือ ยืนอยู่ใน worktree แล้วรัน `python scripts/train.py` → `import src` ไปโหลดโค้ดของ**โฟลเดอร์หลัก**
- แก้โค้ดใน worktree แล้ว**ไม่มีผล**
- task ใหม่ที่เพิ่งเพิ่ม → `invalid choice`
- แย่ที่สุด: เทรนเสร็จหลายชั่วโมงแล้วเพิ่งรู้ว่าใช้โค้ดผิดชุด

## PYTHONPATH แก้ได้
`PYTHONPATH` คือโน้ต ([หน้า 2](02_environment_variables.md)) ที่บอก Python ว่า "หาโค้ดในโฟลเดอร์นี้ก่อน" ค่านี้มาก่อนการติดตั้งแบบ editable

```bash
cd ~/nvidia/unitree/unitree_rl_mjlab-stairs
PYTHONPATH=$PWD python scripts/train.py ...      # ใช้โค้ดของ worktree นี้
```
`make` (`in_rl`) และสคริปต์ `run_*.sh` ตั้งค่านี้ให้แล้ว

## ลองพิมพ์
```bash
conda activate unitree_rl_mjlab
cd ~/nvidia/unitree/unitree_rl_mjlab-stairs
python -c "import sys; sys.path[0]='scripts'; import src; print(src.__path__)"
#   → โฟลเดอร์หลัก (แบบที่ train.py เห็น)
PYTHONPATH=$PWD python -c "import sys; sys.path[0]='scripts'; import src; print(src.__path__)"
#   → โฟลเดอร์ -stairs
```
(`sys.path[0]='scripts'` จำลองสิ่งที่เกิดเมื่อรันไฟล์ใน `scripts/`)

## คำถามท้ายบท
1. ทำไมไม่สร้างโฟลเดอร์ใหม่ด้วยการก๊อปทั้ง repo แทน worktree
2. `make doctor` ตรวจเรื่องนี้ในบรรทัดไหน

<details><summary>เฉลย</summary>

1. ก๊อปแล้วเป็น repo แยกกัน ต้อง push/pull ข้ามกันเอง และ `logs/` ขนาดหลาย GB ก็ถูกก๊อปไปด้วย worktree ใช้ `.git` ชุดเดียว
2. หมวด Conda envs บรรทัด "editable install points at ..." ถ้าชี้ไปที่อื่นที่ไม่ใช่ WS จะขึ้น WARN
</details>
