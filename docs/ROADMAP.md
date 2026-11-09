# แผนพัฒนา g1_23dof_kit (สำหรับส่งต่อผู้เริ่มต้น)

เริ่ม 9/11/2026 · ผู้ดูแล: Overdamp · repo: https://github.com/Overdamp/g1_23dof_kit_101

## 1. เป้าหมาย

คนที่ไม่เคยเห็นโปรเจคนี้ โคลน repo แล้วทำตามคู่มือได้เองจนถึงจุดเหล่านี้ โดยไม่ต้องถามคนเก่า

| จุดหมาย | เวลาที่ตั้งไว้ |
|---|---|
| ติดตั้งเสร็จ `make doctor` ได้ 0 FAIL | ภายในวันแรก |
| เห็นหุ่นเดินใน sim ด้วยคีย์บอร์ด | ภายในวันแรก |
| เทรน policy เอง แล้ว export ไป sim2sim ได้ | ภายในสัปดาห์แรก |
| อธิบายได้ว่าทำไม sim กับหุ่นจริงต้องแยก domain / interface | ก่อนแตะหุ่นจริง |
| ซ้อมวันทดสอบหุ่นใน sim ครบ checklist | ก่อนแตะหุ่นจริง |

**ผู้ใช้เป้าหมาย:** นักศึกษาที่รู้ Python และ Linux เบื้องต้น ยังไม่เคยใช้ conda, make, DDS, ROS หรือ RL

## 2. หลักการออกแบบ

1. **ค่าเริ่มต้นต้องปลอดภัย** ทุกคำสั่งใช้ sim เป็นค่าเริ่มต้น หุ่นจริงต้องระบุให้ชัดและยืนยันก่อน
2. **make เป็นแค่ทางลัดที่มองทะลุได้** แต่ละ target ยาวไม่เกิน 3 บรรทัด และเรียกสคริปต์จริงใน repo ห้ามซ่อน logic ไว้ใน Makefile สคริปต์ทุกตัวต้องรันได้โดยไม่ต้องใช้ make
3. **สอนวิธีพิมพ์เองก่อน แล้วค่อยบอกทางลัด** ทุกขั้นในคู่มือแสดงคำสั่งเต็มก่อน แล้วจึงบอกว่า `make <target>` ทำสิ่งนี้แทน
4. **ทุกขั้นมีผลที่ตรวจได้** เขียนให้ชัดว่า "ต้องเห็นอะไร" ถ้าไม่เห็นให้ไปดู pitfalls ข้อไหน
5. **ล็อกเวอร์ชันทุกอย่าง** ได้แก่ `repos.lock`, `envs/*.yml` และ tag ของ Docker image จะเปลี่ยนได้ต่อเมื่อ `make smoke` ผ่าน
6. **ไม่มีความลับและข้อมูลส่วนตัวใน repo** ไม่มีรหัสผ่าน, token หรือ path ของ home ใครก็ตาม
7. **คู่มือผ่านการทดสอบจริง** ถือว่าเสร็จก็ต่อเมื่อคนใหม่ทำตามบนเครื่องเปล่าได้

## 3. สถานะปัจจุบัน (9/11/2026)

| ส่วน | สถานะ |
|---|---|
| `Makefile` (doctor, clone, envs, sdk2, build, train, play, eval, sim2sim, deploy-sim/real, smoke, docker) | ✅ ใช้ได้บนเครื่องผู้ดูแล |
| `make set-ws` + `local.mk` + ข้อความ error เมื่อหา repo ไม่เจอ | ✅ |
| `scripts/doctor.sh` | ✅ 0 FAIL / 0 WARN บนเครื่องผู้ดูแล |
| `tests/smoke.sh` | ✅ ผ่านใน 14 s |
| `repos.lock`, `envs/*.yml` | ✅ ตรงกับเครื่องผู้ดูแล ⚠️ ยังไม่ได้ทดสอบสร้างใหม่บนเครื่องเปล่า |
| `docker/` | ⚠️ ร่าง ยังไม่ได้ build |
| `docs/` | 🟡 มี README, pitfalls, Day 1 ส่วนที่เหลือเป็นโครง |

## 4. แผนงานและ checklist

สถานะ: `[ ]` ยังไม่ทำ · `[x]` เสร็จ · ใส่วันที่และชื่อคนทำหลังข้อที่เสร็จ

### Phase 0: เก็บงานที่ค้าง (½ วัน)
- [x] commit + push `set-ws`, `local.mk` ใน `.gitignore` และ README ที่แก้แล้ว (9/11/2026, Overdamp)
- [x] เพิ่ม alias `g1k='make -C ~/nvidia/unitree/g1_23dof_kit'` ในคู่มือ (เป็นตัวเลือก ไม่บังคับ) (9/11/2026, Overdamp)
- [x] เพิ่มใน `pitfalls.md`: (9/11/2026, Overdamp)
  - [x] ROS 2 ใช้ Fast DDS เป็นค่าเริ่มต้น ต้องตั้ง `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp` ไม่อย่างนั้น `CYCLONEDDS_URI` ไม่มีผล (9/11/2026, Overdamp)
  - [x] `unitree_ros2/setup.sh` เขียนชื่อการ์ดว่า `enp3s0` ต้องแก้ให้ตรงกับเครื่อง (เช่น `enp43s0`) (9/11/2026, Overdamp)
  - [x] พิมพ์ `make` ผิดโฟลเดอร์จะไปรัน Makefile ของโฟลเดอร์นั้น (เช่น `build/` ของ cmake) (9/11/2026, Overdamp)

**เสร็จเมื่อ:** `git status` สะอาด และ `make doctor` ยังได้ 0 FAIL

### Phase 1: ทำให้ make โปร่งใส (1 วัน)
- [x] คอมเมนต์หัวไฟล์ `Makefile`: ไฟล์นี้เป็นแค่ทางลัด ของจริงอยู่ใน `scripts/` และ `unitree_rl_mjlab/` ดูตารางได้ที่ `docs/03-reference/make_targets.md` (9/11/2026, Overdamp)
- [x] `docs/03-reference/make_targets.md`: ตาราง target → คำสั่งจริง → ไฟล์ต้นทาง ครบทุก target (9/11/2026, Overdamp)
- [x] สคริปต์ตรวจว่าทุก target ใน `Makefile` มีอยู่ในตาราง (ใส่ไว้ใน `make smoke` หรือ CI) (9/11/2026, Overdamp) → `make check` (`tests/check_kit.sh`) และ `make smoke` เรียก `check` ก่อน
- [x] ตรวจว่าไม่มี target ไหนยาวเกิน 3 บรรทัด ถ้ายาวกว่านั้นให้ย้ายไปเป็นสคริปต์ (9/11/2026, Overdamp) → `deploy-real` เคยมี 6 คำสั่ง ย้ายด่านตรวจไปไว้ใน `scripts/real_robot_guard.sh` แล้ว · `make check` ตรวจกฎนี้ (ไม่นับ `$(need_ws)` และบรรทัดต่อ)

**เสร็จเมื่อ:** เปิด `make_targets.md` หน้าเดียวก็ตอบได้ว่าแต่ละคำสั่งรันอะไร

### Phase 2: คำศัพท์พื้นฐานสำหรับมือใหม่ (1 วัน)
`docs/04-explanation/basics/` เขียนภาษาง่าย มีตัวอย่างให้ลองพิมพ์ ข้อละไม่เกิน 1 หน้า
- [x] terminal, path, `cd` และ "คำสั่งนี้รันจากโฟลเดอร์ไหน" (9/11/2026, Overdamp)
- [x] ตัวแปร environment: `export` / `unset` / `echo $X` (ใช้ตัวอย่าง "โน้ตแปะ terminal") (9/11/2026, Overdamp)
- [x] conda env คืออะไร ทำไมมี 2 ตัว (`unitree_rl_mjlab`, `g1_sdk`) (9/11/2026, Overdamp)
- [x] make คืออะไร และอ่าน Makefile จากที่ไหน (9/11/2026, Overdamp)
- [x] DDS, domain, interface (lo กับ enp43s0) และ `CYCLONEDDS_URI` (เมื่อไร set เมื่อไร unset) (9/11/2026, Overdamp)
- [x] ROS 2 กับ Unitree SDK ต่างกันอย่างไร, Fast DDS กับ Cyclone DDS (9/11/2026, Overdamp)
- [x] git worktree และเหตุที่ต้องตั้ง `PYTHONPATH` (9/11/2026, Overdamp)

**เสร็จเมื่อ:** มือใหม่อ่านจบแล้วตอบคำถามท้ายแต่ละหน้าได้
(เขียนครบ 7 หน้า 9/11/2026 · คำสั่ง "ลองพิมพ์" ทุกหน้ารันจริงแล้วผลตรง · ⏳ ยังรอมือใหม่ลองอ่านจริง ซึ่งจะทำพร้อม Phase 5)

### Phase 3: Tutorial ครบ 5 วัน (3–4 วัน)
ทุกหน้าใช้รูปแบบเดียวกัน: เป้าหมาย → คำสั่งเต็ม → ทางลัด make → ผลที่ต้องเห็น → ถ้าไม่เห็นให้ดูข้อไหน
- [ ] Day 1 แก้ให้แสดงคำสั่งเต็มก่อนทุกขั้น (ตอนนี้มีแต่ make)
- [ ] Day 2 เทรน: `make train` → TensorBoard → `make play` (native กับ viser ต่างกันอย่างไร)
- [ ] Day 3 export + sim2sim: export onnx + deploy.yaml → `make eval` (เกณฑ์ผ่าน) → `make sim2sim`
- [ ] Day 4 ซ้อมวันทดสอบใน sim: `make deploy-sim` ครบ checklist + การหยุดฉุกเฉิน
- [ ] Day 5 หุ่นจริง: อ้างอิง checklist วันทดสอบ, ทดสอบเป็นกลุ่ม, หุ่นแขวน, สิทธิ์ของแลป
- [ ] ภาพหน้าจอหรือ GIF ของผลที่ต้องเห็น อย่างน้อยหน้าละ 1 รูป

**เสร็จเมื่อ:** ผู้ดูแลทำตาม Day 1–4 บน user ใหม่ได้โดยไม่ต้องเปิดโน้ตส่วนตัว

### Phase 4: ย้ายความรู้จาก vault มาเป็น docs (2–3 วัน)
ตัดข้อมูลเฉพาะเครื่องออก และเปลี่ยน alias ใน bashrc ให้เป็น `make <target>`
- [ ] how-to: terminal cmd, deploy_byobu, Test Day Procedure, Stop Mechanisms
- [ ] how-to: Hi-level cmd + ros2 cmd (.164) โดยไม่ใส่รหัสผ่าน
- [ ] reference: flag ของ g1_ctrl และสคริปต์, ตาราง joint / kp / kd, Deploy Contract, DDS and Domains, Glossary
- [ ] explanation: แยก sim/หุ่นจริง, FixStand กับ gain, DR แต่ละ phase, cross-sim Isaac, บันไดโปร่ง (Phase 4 stairs)
- [ ] ตรวจด้วย `grep -rnE "/home/|password|token"` ก่อน commit ทุกครั้ง

**เสร็จเมื่อ:** คำถามที่เคยถามกันบ่อยมีคำตอบใน docs และลิงก์ถึงกันหมด

### Phase 5: ทดสอบบนเครื่องเปล่า (1–2 วัน, สำคัญที่สุด)
- [ ] สร้าง user ใหม่บนเครื่องนี้ (หรือใช้เครื่องอื่น) แล้วทำตาม README ตั้งแต่ `git clone` โดยใช้ `make clone` ไม่ใช้ `set-ws`
- [ ] จดทุกจุดที่ติด เวลาที่ใช้ และคำสั่งที่ต้องเดาเอง
- [ ] แก้ `envs/*.yml` ถ้าสร้างไม่ผ่าน (เช่น torch / CUDA ไม่ตรง)
- [ ] แก้คู่มือตามจุดที่ติดทั้งหมด แล้วทำซ้ำจนผ่านรวด
- [ ] ให้รุ่นน้อง 1 คนทำตามจริง โดยผู้ดูแลนั่งดูแต่ห้ามช่วย

**เสร็จเมื่อ:** รุ่นน้องได้ 0 FAIL และเห็นหุ่นเดินใน sim ภายในวันแรก

### Phase 6: Docker (2 วัน, ตัวเลือกเสริม)
- [ ] `make docker-build` ผ่าน (แก้ tag ของ base image / Miniforge ถ้าจำเป็น)
- [ ] ใน container: `make build && make smoke` ผ่าน
- [ ] sim2sim ใน container: หน้าต่าง MuJoCo ขึ้น (X11) และ viser เปิดได้
- [ ] DDS จาก container หา sim บน host ได้ (`network_mode: host`)
- [ ] เขียนคู่มือ "ใช้ Docker แทน conda" 1 หน้า
- [ ] ตัดสินใจว่าจะ push image ขึ้น registry หรือให้ build เอง (ขนาด, สิทธิ์)

**เสร็จเมื่อ:** เครื่องที่มีแค่ driver + Docker รัน `make smoke` ใน container ผ่าน

### Phase 7: model และไฟล์ใหญ่ (½ วัน)
- [ ] ตกลงว่า policy ตัวไหนเป็น "ตัวอ้างอิง" ที่มือใหม่ใช้ (เช่น v0 = Phase 3b)
- [ ] แนบ `.pt` / `.onnx` ไว้ใน GitHub Release พร้อม sha256
- [ ] `make models` ดาวน์โหลดและตรวจ sha256

### Phase 8: กันของพังระยะยาว (1 วัน)
- [ ] GitHub Actions (CPU): `bash -n` ทุกสคริปต์, shellcheck, `make help`, ตรวจตาราง make_targets, ตรวจลิงก์ใน docs
- [ ] ขั้นตอนการเปลี่ยน commit ใน `repos.lock`: แตก branch → `make smoke` → อัปเดต `CHANGELOG.md` → PR
- [ ] `CHANGELOG.md` และ tag เวอร์ชันของ kit (v0.1, v0.2, ...)
- [ ] `CONTRIBUTING.md`: วิธีเพิ่ม target, วิธีเพิ่ม pitfall, กฎห้ามใส่ความลับ

### Phase 9: ส่งมอบ
- [ ] ประชุมส่งมอบ 1 ชั่วโมง: demo Day 1 สด + ตอบคำถาม
- [ ] ระบุผู้ดูแลคนถัดไปใน README
- [ ] สิทธิ์ GitHub (collaborator) และสิทธิ์เครื่อง / หุ่นตามกฎแลป
- [ ] รายการงานที่ยังไม่เสร็จ ย้ายไปเป็น GitHub Issues

## 5. ความเสี่ยง

| ความเสี่ยง | ผลกระทบ | ทางลด |
|---|---|---|
| fork หรือ upstream เปลี่ยน, mjlab ออกรุ่นใหม่ | env สร้างไม่ผ่าน | ล็อก commit/เวอร์ชัน, `make smoke` ก่อนเปลี่ยน |
| GPU ของมือใหม่ไม่ใช่ NVIDIA หรือ VRAM น้อย | เทรนไม่ได้ | ระบุสเปกขั้นต่ำ, `ENVS=` ให้ลดได้, ใช้ DGX ของแลป |
| มือใหม่ใช้ make โดยไม่เข้าใจว่าข้างในทำอะไร | แก้ปัญหาเองไม่ได้ | หลักการข้อ 2–3, ตาราง make_targets, หน้า basics |
| มีคนแตะหุ่นจริงก่อนพร้อม | อันตรายต่อคนและหุ่น | `deploy-real` มีด่านกั้น, Day 5 ต้องผ่าน Day 4 ก่อน, กฎทดสอบเป็นกลุ่ม |
| ความลับหลุดเข้า repo | ต้องเปลี่ยนรหัส และประวัติ git ยังเก็บค่าเดิมไว้ | `.env`, grep ก่อน commit, ตรวจใน CI |
| ผู้ดูแลจบ แล้ว kit ไม่มีคนดูแล | ค่อยๆ ใช้ไม่ได้ | Phase 8–9, ผู้ดูแลคนถัดไป, Issues |

## 6. ลำดับที่แนะนำ

Phase 0 → 1 → 2 → 3 (Day 1–2) → **5 (ทดสอบรอบแรก)** → 3 (Day 3–5) → 4 → 5 (รอบสอง) → 7 → 8 → 6 → 9

ควรทดสอบบนเครื่องเปล่าตั้งแต่ Day 1–2 เสร็จ ไม่ต้องรอให้คู่มือครบ เพราะปัญหาการติดตั้งจะได้ไม่ไหลไปถึงหน้าหลังๆ
