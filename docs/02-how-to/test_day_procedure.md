# Test Day Procedure

> ย้ายมาจาก vault ของผู้ดูแล (`02 Real Robot/Test Day Procedure.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-03

ลำดับที่ใช้ตั้งแต่ 3/11/2026 (ปรับจากบทเรียน 30/10 และ 2/11) ใบพิมพ์: `unitree_rl_mjlab/doc/print/g1_23dof_test_day_20261103.pdf`
checklist เต็ม: `doc/g1_23dof_real_robot_setup_checklist.md`
คำสั่งพร้อมคัดลอก: [terminal cmd](terminal_cmd.md)

> [!CAUTION]
> **กฎเหล็ก**
> - หุ่น**แขวนรอกตลอด** ตั้งแต่เปิดจนปิด (ยกเว้นขั้นยืนบนพื้นที่วางแผนไว้ และต้องมี 2 คน)
> - **ไม่กด L2 + A** · เข้า debug ด้วย `motion_mode.py release` ไม่ใช้ L2 + R2
> - หยุดทันทีด้วย **L2 + B** เมื่อผิดทิศ / สั่นถี่ / เสียงแปลก / มอเตอร์ > 70 °C / มีคนพูด "หยุด"
> - ทำข้อถัดไปเมื่อข้อก่อนผ่านเท่านั้น

```bash
cd ~/nvidia/unitree/unitree_rl_mjlab ; conda activate g1_sdk ; S=deploy/robots/g1_23dof/scripts
```

| # | ขั้น | คำสั่ง | ผ่านเมื่อ |
|---|---|---|---|
| 0 | เปิดหุ่นตอนแขวน ไม่กดปุ่ม + เน็ตเวิร์ก | `sudo ip addr replace 192.168.123.123/24 dev enp43s0 && sudo ip link set enp43s0 up && sudo ip link set lo multicast on` แล้ว `ping -c 3 192.168.123.161` ([Network Setup](network_setup.md)) | ping 0% loss |
| 0a | **ปิด sim** | `pgrep -a unitree_mujoco` | ไม่มีผลลัพธ์ (ถ้ามี ปิดก่อน · `make deploy-real` ไม่ยอมเปิดถ้า sim เปิดอยู่) |
| 0b | **service บนคอม 164** ที่สั่งหุ่นได้ | `ssh unitree@192.168.123.164` แล้ว `systemctl is-active fibo_legged_robot_g1 g1_arm g1_arm_web` | `inactive` ทั้ง 3 · ถ้า `active` คุยกับรุ่นพี่แล้ว `sudo systemctl stop` ([Hi-level cmd](pc164_hi_level_cmd.md)) |
| 0c | **ดูบรรทัดแรกทุกโปรแกรม** | – | ต้องเป็น `DDS: REAL ROBOT ...` / `(REAL ROBOT, keyboard off...)` · เห็น `SIM` = ลืม `--network enp43s0` |
| 1 | สุขภาพหุ่น | `python $S/robot_health.py --network enp43s0` | PASS ทุกบรรทัด, **23 motors online** |
| 2 | ค่าศูนย์ข้อต่อ | `python $S/offset_check.py --network enp43s0 --joints right_elbow,...` | OK ทุกข้อต่อที่หมุน ([Offset Check](offset_check.md)) |
| 3 | เข้า debug | `motion_mode.py --network enp43s0 release` → `check` | `name=''`, ไฟเหลือง |
| 4 | sysid เบาๆ | `sysid_motion.py --network enp43s0 --groups armL --joints elbow --kinds step` | `kp x` ≈ 1, L2 + B หยุดได้ ([Sysid Motion](sysid_motion.md)) |
| 5 | FixStand gain ที่เทรน | `fixstand_train_gains.sh` + `IFACE=enp43s0 deploy_byobu.sh 1 bm` | `kp x` 0.8–1.2, `kd x` 0.5–1.5 ([FixStand Train Gains](../04-explanation/fixstand_train_gains.md)) |
| 6 | Handover + ปิด | **L1 + R1** ค้าง 1 s → START | ไฟม่วง, `name='ai'` ([Handover](handover.md)) → [Safe Shutdown](safe_shutdown.md) |
| (7) | ยืนบนพื้น P3b | checklist 9.2 | เมื่อทุกข้อผ่าน + 2 คน + เชือก |

## หน้าจอ byobu (T1–T4)
```
IFACE=enp43s0 deploy/robots/g1_23dof/scripts/deploy_byobu.sh <RUN> <TAG>      # log: ~/g1_{state,cmd}_<วันที่>_<TAG><RUN>.csv
┌─────────────────────┬─────────────────────┐
│ T1 lowstate_monitor │ T2 lowcmd_monitor   │
├─────────────────────┼─────────────────────┤
│ T3 g1_ctrl          │ T4 คำสั่ง/วิเคราะห์  │
└─────────────────────┴─────────────────────┘
```
- คำสั่งพิมพ์ไว้ในแต่ละช่องแต่**ยังไม่รัน** กด Enter เอง
- ย้ายช่อง: คลิก (เปิด mouse ไว้) หรือ Shift + ลูกศร (Alt + ลูกศร = สลับ window ไม่ใช่ช่อง)
- F6 = detach, `byobu attach -t g1deploy` = กลับมา
- `G1_CTRL_DIR=<dir>` เลือก g1_ctrl สำเนาอื่น

## หลังจบ
- จดผลในตารางท้ายใบพิมพ์
- log ใหญ่มาก (30/10: 4 GB ใน ~40 นาที) ตัดช่วงด้วย `awk` ก่อน `--replay`
- ส่งชื่อไฟล์ให้วิเคราะห์ด้วย `pd_check.py`

## ดูเพิ่ม
[Stop Mechanisms](../04-explanation/stop_mechanisms.md) · [Remote and LED](../03-reference/remote_and_led.md) · [Real Robot Tools](../03-reference/real_robot_tools.md) · [Real Robot Results](../05-history/real_robot_results.md)

คู่มือหน้าจอ T1–T4 และปุ่มลัด: [Byobu Guide](byobu_guide.md)
แผนทดสอบครั้งถัดไป (chirp วัด kd + L2 + B, ทดสอบเป็นทีม): แผนทดสอบ G1 23-DoF (เอกสารแยกของผู้ดูแล)
