# Tutorials: ทำตามทีละวัน

ทำตามลำดับ แต่ละหน้าจบด้วย "ผลที่ต้องเห็น" และรายการทบทวน ถ้าไม่เห็นผลตามนั้น อย่าข้ามไปหน้าถัดไป ให้ดู [../pitfalls.md](../pitfalls.md)
ยังไม่เคยใช้ terminal, conda, make หรือ DDS: อ่าน [พื้นฐาน 8 หน้า](../04-explanation/basics/README.md) ก่อน

ทุกขั้นแสดง**คำสั่งเต็ม**ก่อน แล้วค่อยบอกทางลัด `make` (หลักการ: [ROADMAP](../ROADMAP.md) ข้อ 2–3)

| วัน | หน้า | ผลที่ต้องเห็น |
|---|---|---|
| 1 | [ติดตั้ง และเห็นหุ่นเดินใน sim](day1_setup_and_sim.md) | `make doctor` 0 FAIL · หุ่นเดินใน sim ด้วยคีย์บอร์ด · ปิด session เป็น |
| 2 | [เทรน policy เอง แล้วดูผล](day2_train.md) | เทรน 500 รอบ · อ่านกราฟใน TensorBoard เป็น · `make play` เห็นหุ่น |
| 3 | [export และ sim2sim](day3_export_and_sim2sim.md) | สร้างโฟลเดอร์ policy · `gain-check` PASS · อ่านผล `vel_eval` เป็น |
| 4 | [ซ้อมวันทดสอบใน sim](day4_real_robot_rehearsal.md) | ซ้อมครบ 9 ข้อ · หยุดได้ทันทีโดยไม่ต้องคิด |
| 5 | [วันทดสอบหุ่นจริง](day5_real_robot.md) | รู้ลำดับ เอกสาร และบทบาทของตัวเอง (ทดสอบเป็นกลุ่มเท่านั้น) |
