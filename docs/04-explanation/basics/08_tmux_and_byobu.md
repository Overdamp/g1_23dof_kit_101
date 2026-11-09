# 8. tmux และ byobu

## ทำไมต้องใช้
โปรแกรมของโปรเจคต้องรันพร้อมกันหลายตัว (sim, g1_ctrl, monitor 2 ตัว) และ**ต้องรันต่อแม้หน้าต่าง terminal จะปิดหรือหลุด**
tmux ช่วยได้ทั้งสองเรื่อง: แบ่งหน้าจอได้หลายช่อง และเก็บโปรแกรมไว้ใน "session" ที่อยู่ต่อแม้จะปิดหน้าต่างไปแล้ว

## byobu คือเปลือกที่ครอบ tmux
```
byobu  = ปุ่มลัด F-key + แถบสถานะ
  └── tmux  = ตัวจริง (session, window, pane)
```
ทั้งคู่ใช้ server ของ tmux ตัวเดียวกัน `tmux ls` จึงเห็น session ของทั้งสองแบบ และ `tmux kill-session` ปิดได้ทั้งคู่

## ศัพท์สามคำ
| คำ | เทียบกับ | ตัวอย่างในโปรเจค |
|---|---|---|
| **session** | โต๊ะทำงานหนึ่งโต๊ะ ออกไปแล้วของบนโต๊ะยังอยู่ | `sim2sim`, `g1deploy` |
| **window** | แท็บ เห็นทีละแท็บ | `sim2sim` มี 3 window: 0 MuJoCo, 1 g1_ctrl, 2 monitor |
| **pane** | ช่องที่แบ่งในแท็บเดียว เห็นพร้อมกัน | `g1deploy` มี 4 pane: T1–T4 |

ทำไมจัดคนละแบบ: วันทดสอบต้องเห็น monitor กับ g1_ctrl **พร้อมกันตลอด** จึงใช้ pane ส่วน sim2sim มีหน้าต่าง MuJoCo แยกออกมาอยู่แล้ว ใช้ window ก็พอ

## สคริปต์ไหนใช้อะไร
| | `make sim2sim` (`sim2sim_policy.sh`) | `make deploy-sim` / `deploy-real` (`deploy_byobu.sh`) |
|---|---|---|
| เปิดด้วย | tmux | byobu |
| session | `sim2sim` | `g1deploy` |
| จัดหน้าจอ | 3 window | 4 pane ในหน้าเดียว (คลิกเมาส์ได้) |

## ปุ่มที่ใช้บ่อย
| ทำอะไร | tmux | byobu |
|---|---|---|
| ออกจาก session (โปรแกรมยังรันต่อ) | `Ctrl+b` แล้ว `d` | `F6` |
| สลับ window | `Ctrl+b` แล้วเลข `0` `1` `2` | `F3` / `F4` |
| ย้าย pane | `Ctrl+b` แล้วลูกศร | `Shift` + ลูกศร หรือคลิกเมาส์ |
| เลื่อนดูข้อความเก่า | `Ctrl+b` แล้ว `[` (ออกด้วย `q`) | `F7` |

> [!danger] ใน byobu อย่ากด `Ctrl+F6`
> `Ctrl+F6` = **ปิด pane ที่อยู่** ทันทีโดยไม่ถาม ถ้าอยู่ที่ T3 จะเท่ากับปิด g1_ctrl ตอนหุ่นจริงกำลังยืนอยู่

## คำสั่งที่ใช้ได้เสมอ ไม่ว่าจะเปิดด้วยอะไร
พิมพ์จาก terminal ปกติ (นอก session):
```bash
tmux ls                          # มี session อะไรค้างอยู่บ้าง
tmux attach -t sim2sim           # กลับเข้า session
tmux kill-session -t sim2sim     # ปิดทั้ง session และทุกโปรแกรมข้างใน
```
ถ้าจำปุ่มไม่ได้ ให้ปิดหน้าต่าง terminal ไปเลยก็ได้ session ยังอยู่ แล้วค่อย `tmux attach` กลับเข้าไปใหม่

**ลำดับการปิด `g1deploy`:** หยุด g1_ctrl ใน T3 ด้วย Ctrl-C **ก่อน** แล้วค่อย `tmux kill-session -t g1deploy`
(สคริปต์ไม่ปิดให้เอง เพราะบนหุ่นจริง g1_ctrl อาจกำลังพยุงหุ่นอยู่)

## ข้อสังเกต: ปุ่มอาจเพี้ยนถ้าเปิดสองแบบปนกัน (จากการอ่านโค้ด ยังไม่ได้ทดสอบ)
byobu โหลดชุดปุ่มของตัวเองด้วย `tmux -f <ไฟล์ของ byobu>` ซึ่ง tmux อ่านไฟล์นี้**เฉพาะตอนที่ server เริ่มทำงาน**
- ถ้าเปิด `make sim2sim` (tmux) ค้างไว้ก่อน แล้วค่อยเปิด `make deploy-sim` (byobu) ปุ่ม F-key ใน `g1deploy` อาจไม่ทำงาน
- กลับกัน ถ้าเปิด byobu ก่อน prefix ของ tmux อาจกลายเป็น `Ctrl+a` แทน `Ctrl+b`

ตรวจได้ว่าตอนนี้ปุ่มเป็นแบบไหน:
```bash
tmux show -gv prefix                         # C-b = แบบ tmux, C-a = แบบ byobu
tmux list-keys -T root | grep -c ' F6 '      # 1 = F6 ใช้ได้, 0 = ใช้ไม่ได้
```
วิธีเลี่ยงที่ง่ายที่สุด: ปิด session ที่ไม่ใช้แล้วทุกครั้ง (`make sim2sim-stop`) ก่อนเปิดอีกแบบหนึ่ง ถ้าปุ่มไม่ทำงาน ให้ใช้คำสั่งในหัวข้อก่อนหน้าแทน ซึ่งใช้ได้เสมอ

## ลองพิมพ์
```bash
tmux new -s lab                    # เปิด session ชื่อ lab
#   ในนั้นพิมพ์: top  แล้วกด Ctrl+b d
tmux ls                            # lab: 1 windows ...  (top ยังรันอยู่)
tmux attach -t lab                 # กลับเข้าไป เห็น top รันต่อ
#   กด q ออกจาก top แล้ว Ctrl+b d อีกครั้ง
tmux kill-session -t lab
tmux ls                            # ไม่มี lab แล้ว
```

## คำถามท้ายบท
1. กด `Ctrl+b d` ใน `sim2sim` แล้วเปิด `make sim2sim` ใหม่ จะเกิดอะไรขึ้น
2. ทำไม session ของวันทดสอบแบ่งเป็น pane แทนที่จะเป็น window

<details><summary>เฉลย</summary>

1. ขึ้นว่า `already running; stop it first` เพราะ `d` แค่ออกจาก session ส่วน g1_ctrl ยังรันอยู่ ต้อง `make sim2sim-stop` ก่อน
2. ต้องเห็น monitor ทั้งสองตัวกับ g1_ctrl พร้อมกันตลอด ถ้าขึ้น `MISMATCH` หรือ `STALE` ต้องเห็นทันทีโดยไม่ต้องสลับแท็บ
</details>
