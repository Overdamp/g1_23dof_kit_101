# วิธีแก้ kit นี้

อ่านหน้านี้ก่อนแก้อะไรใน repo กฎมีน้อย และ `make check` ตรวจให้เกือบทั้งหมด

## ก่อน commit ทุกครั้ง
```bash
make check        # ไม่ต้องมี GPU: สคริปต์, กฎของ Makefile, ตาราง make_targets, ลิงก์ใน docs, ความลับ
```
ถ้าแก้อะไรที่กระทบการเทรนหรือ sim2sim (สคริปต์, `envs/`, `repos.lock`) รัน `make smoke` ด้วย
GitHub Actions รัน `make check` ซ้ำทุก push และทุก pull request (`.github/workflows/check.yml`)

เพิ่มหนึ่งบรรทัดใต้ "ยังไม่ออกรุ่น" ใน [CHANGELOG.md](CHANGELOG.md) ว่าแก้อะไร

## ห้ามใส่ความลับ
- ห้ามมีรหัสผ่าน token หรือ key ในไฟล์ใดๆ รวมถึงใน docs และตัวอย่างคำสั่ง ถ้าโปรแกรมต้องใช้ ให้อ่านจาก `.env` (อยู่ใน `.gitignore`)
- ห้ามใส่ path ที่มีเฉพาะบนเครื่องของใครคนหนึ่ง (เช่น home ของตัวเอง) ใช้ `WS`, `KIT` หรือ `~`
- `make check` จับ token ที่มีรูปแบบชัด (GitHub, AWS, private key) แต่**จับรหัสผ่านธรรมดาไม่ได้** ต้องอ่าน diff เองก่อน commit
- ถ้าหลุดขึ้น GitHub ไปแล้ว: เปลี่ยนรหัสหรือยกเลิก token นั้นทันที การลบ commit ไม่พอ

## เพิ่ม make target
1. เขียน target ใน `Makefile` พร้อม `## คำอธิบาย` ท้ายบรรทัดชื่อ (`make help` อ่านจากตรงนี้)
2. target หนึ่งมีได้ไม่เกิน 3 คำสั่ง ถ้ายาวกว่านั้นให้เขียนเป็นสคริปต์ใน `scripts/` แล้วให้ target เรียก
3. เพิ่มแถวใน [docs/03-reference/make_targets.md](docs/03-reference/make_targets.md): target, ทำอะไร, คำสั่งจริง, ไฟล์ต้นทาง
4. `make check` จะ FAIL ถ้าขาดข้อ 1–3

หลักคือ make เป็นแค่ทางลัด คนที่ไม่ใช้ make ต้องก๊อปคำสั่งจริงจากตารางไปรันเองได้

## เพิ่มสคริปต์
- ขึ้นต้นด้วย `set -euo pipefail` และคอมเมนต์หัวไฟล์ว่าทำอะไร ใช้อย่างไร
- ไฟล์ชั่วคราวใน `/tmp` ต้องมีชื่อ user ในชื่อโฟลเดอร์ (เช่น `/tmp/kit_smoke_$USER`) เพราะ `/tmp` ใช้ร่วมกันทุกบัญชีในเครื่อง
- ต้องผ่าน `shellcheck -S warning` (CI ตรวจ · ในเครื่อง: `sudo apt install shellcheck`)

## เพิ่มปัญหาที่เจอ (pitfall)
เจอปัญหาที่เสียเวลาเกิน 15 นาที ให้เพิ่มแถวใน [docs/pitfalls.md](docs/pitfalls.md) ใต้หมวดที่ตรง:
`| อาการ (ข้อความ error ตามที่เห็นจริง) | สาเหตุ | แก้ |`
ใส่ข้อความ error ตรงตัว เพราะคนถัดไปจะค้นด้วยข้อความนั้น ถ้าตรวจอัตโนมัติได้ ให้เพิ่มการตรวจใน `scripts/doctor.sh` ด้วย

## เพิ่มหรือแก้หน้าเอกสาร
- เลือกโฟลเดอร์ตามชนิด: `01-tutorials` (ทำตามทีละขั้น), `02-how-to` (ขั้นตอนของงานหนึ่ง), `03-reference` (ตาราง ค่า flag), `04-explanation` (เหตุผล), `05-history` (เหตุการณ์)
- ลิงก์ระหว่างหน้าใช้ path แบบ relative · `make check` ตรวจว่าปลายทางมีอยู่จริง
- tutorial ต้องแสดง**คำสั่งเต็ม**ก่อน แล้วค่อยบอกทางลัด `make`

## เปลี่ยน commit ใน `repos.lock`
`repos.lock` คือชุด commit ที่ทดสอบแล้วว่าใช้ด้วยกันได้ เปลี่ยนตามลำดับนี้
1. แตก branch ใน kit: `git checkout -b bump-<repo>-<commit สั้น>`
2. checkout commit ใหม่ใน `WS/<repo>` แล้ว build ใหม่: `make build` (binary เก่าไม่รู้จัก option ใหม่ `make doctor` เตือนเรื่องนี้)
3. `make doctor` ต้อง 0 FAIL และ `make smoke` ต้อง PASS ทั้งสองข้อ
4. แก้ commit ใน `repos.lock` และในตัวอย่างคำสั่งของ `docs/01-tutorials/day1_setup_and_sim.md` ข้อ 3
5. ถ้า policy `v0` เปลี่ยน อัปเดต `models.sha256` (วิธีอยู่ในหัวไฟล์นั้น) และบอกเหตุผลใน CHANGELOG
6. เพิ่มบรรทัดใน CHANGELOG แล้วเปิด pull request ให้ CI ผ่านก่อน merge

## ออกรุ่น (tag)
ออกรุ่นเมื่อ `repos.lock` เปลี่ยน หรือมีการแก้ที่คนใช้ต้องรู้
1. ย้ายรายการใต้ "ยังไม่ออกรุ่น" ใน CHANGELOG ไปไว้ใต้หัวข้อรุ่นใหม่ พร้อมวันที่และ commit ใน `repos.lock`
2. `git tag v0.2 && git push origin v0.2`

## สิ่งที่ไม่ควรทำ
- อย่าแก้ไฟล์ใน `WS/unitree_sdk2*` (เป็น repo ของ Unitree) ถ้าจำเป็นจริง ให้จดเหตุผลใน `pitfalls.md`
- อย่าให้ `make` ทำงานที่ต้องใช้ `sudo` เอง ให้พิมพ์คำสั่งออกมาให้คนรันเอง (แบบ `make apt` และ `make sdk2`)
- อย่าเพิ่มทางลัดไปหาหุ่นจริงที่ข้าม `scripts/real_robot_guard.sh`
