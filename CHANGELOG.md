# Changelog

รุ่นของ kit นับแบบ `v<หลัก>.<รอง>` · เพิ่มรายการใต้ "ยังไม่ออกรุ่น" ทุกครั้งที่แก้ แล้วย้ายลงเมื่อ tag (ขั้นตอนอยู่ใน [CONTRIBUTING.md](CONTRIBUTING.md))

## ยังไม่ออกรุ่น

## v0.1 (11/11/2026)
รุ่นแรกที่ผ่านการทดสอบบนเครื่องที่ไม่ใช่ของผู้ดูแล

**repo ที่ล็อกไว้** (`repos.lock`): `unitree_rl_mjlab` `f55e2d5` · `unitree_sdk2` `63096d0` · `unitree_sdk2_python` `814556d`
**policy อ้างอิง:** `v0` = Phase 3b (`models.sha256`)

มีอะไร
- `Makefile` 28 target เป็นทางลัดของคำสั่งจริง ตารางเทียบอยู่ใน `docs/03-reference/make_targets.md`
- `make doctor` ตรวจเครื่อง: repo ตรง lock, conda env ใช้ได้จริง (เปิด DDS ได้), build ไม่เก่ากว่าซอร์ส, policy อ้างอิงตรง sha256, ค่า DDS ของ sim
- `make smoke` เทรน 3 รอบ + sim2sim แบบไม่มีหน้าจอ · `make check` ตรวจสคริปต์ กฎของ Makefile ลิงก์ใน docs และความลับ (CI รันทุก push)
- คู่มือ: พื้นฐาน 8 หน้า, tutorial Day 1–5, how-to / reference / explanation / history ที่ก๊อปมาจาก vault, `pitfalls.md`

ทดสอบแล้ว (รายละเอียดใน `tests/fresh_machine/README.md`)
- เครื่องผู้ดูแล (x86_64, Ubuntu 22.04) ด้วย user ใหม่: ถึง `make doctor` 0 FAIL
- DGX Spark (aarch64, Ubuntu 24.04): `make doctor` 0 FAIL และ sim2sim ครบ sim + g1_ctrl + speed monitor

ยังไม่ได้ทดสอบ
- ทำตามคู่มือตั้งแต่ต้นแบบผ่านรวดโดยไม่แก้ kit ระหว่างทาง และให้รุ่นน้องทำตามจริง
- Docker (`make docker-build`, `make docker-shell`) ยังเป็นร่าง
- `make deploy-real` และ `make health` กับหุ่นจริง หลังย้ายมาอยู่ใน kit (หุ่นอยู่ระหว่าง maintenance)
