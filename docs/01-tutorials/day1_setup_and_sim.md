# Day 1: ติดตั้ง และเห็นหุ่นเดินใน sim

> ยังไม่เคยใช้ terminal, conda, make หรือ DDS: อ่าน [พื้นฐาน 7 หน้า](../04-explanation/basics/README.md) ก่อน

**เป้าหมาย:** จบวันนี้ `make doctor` ได้ 0 FAIL และบังคับหุ่นเดินใน unitree_mujoco ด้วยคีย์บอร์ดได้

## 1. ติดตั้ง
ทำตาม Quickstart ใน [README](../../README.md) ตั้งแต่ `make apt` ถึง `make build`

**ผลที่ต้องเห็น:** `make doctor` บรรทัดสุดท้ายเป็น `0 FAIL` (WARN มีได้ ถ้าอ่านแล้วเข้าใจว่าทำไม)

## 2. ทดสอบเร็ว
```bash
make smoke
```
**ผลที่ต้องเห็น:** `PASS` สองครั้ง ใช้เวลาไม่ถึง 1 นาทีบนเครื่องที่ติดตั้งแล้ว

## 3. Sim2sim ด้วยตา
```bash
make sim2sim POLICY=v0
```
จะได้ tmux 3 หน้าต่าง: 0 = MuJoCo, 1 = g1_ctrl (พิมพ์คีย์ที่นี่), 2 = speed monitor

1. ในหน้าต่าง MuJoCo: กด Pause → Load key 0 (stand_ready)
2. ในหน้าต่าง 1: กด `u` (FixStand) แล้ว `v` (Velocity)
3. กลับไป MuJoCo กด Run
4. ในหน้าต่าง 1: `w/s` เดินหน้า/ถอย, `a/d` ซ้าย/ขวา, `q/e` หมุน, `x` หยุด

**ผลที่ต้องเห็น:** บรรทัดแรกของ g1_ctrl เป็น `DDS: domain 1 on lo (SIM, keyboard on)` และหุ่นเดินตามคีย์

## 4. ทำความเข้าใจ (อ่านก่อนวันที่ 2)
- ทำไม sim ใช้ domain 1 แต่หุ่นใช้ 0: [basics/05](../04-explanation/basics/05_dds_domain_interface.md)
- โครงของ FSM: Passive → FixStand → Velocity: docs/04-explanation (ยังไม่เขียน)
