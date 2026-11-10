# Byobu Guide: คู่มือ byobu อย่างละเอียด

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Byobu Guide.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-04

ปุ่มลัดทั้งหมดในโน้ตนี้ **เช็คจากเครื่องของผู้ดูแลจริง** (byobu 5.133, tmux 3.2a, backend tmux) ด้วย `tmux list-keys` เมื่อ 4/11/2026
ถ้าเครื่องอื่นตั้งค่าต่างกัน ให้ดูด้วย `tmux list-keys | less` ระหว่างอยู่ใน byobu

> [!WARNING]
> prefix ของเครื่องนี้คือ **F12** ไม่ใช่ `Ctrl + b`
> byobu ตั้ง `prefix F12` และ `prefix2 F12` คำแนะนำของ tmux ทั่วไปที่เขียนว่า "`Ctrl + b` แล้ว ..." ให้ใช้ **F12 แล้ว ...** แทน (3/11 ผมแนะนำ `Ctrl + b` ไปซึ่งผิด)

## สารบัญ
1. › 1. byobu คืออะไร
2. › 2. คำศัพท์: session / window / pane
3. › 3. เปิด ปิด ออก กลับเข้า (คำสั่ง shell)
4. › 4. ปุ่มลัด: pane (ช่องย่อย)
5. › 5. ปุ่มลัด: window (แท็บ)
6. › 6. ปุ่มลัด: session และอื่นๆ
7. › 7. prefix F12 + ปุ่ม (คำสั่งแบบ tmux)
8. › 8. เลื่อนดูย้อนหลังและ copy ข้อความ
9. › 9. เมาส์
10. › 10. สั่ง byobu จาก script (tmux commands)
11. › 11. deploy_byobu.sh: หน้าจอวันทดสอบหุ่น
12. › 12. กฎความปลอดภัยเวลาใช้กับหุ่นจริง
13. › 13. ปัญหาที่เจอบ่อย
14. › 14. ตารางสรุป (cheat sheet)

---

## 1. byobu คืออะไร
- **byobu = ตัวครอบ tmux** ที่ใส่ปุ่มลัด F-key และแถบสถานะให้ใช้ง่ายขึ้น ข้างในคือ tmux ทุกคำสั่ง `tmux ...` จึงใช้กับ byobu ได้
- **แบ่งหน้าจอ terminal เดียวเป็นหลายช่อง** แต่ละช่องคือ shell แยกกัน เช่น T1 lowstate, T2 lowcmd, T3 g1_ctrl, T4 คำสั่ง
- **โปรแกรมไม่ตายเมื่อปิดหน้าต่าง:** ถ้า detach (F6) หรือหน้าต่าง terminal ปิดไป โปรแกรมใน byobu ยังรันต่อ กลับเข้าไปดูได้ด้วย `byobu attach` สำคัญมากกับหุ่น: terminal ปิดแล้ว g1_ctrl ไม่ตายกลางคัน

---

## 2. คำศัพท์: session / window / pane
```
session "g1deploy"  (byobu ls เห็นชื่อนี้)
└── window 0 "deploy"  (แท็บที่แถบล่าง)
    ├── pane T1 ┐
    ├── pane T2 ├─ ช่องย่อยในหน้าจอเดียวกัน
    ├── pane T3 │
    └── pane T4 ┘
```
| คำ | คืออะไร | เทียบกับ |
|---|---|---|
| **session** | ชุดงานทั้งหมด มีชื่อ (`g1deploy`) อยู่ต่อแม้ปิด terminal | โปรเจกต์หนึ่ง |
| **window** | แท็บใน session แสดงที่แถบล่าง (`0:deploy`) | แท็บ browser |
| **pane** | ช่องย่อยใน window แต่ละช่องคือ shell หนึ่งตัว | ช่องแบ่งจอ |
| **attach / detach** | เข้า / ออกจาก session โดยไม่ปิดโปรแกรม | เปิด / พับจอ |
| **prefix** | ปุ่มนำ (F12) กดก่อนแล้วตามด้วยปุ่มคำสั่ง | – |

---

## 3. เปิด ปิด ออก กลับเข้า (คำสั่ง shell)
พิมพ์ใน terminal ปกติ (นอก byobu) หรือใน pane ไหนก็ได้

| ทำอะไร | คำสั่ง |
|---|---|
| เปิด byobu (session ใหม่ หรือเข้า session เดิม) | `byobu` |
| เปิด session ใหม่พร้อมชื่อ | `byobu new -s ชื่อ` |
| ดูว่ามี session อะไรบ้าง | `byobu ls` (= `tmux ls`) |
| กลับเข้า session | `byobu attach -t g1deploy` |
| ออกโดยโปรแกรมยังรันต่อ (detach) | **F6** (ในbyobu) หรือ `tmux detach` |
| ปิด session ทั้งชุด (**ฆ่าทุกโปรแกรมข้างใน**) | `tmux kill-session -t g1deploy` |
| ปิด pane ปัจจุบัน | พิมพ์ `exit` หรือ **Ctrl + F6** |
| ปิดทุกอย่างของ byobu/tmux | `tmux kill-server` ⚠️ |

**ข้อสังเกต**
- `kill-session` ส่งสัญญาณให้โปรแกรมทุกตัวในนั้นปิด **รวมถึง g1_ctrl** ดู › 12. กฎความปลอดภัยเวลาใช้กับหุ่นจริง
- ถ้าพิมพ์ `byobu` ทั้งที่อยู่ใน byobu แล้ว จะขึ้นเตือนเรื่อง nested session ไม่ต้องทำ

---

## 4. ปุ่มลัด: pane (ช่องย่อย)
| ปุ่ม | ทำอะไร |
|---|---|
| **Shift + ← ↑ → ↓** | **ย้ายไปช่องข้างๆ** (ใช้บ่อยสุด) |
| **Shift + F3 / Shift + F4** | วนไปช่องก่อนหน้า / ถัดไป |
| F12 แล้ว `q` แล้วกดเลข | ขึ้นเลขบนแต่ละช่อง กดเลขเพื่อไปช่องนั้น |
| F12 แล้ว `o` | ไปช่องถัดไป |
| **Shift + F11** | ขยายช่องปัจจุบันเต็มจอ / กดอีกครั้งกลับ (= F12 แล้ว `z`) |
| Ctrl + F2 | แบ่งช่องแนวตั้ง (ซ้าย / ขวา) |
| Shift + F2 | แบ่งช่องแนวนอน (บน / ล่าง) |
| Alt + Shift + ← ↑ → ↓ | ปรับขนาดช่อง |
| Ctrl + F3 / Ctrl + F4 | สลับตำแหน่งช่องกับช่องก่อนหน้า / ถัดไป |
| Shift + F8 | เปลี่ยน layout (วนรูปแบบการจัดช่อง) |
| Alt + F11 | แยกช่องปัจจุบันออกเป็น window ใหม่ |
| Alt + F9 | **พิมพ์พร้อมกันทุกช่อง** (synchronize) กดอีกครั้งปิด ⚠️ อันตรายถ้า T3 มี g1_ctrl |
| Ctrl + F6 | **ปิดช่องปัจจุบัน** (ฆ่าโปรแกรมในช่องนั้น) |

> [!NOTE]
> **Alt + ลูกศร ไม่ใช่ย้ายช่อง**
> **Alt + ← →** = เปลี่ยน **window** และ **Alt + ↑ ↓** = เปลี่ยน **session** ถ้าจะย้ายช่องให้ใช้ **Shift** + ลูกศร

---

## 5. ปุ่มลัด: window (แท็บ)
| ปุ่ม | ทำอะไร |
|---|---|
| F2 | เปิด window ใหม่ |
| F3 / F4 | window ก่อนหน้า / ถัดไป |
| Alt + ← / Alt + → | window ก่อนหน้า / ถัดไป |
| F8 | ตั้งชื่อ window |
| Ctrl + Shift + F3 / F4 | ย้ายลำดับ window |
| F12 แล้ว `w` | รายการ window ให้เลือก |
| F12 แล้ว `,` | ตั้งชื่อ window |

---

## 6. ปุ่มลัด: session และอื่นๆ
| ปุ่ม | ทำอะไร |
|---|---|
| **F6** | **detach** ออกโดยทุกอย่างรันต่อ |
| Shift + F6 | detach โดยไม่ logout (ใช้ตอน SSH) |
| Alt + F6 | ไล่ client อื่นที่ attach session เดียวกันออก |
| Ctrl + F8 | ตั้งชื่อ session |
| Alt + ↑ / Alt + ↓ | สลับ session |
| F12 แล้ว `s` | รายการ session ให้เลือก |
| Ctrl + Shift + F2 | เปิด session ใหม่ |
| F7 | โหมดเลื่อนดูย้อนหลัง / copy (› 8. เลื่อนดูย้อนหลังและ copy ข้อความ) |
| Shift + F7 | เซฟข้อความทั้งช่อง (32,768 บรรทัด) แล้วเปิดใน editor |
| F9 (หรือ F1) | เมนูตั้งค่า byobu |
| Shift + F1 | หน้าช่วยเหลือของ byobu (รายการปุ่มทั้งหมด) |
| F5 | โหลด config ใหม่ |
| Shift + F12 | **ปิด/เปิดปุ่ม F-key ทั้งหมด** ใช้ตอนโปรแกรมข้างในต้องใช้ F-key เอง (ถ้า F-key ใช้ไม่ได้ ลองกดอันนี้) |
| Alt + F12 | เปิดเมาส์ |

> [!WARNING]
> **GNOME Terminal แย่งปุ่มบางตัว**
> **F1** (help), **F10** (เมนู), **F11** (เต็มจอ) ถูก terminal ใช้ก่อน byobu อาจไม่ได้รับ ใช้ทางอื่นแทน เช่น F9 แทน F1 หรือปิดปุ่มลัดใน Preferences → Shortcuts ของ terminal

---

## 7. prefix F12 + ปุ่ม (คำสั่งแบบ tmux)
กด **F12** แล้วปล่อย จากนั้นกดปุ่มคำสั่ง (ไม่ต้องกดพร้อมกัน)

| F12 แล้ว | ทำอะไร |
|---|---|
| `q` | ขึ้นเลขช่อง กดเลขเพื่อไป |
| `o` | ช่องถัดไป |
| ↑ ↓ ← → | ย้ายช่อง |
| `z` | ขยายช่องเต็มจอ / กลับ |
| `%` | แบ่งซ้าย/ขวา |
| `c` | window ใหม่ |
| `n` / `p` | window ถัดไป / ก่อนหน้า |
| `w` | รายการ window |
| `s` | รายการ session |
| `,` | ตั้งชื่อ window |
| `[` | โหมดเลื่อน/copy (= F7) |
| `d` | detach (= F6) |
| `:` | พิมพ์คำสั่ง tmux ตรงๆ เช่น `:kill-pane` |
| `?` | รายการปุ่มทั้งหมด |
| ⚠️ `x` | **lock หน้าจอ** (ไม่ใช่ปิดช่องแบบ tmux ปกติ) ปิดช่องให้ใช้ Ctrl + F6 |

---

## 8. เลื่อนดูย้อนหลังและ copy ข้อความ
byobu เก็บประวัติ 100,000 บรรทัดต่อช่อง ใช้ **โหมด copy แบบ vi**

**เลื่อนดูย้อนหลัง**
1. กด **F7** (หรือ F12 แล้ว `[` หรือเลื่อนล้อเมาส์ขึ้นถ้าเปิดเมาส์)
2. เลื่อนด้วย ↑ ↓, PgUp / PgDn, `Ctrl + u` / `Ctrl + d` (ครึ่งหน้า), `g` (บนสุด), `G` (ล่างสุด)
3. ค้นหา: `/` คำ แล้ว Enter (ลงล่าง), `?` คำ (ขึ้นบน), `n` ตัวถัดไป
4. ออก: **`q`**

> [!NOTE]
> **ระหว่างอยู่ในโหมดนี้ ช่องนั้นพิมพ์อะไรไม่ได้**
> มุมขวาบนของช่องจะขึ้นเลขตำแหน่ง ถ้าพิมพ์แล้วไม่มีอะไรเกิดขึ้น ให้กด `q` ก่อน (โปรแกรมในช่องยังรันอยู่ ไม่ได้หยุด)

**copy ข้อความ: วิธีง่ายสุด (แนะนำ)**
- **กด Shift ค้างแล้วลากเมาส์** → Ctrl + Shift + C → วางด้วย Ctrl + Shift + V
- ข้อเสีย: ถ้าช่องอยู่ติดกัน การเลือกจะลากข้ามไปโดนช่องข้างๆ → **Shift + F11 ขยายช่องให้เต็มจอก่อน** แล้วค่อยลาก จากนั้นกด Shift + F11 อีกครั้งเพื่อกลับ

**copy ด้วยคีย์บอร์ด (ในโหมด F7)**
1. F7 → เลื่อนไปจุดเริ่ม → **Space** (เริ่มเลือก)
2. เลื่อนไปจุดจบ → **Enter** (copy แล้วออก) ข้อความอยู่ใน buffer ของ tmux
3. วางใน byobu: F12 แล้ว `]`
- buffer นี้ไม่ได้เข้า clipboard ของระบบอัตโนมัติ ถ้าจะวางนอก byobu ให้ใช้วิธี Shift + ลาก

**ไม่ต้อง copy เลย:** ถ้าจะส่งให้ Claude อ่าน บอกแค่ "ดู T4" Claude อ่านช่องได้เองด้วย `tmux capture-pane`

---

## 9. เมาส์
- byobu บนเครื่องนี้ **ปิดเมาส์เป็นค่าเริ่มต้น** (`mouse off`) แต่ `deploy_byobu.sh` **เปิดให้ใน session `g1deploy`**
- เปิดเอง: **Alt + F12** หรือ `tmux set -g mouse on`
- เมื่อเปิดเมาส์: คลิกเลือกช่อง, ลากขอบช่องปรับขนาด, เลื่อนล้อดูย้อนหลัง
- เมื่อเปิดเมาส์ การลากเลือกข้อความจะเป็นของ byobu → copy ให้ใช้ **Shift + ลาก**
- ถ้าคลิกแล้วช่องไม่เปลี่ยน (เคยเจอ 3/11) ใช้ **Shift + ลูกศร** แทน

---

## 10. สั่ง byobu จาก script (tmux commands)
ทุกอย่างทำจาก shell ได้ด้วยคำสั่ง `tmux` เป็นวิธีที่ `deploy_byobu.sh` ใช้สร้างหน้าจอ 4 ช่อง และเป็นวิธีที่ Claude ใช้อ่าน/พิมพ์ในช่อง

### 10.1 อ้างถึงช่อง (target)
| แบบ | ตัวอย่าง | ความหมาย |
|---|---|---|
| `session` | `-t g1deploy` | session |
| `session:window` | `-t g1deploy:0` | window 0 |
| `session:window.pane` | `-t g1deploy:0.2` | pane ลำดับที่ 2 (เลขเปลี่ยนตามการจัดช่อง) |
| **pane id** | `-t %4` | id ถาวรของช่อง **แนะนำใน script** (ไม่เปลี่ยนเมื่อแบ่งช่องเพิ่ม) |

ดู id และชื่อของทุกช่อง:
```bash
tmux list-panes -t g1deploy -F '#{pane_id} #{pane_title} active=#{pane_active} cmd=#{pane_current_command}'
```

### 10.2 คำสั่งที่ใช้บ่อย
```bash
# สร้าง session แบบไม่เข้า (detached) ชื่อ demo มี window ชื่อ main
byobu new-session -d -s demo -n main

# แบ่งช่อง แล้วเก็บ pane id ไว้ใช้ต่อ
P1=$(tmux display-message -p -t demo '#{pane_id}')
P2=$(tmux split-window -h -t "$P1" -P -F '#{pane_id}')     # ขวาของ P1
P3=$(tmux split-window -v -t "$P1" -P -F '#{pane_id}')     # ใต้ P1

# ตั้งชื่อช่อง และให้ชื่อขึ้นที่ขอบบน
tmux select-pane -t "$P1" -T "T1 monitor"
tmux set-option -t demo pane-border-status top
tmux set-option -t demo pane-border-format ' #{pane_title} '
tmux set-option -t demo mouse on

# พิมพ์ลงช่อง: มี Enter = รันเลย, ไม่มี Enter = พิมพ์รอไว้ให้คนกด
tmux send-keys -t "$P1" "echo hello" Enter
tmux send-keys -t "$P2" "python long_job.py"               # พิมพ์ไว้ ยังไม่รัน
tmux send-keys -t "$P2" C-c                                # = Ctrl-C ในช่องนั้น

# อ่านข้อความในช่อง (ย้อนหลัง 50 บรรทัด, -J ต่อบรรทัดที่ถูกตัด)
tmux capture-pane -p -J -t "$P1" -S -50

# เลือกช่องที่ active แล้วเข้า session
tmux select-pane -t "$P3"
byobu attach -t demo

# ปิด
tmux kill-pane -t "$P2"
tmux kill-session -t demo
```

### 10.3 แม่แบบ script ของตัวเอง
```bash
#!/usr/bin/env bash
set -euo pipefail
SESSION=mywork
if tmux has-session -t "$SESSION" 2>/dev/null; then exec byobu attach -t "$SESSION"; fi
byobu new-session -d -s "$SESSION" -n main
A=$(tmux display-message -p -t "$SESSION" '#{pane_id}')
B=$(tmux split-window -h -t "$A" -P -F '#{pane_id}')
tmux set-option -t "$SESSION" mouse on
SETUP="cd ~/nvidia/unitree/unitree_rl_mjlab && source ~/miniconda3/etc/profile.d/conda.sh && conda activate g1_sdk && S=deploy/robots/g1_23dof/scripts && clear"
for p in "$A" "$B"; do tmux send-keys -t "$p" "$SETUP" Enter; done
sleep 1
tmux send-keys -t "$A" 'python $S/robot_health.py --network enp43s0'          # พิมพ์รอไว้
tmux select-pane -t "$B"
exec byobu attach -t "$SESSION"
```

---

## 11. deploy_byobu.sh: หน้าจอวันทดสอบหุ่น
ไฟล์: `unitree_rl_mjlab/deploy/robots/g1_23dof/scripts/deploy_byobu.sh` ([00 Code Map](../03-reference/code_map.md))

### 11.1 รัน
```bash
cd ~/nvidia/unitree/unitree_rl_mjlab
IFACE=enp43s0 deploy/robots/g1_23dof/scripts/deploy_byobu.sh [RUN] [TAG]
```
| อาร์กิวเมนต์ / ตัวแปร | ค่าเริ่มต้น | ใช้ทำอะไร |
|---|---|---|
| `RUN` | `1` | เลขรอบ ใส่ในชื่อไฟล์ log |
| `TAG` | `run` | ชื่องาน เช่น `run`, `sysid`, `bm`, `chirp`, `walk` |
| `G1_CTRL_DIR=...` | `deploy/robots/g1_23dof/build` | ใช้ g1_ctrl จากที่อื่น เช่น `/tmp/g1_fixstand_train/build` |
| `IFACE=...` | `enp43s0` | interface ของหุ่น |
| `SESSION=...` | `g1deploy` | ชื่อ session |

log ที่ได้: `~/g1_state_<YYYYMMDD>_<TAG><RUN>.csv` และ `~/g1_cmd_<YYYYMMDD>_<TAG><RUN>.csv`

ตัวอย่างที่ใช้จริง:
```bash
IFACE=enp43s0 deploy/robots/g1_23dof/scripts/deploy_byobu.sh 1 sysid                                   # sysid (ไม่เปิด g1_ctrl)
IFACE=enp43s0 G1_CTRL_DIR=/tmp/g1_fixstand_train/build deploy/robots/g1_23dof/scripts/deploy_byobu.sh 1 bm   # FixStand gain เทรน
IFACE=enp43s0 deploy/robots/g1_23dof/scripts/deploy_byobu.sh 2 run                                     # g1_ctrl ตัวปกติ (Handover)
```

### 11.2 หน้าจอที่ได้
```
+--------------------------------+--------------------------------+
| T1 lowstate_monitor (read-only)| T2 lowcmd_monitor (read-only)  |
|  คำสั่งพิมพ์รอไว้ → กด Enter       |  คำสั่งพิมพ์รอไว้ → กด Enter       |
+--------------------------------+--------------------------------+
| T3 g1_ctrl (SENDS MOTOR CMDS)  | T4 checks / motion_mode / ...  |
|  คำสั่งพิมพ์รอไว้ → กด Enter       |  ช่องที่เลือกไว้ตอนเริ่ม            |
+--------------------------------+--------------------------------+
```
- ทุกช่อง `cd` เข้า repo, `conda activate g1_sdk`, `unset CYCLONEDDS_URI`, ตั้ง `RUN`, `TAG`, `D` (วันที่) ให้แล้ว
- **T1/T2/T3 คำสั่งถูกพิมพ์ไว้แต่ยังไม่รัน** ต้องกด Enter เอง (ตั้งใจออกแบบให้เช็คหุ่นก่อน)
- **T4 มีประวัติคำสั่งเตรียมไว้** กด **↑** เพื่อเรียก: `ping`, `gain_check`, `motion_mode check`, `motion_mode release`, `pd_check`
- ⚠️ **T4 ไม่มีตัวแปร `$S`** ถ้าจะใช้ `$S/...` ให้พิมพ์ `S=deploy/robots/g1_23dof/scripts` ก่อน (3/11 เจอ error `can't open file '/sysid_motion.py'`)
- ถ้า session `g1deploy` มีอยู่แล้ว script จะ **เข้า session เดิม ไม่สร้างใหม่และไม่ฆ่าของเดิม** (กัน g1_ctrl ที่คุมหุ่นอยู่ตาย)
- ถ้ามี g1_ctrl รันอยู่นอก session script จะไม่ยอมเริ่ม

### 11.3 ขั้นตอนในหน้าจอ
1. T1 Enter → T2 Enter (เริ่ม log)
2. T3 Enter (เฉพาะงานที่ใช้ g1_ctrl ห้ามกดในรอบ sysid)
3. ทำงานบนหุ่น
4. **จบรอบ: Ctrl-C ที่ T1 และ T2** เพื่อปิดไฟล์ CSV ให้สมบูรณ์
5. รอบใหม่ในหน้าจอเดิม: ในช่อง T1/T2 พิมพ์ `RUN=2` แล้วกด **↑ Enter** เรียกคำสั่ง monitor เดิม (ชื่อไฟล์จะเปลี่ยนตาม `RUN` เพราะใช้ `${RUN}`)
6. วิเคราะห์ใน T4: `python $S/pd_check.py ~/g1_state_${D}_${TAG}${RUN}.csv ~/g1_cmd_${D}_${TAG}${RUN}.csv`

### 11.4 เปลี่ยนชุดงาน (เช่น sysid → FixStand)
```bash
# 1. ให้แน่ใจว่า g1_ctrl ใน T3 อยู่ Passive (L2 + B) แล้ว Ctrl-C ที่ T3
# 2. ปิด session เดิม
tmux kill-session -t g1deploy
# 3. เปิดชุดใหม่
IFACE=enp43s0 G1_CTRL_DIR=/tmp/g1_fixstand_train/build deploy/robots/g1_23dof/scripts/deploy_byobu.sh 1 bm
```

---

## 12. กฎความปลอดภัยเวลาใช้กับหุ่นจริง
1. **ห้าม `tmux kill-session` หรือ Ctrl + F6 ที่ T3 ตอน g1_ctrl อยู่ใน FixStand หรือ Velocity** ต้องกด L2 + B ให้เข้า Passive ก่อน แล้ว Ctrl-C ที่ T3 แล้วค่อยปิด session
2. **Detach (F6) ไม่ได้หยุดอะไร** g1_ctrl ยังคุมหุ่นอยู่ อย่าเข้าใจผิดว่าปิดแล้ว
3. **ก่อนกด Enter ให้ดูชื่อช่องที่ขอบบน** โดยเฉพาะ `T3 g1_ctrl (SENDS MOTOR COMMANDS)`
4. **ห้ามเปิด Alt + F9 (พิมพ์ทุกช่องพร้อมกัน)** ระหว่างทดสอบหุ่น
5. ถ้ามีคำสั่งพิมพ์ค้างใน T3 ทั้งที่รอบนั้นไม่ใช้ g1_ctrl ให้กด **Ctrl-C ใน T3** เพื่อล้างบรรทัดทิ้ง กันเผลอกด Enter
6. Ctrl-C ใน T1/T2 ปลอดภัยเสมอ (monitor อ่านอย่างเดียว)

---

## 13. ปัญหาที่เจอบ่อย
| อาการ | สาเหตุ | แก้ |
|---|---|---|
| พิมพ์แล้วไม่ขึ้นในช่องที่ต้องการ | ช่องที่ active เป็นช่องอื่น (3/11: T1) | Shift + ลูกศร ย้ายช่อง ดูกรอบสีและชื่อช่อง |
| คลิกเลือกช่องไม่ได้ | ปิดเมาส์อยู่ หรือ terminal ไม่ส่งคลิก | Alt + F12 หรือใช้ Shift + ลูกศร |
| ช่องพิมพ์ไม่ได้ มีเลขมุมขวาบน | อยู่ในโหมดเลื่อนดู (F7 / ล้อเมาส์) | กด `q` |
| Ctrl + Shift + C ไม่ copy | byobu จับการลากเมาส์ไป | Shift + ลาก แล้วค่อย Ctrl + Shift + C |
| F-key ไม่ทำงาน | ถูกปิดด้วย Shift + F12 หรือ terminal แย่งไป | กด Shift + F12 อีกครั้ง หรือใช้ F12 + ปุ่ม |
| `Ctrl + b` แล้วไม่มีอะไรเกิด | prefix เครื่องนี้คือ F12 | ใช้ F12 |
| `can't open file '/xxx.py'` | `$S` ว่างในช่องนั้น | `S=deploy/robots/g1_23dof/scripts` |
| `Session g1deploy already exists, attaching` | มี session เดิมอยู่ | ตั้งใจ: script ไม่ฆ่าของเดิม ถ้าจะเริ่มใหม่ให้ทำตาม 11.4 |
| `no server running on /tmp/tmux-1000/default` | ยังไม่มี session ใดๆ | ปกติ เปิดใหม่ได้เลย |
| หน้าจอเพี้ยน / ตัวอักษรซ้อน | ขนาดหน้าต่างเปลี่ยน | F5 หรือ F12 แล้ว `r` / ปรับขนาดหน้าต่างใหม่ |
| terminal ปิดไปกลางคัน | – | เปิด terminal ใหม่ → `byobu attach -t g1deploy` (โปรแกรมยังรันอยู่) |

---

## 14. ตารางสรุป (cheat sheet)
| หมวด | ปุ่ม / คำสั่ง | ทำอะไร |
|---|---|---|
| เข้า/ออก | `byobu ls` · `byobu attach -t g1deploy` | ดู / กลับเข้า session |
| | **F6** | detach (รันต่อ) |
| | `tmux kill-session -t g1deploy` | ปิดทั้งชุด ⚠️ |
| ช่อง | **Shift + ลูกศร** | ย้ายช่อง |
| | Shift + F3 / F4 | วนช่อง |
| | **Shift + F11** | ขยายช่องเต็มจอ / กลับ |
| | Ctrl + F2 / Shift + F2 | แบ่งช่อง ซ้ายขวา / บนล่าง |
| | Alt + Shift + ลูกศร | ปรับขนาดช่อง |
| | Ctrl + F6 | ปิดช่อง ⚠️ |
| window | F2 · F3 / F4 · Alt + ← → | ใหม่ · ก่อน/ถัดไป |
| เลื่อน/copy | **F7** แล้ว ↑↓ PgUp `/` ค้นหา, **`q`** ออก | ดูย้อนหลัง |
| | **Shift + ลาก** → Ctrl + Shift + C | copy ไป clipboard |
| prefix | **F12** แล้ว `q` / `z` / `o` / `[` / `?` | เลขช่อง / ขยาย / ช่องถัดไป / เลื่อน / ช่วยเหลือ |
| อื่นๆ | Alt + F12 | เปิดเมาส์ |
| | Shift + F12 | ปิด/เปิด F-key |
| | Shift + F1 | ช่วยเหลือ byobu |
| script | `tmux send-keys -t %4 "cmd" Enter` | พิมพ์และรันในช่อง |
| | `tmux capture-pane -p -J -t %4 -S -50` | อ่านข้อความในช่อง |
| | `tmux list-panes -t g1deploy -F '#{pane_id} #{pane_title}'` | ดู id ของช่อง |

## ดูเพิ่ม
[Test Day Procedure](test_day_procedure.md) · [Real Robot Tools](../03-reference/real_robot_tools.md) · [Sysid Motion](sysid_motion.md) · [FixStand Train Gains](../04-explanation/fixstand_train_gains.md) · [00 Code Map](../03-reference/code_map.md)
