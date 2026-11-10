# FSM Code Walkthrough: ไล่โค้ด FSM ของ g1_ctrl ทีละบรรทัด

> ย้ายมาจาก vault ของผู้ดูแล (`04 Code Map/FSM Code Walkthrough.md`) เมื่อ 10/11/2026 · ต้นฉบับอัปเดต 2026-11-04

โน้ตนี้ไล่โค้ด FSM ของ `g1_ctrl` ตามลำดับที่โปรแกรมทำงานจริง ตั้งแต่ก่อน `main()` ไปจนถึง loop 1 kHz และการเปลี่ยน state เลขบรรทัดอ้างอิง commit `b9c3eaa` ถ้าโค้ดเปลี่ยน เลขบรรทัดอาจเลื่อน ให้ค้นด้วยชื่อฟังก์ชัน
ภาพรวมแนวคิดอยู่ที่ [g1_ctrl FSM](../04-explanation/g1_ctrl_fsm.md) · สารบัญไฟล์อยู่ที่ [00 Code Map](code_map.md)

## สารบัญ
0. › 0. ไฟล์ที่เกี่ยวข้องและลำดับการทำงาน
1. › 1. BaseState.h: แม่แบบของทุก state และระบบลงทะเบียน
2. › 2. main.cpp: เริ่มโปรแกรม
3. › 3. config.yaml: นิยาม state และปุ่ม
4. › 4. CtrlFSM.h constructor: สร้าง state จาก config
5. › 5. FSMState.h: แปลงปุ่มเป็นเงื่อนไข + timeout
6. › 6. CtrlFSM::start() และ run_(): loop 1 kHz
7. › 7. State_Passive.h: state ที่ปลอดภัยที่สุด
8. › 8. State_FixStand.h: ค่อยๆ เข้าท่ายืน
9. › 9. ไล่เหตุการณ์จริง: กด L2 + ↑ แล้วเกิดอะไร
10. › 10. จุดที่ควรรู้ (gotchas)
11. › 11. แบบฝึกหัด

---

## 0. ไฟล์ที่เกี่ยวข้องและลำดับการทำงาน
| ไฟล์ | บรรทัด | บทบาท | ของใคร |
|---|---|---|---|
| `deploy/include/FSM/BaseState.h` | 54 | คลาสแม่ + มาโคร `REGISTER_FSM` | Unitree |
| `deploy/include/FSM/FSMState.h` | 99 | คลาสแม่ชั้นที่ 2: transition จาก yaml, timeout, ส่ง lowcmd | Unitree + **เราแก้ (คีย์ sim)** |
| `deploy/include/FSM/CtrlFSM.h` | 116 | ตัวคุม FSM: สร้าง state, loop, เปลี่ยน state | Unitree |
| `deploy/include/FSM/State_Passive.h` | 49 | damping | Unitree + เราแก้ (comment Zero-Kp) |
| `deploy/include/FSM/State_FixStand.h` | 58 | เข้าท่ายืน | Unitree |
| `deploy/robots/g1_23dof/main.cpp` | 93 | entry point | Unitree + **เราแก้** |
| `deploy/robots/g1_23dof/config/config.yaml` | – | นิยาม state / ปุ่ม / gain | Unitree + **เราแก้** |
| `deploy/include/unitree_joystick_dsl.hpp` | – | แปลงข้อความปุ่ม (`LT + up.on_pressed`) เป็นฟังก์ชัน | Unitree |

**ลำดับเวลาที่โค้ดทำงาน**
```
[ก่อน main]  REGISTER_FSM(...) ของทุก state → ใส่ "โรงงาน" ลง getFsmMap()
[main]       อ่าน args → Init DDS → init_fsm_state() (lowcmd, lowstate, timeout 100 ms)
             → เช็ค mode_machine = 4 → new CtrlFSM(config["FSM"])
                  ├ ใส่ชื่อ/id ทุก state ลง FSMStringMap
                  └ สร้าง object ของแต่ละ state → constructor ของ FSMState อ่าน transitions
             → (sim) ผูกคีย์ h/p → fsm->start() → while(true) sleep(1)
[thread FSM] ทุก 1 ms: pre_run → run → post_run → เช็คเงื่อนไข → (exit → enter)
```

---

## 1. BaseState.h: แม่แบบของทุก state และระบบลงทะเบียน
```cpp
11  inline boost::bimap<int, std::string> FSMStringMap;
```
- **ตารางสองทาง id ↔ ชื่อ** เช่น `1 ↔ "Passive"` ใช้ `.left.at(id)` หาชื่อ และ `.right.at("Passive")` หา id
- `inline` (C++17) = มีตัวแปรเดียวทั้งโปรแกรม แม้หลายไฟล์ include

```cpp
13  class BaseState {
16      BaseState(int state, std::string state_string) : state_(state)
18          { FSMStringMap.insert({state, state_string}); }
```
- ทุก state มี **id (int)** เก็บใน `state_` และลงชื่อในตาราง (ถ้ามีอยู่แล้ว bimap จะไม่ใส่ซ้ำ)

```cpp
21      virtual void enter() {}        // เรียกครั้งเดียวตอนเข้า state
23      virtual void pre_run() {}      // ทุก 1 ms: อ่านข้อมูล
24      virtual void run() {}          // ทุก 1 ms: คำนวณคำสั่ง
25      virtual void post_run() {}     // ทุก 1 ms: ส่งคำสั่ง
27      virtual void exit() {}         // เรียกครั้งเดียวตอนออก
```
- **5 ฟังก์ชันหลักของทุก state** เป็น `virtual` ค่าเริ่มต้นไม่ทำอะไร state ลูก override เฉพาะที่ต้องใช้

```cpp
29      std::string getStateString() { return FSMStringMap.left.at(state_); }
30      int getState() { return state_; }
31      bool isState(int state) { return state_ == state; }
32      std::vector<std::pair<std::function<bool()>, int>> registered_checks;
```
- `registered_checks` = **รายการ "เงื่อนไข → id ปลายทาง"** แต่ละคู่คือ (ฟังก์ชันที่คืน true/false, id ของ state ที่จะไป) **นี่คือหัวใจของการเปลี่ยน state**

```cpp
37  using FsmFactory = std::function<std::shared_ptr<BaseState>(int, std::string)>;
38  using FsmMap     = std::unordered_map<std::string, FsmFactory>;
40  inline FsmMap& getFsmMap() { static FsmMap fsmMap; return fsmMap; }
```
- `FsmMap` = **ตาราง "ชื่อคลาส → ฟังก์ชันสร้าง object"** เช่น `"State_Passive" → สร้าง State_Passive`
- ใช้ `static` ในฟังก์ชัน เพื่อให้ตารางถูกสร้างก่อนถูกใช้เสมอ (กันปัญหาลำดับการสร้างตัวแปร global ข้ามไฟล์)

```cpp
45  #define REGISTER_FSM(Derived) \
46      inline std::shared_ptr<BaseState> __factory_##Derived(int s, std::string ss) { \
47          return std::make_shared<Derived>(s, ss); } \
49      inline struct __registrar_##Derived { \
50          __registrar_##Derived() { getFsmMap()[#Derived] = __factory_##Derived; } \
53      } __registrar_instance_##Derived;
```
- เขียน `REGISTER_FSM(State_Passive)` ท้ายไฟล์ แล้วมาโครจะสร้าง:
  1. ฟังก์ชัน `__factory_State_Passive` ที่ `make_shared<State_Passive>`
  2. struct ที่ constructor ใส่ฟังก์ชันนั้นลงตารางด้วยชื่อ `"State_Passive"` (`#Derived` = แปลงเป็นข้อความ)
  3. ตัวแปร global ของ struct นั้น → **constructor รันก่อน `main()`** ทุก state จึงลงทะเบียนตัวเองอัตโนมัติ
- ผล: เพิ่ม state ใหม่ได้โดยไม่ต้องแก้ `CtrlFSM` (Handover ก็ใช้วิธีนี้)

---

## 2. main.cpp: เริ่มโปรแกรม
```cpp
1-6   #include "FSM/CtrlFSM.h" ... "State_Handover.h"
```
- **include = ลงทะเบียน** state ใดที่ไม่ได้ include จะไม่มีใน `getFsmMap()` แล้ว config อ้างถึงจะ error `Unknown FSM type`

```cpp
8   std::unique_ptr<LowCmd_t>  FSMState::lowcmd  = nullptr;
9   std::shared_ptr<LowState_t> FSMState::lowstate = nullptr;
10  std::shared_ptr<Keyboard>   FSMState::keyboard = std::make_shared<Keyboard>();
```
- นิยามตัวแปร `static` ของ `FSMState` **ทุก state ใช้ lowcmd / lowstate ตัวเดียวกัน** (ข้อความคำสั่งมีก้อนเดียว ใครเป็น state ปัจจุบันก็เขียนก้อนนั้น)

```cpp
12  void init_fsm_state() {
14      auto lowcmd_sub = std::make_shared<...::LowCmd>();
15      usleep(0.2 * 1e6);
16      if(!lowcmd_sub->isTimeout()) {
18          spdlog::critical("The other process is using the lowcmd channel, please close it first.");
19          unitree::robot::go2::shutdown();
20          // exit(0);
```
- ฟัง `rt/lowcmd` 0.2 s ถ้ามีคนส่งอยู่ (เช่น g1_ctrl อีกตัว หรือ controller `ai`) ให้เตือน
- ⚠️ **`exit(0)` ถูก comment ไว้** โปรแกรมจึงรันต่อ (เราเจอ: g1_ctrl สองตัวบน `lo` แย่งกัน) → ต้อง `release` และเช็ค `robot_health.py` ว่า lowcmd = 0 เองก่อนเปิด

```cpp
22      FSMState::lowcmd   = std::make_unique<LowCmd_t>();
23      FSMState::lowstate = std::make_shared<LowState_t>();
25      FSMState::lowstate->wait_for_connection();
30      FSMState::lowstate->set_timeout_ms(100);
```
- สร้าง publisher `rt/lowcmd` และ subscriber `rt/lowstate`
- `wait_for_connection()` วนรอทุก 100 ms จนกว่าจะได้ LowState ข้อความแรก (ถ้าเกิน 2 s พิมพ์ `Waiting for connection`)
- **ตั้ง timeout 100 ms หลังเชื่อมต่อแล้ว** (เราแก้ commit e0851be ค่าเดิมของ SDK คือ 1000 ms) ใช้ในเงื่อนไข "LowState ขาด → Passive" (› 5. FSMState.h: แปลงปุ่มเป็นเงื่อนไข + timeout)

```cpp
37  auto vm = param::helper(argc, argv);
38  FSMState::keyboard_fsm_shortcuts_enabled = (vm["network"].as<std::string>() == "lo");
45  unitree::robot::ChannelFactory::Instance()->Init(0, vm["network"].as<std::string>());   // 5/11: เปลี่ยนเป็น Init(domain, network) + บังคับ --network
47  init_fsm_state();
49  FSMState::lowcmd->msg_.mode_machine() = 4; // 23dof
50  if(!FSMState::lowcmd->check_mode_machine(FSMState::lowstate)) { ... exit(-1); }
56  auto fsm = std::make_unique<CtrlFSM>(param::config["FSM"]);
```
- `param::helper` อ่าน `--network` และโหลด `config.yaml` เข้า `param::config`
- คีย์บอร์ดเปลี่ยน state ได้ **เฉพาะ `--network lo` (sim)** หุ่นจริงใช้ไม่ได้ (กันพิมพ์ผิดแล้วหุ่นขยับ)
- DDS domain 0 บน interface ที่ระบุ (`enp43s0` หุ่นจริง / `lo` sim)
- `mode_machine` ต้องตรงกับหุ่น (23dof = 4) ไม่ตรงปิดโปรแกรม
- บรรทัด 56 สร้าง FSM จาก config (› 4. CtrlFSM.h constructor: สร้าง state จาก config)

```cpp
57-70  if (keyboard_fsm_shortcuts_enabled && FSMStringMap.right.count("Handover")) { ... }
```
- (เราเพิ่ม) ผูกคีย์ sim `h` (Passive → Handover) และ `p` (Handover → Passive) โดยต่อท้าย `registered_checks` ของ state นั้นๆ ตรงๆ เพราะคีย์ชุดเดิมใน `FSMState.h` รู้จักแค่ u/v/p

```cpp
72  fsm->start();
86  while (true) { sleep(1); }
```
- `start()` เปิด thread ของ FSM แล้ว **main thread แค่นอนรอตลอดไป** งานทั้งหมดอยู่ใน thread FSM ปิดด้วย Ctrl-C

---

## 3. config.yaml: นิยาม state และปุ่ม
```yaml
1  FSM:
2    _: # enabled fsms
3      Passive:   { id: 1 }
5      FixStand:  { id: 2 }
7      Velocity:  { id: 3, type: RLBase }
10     Handover:  { id: 4 }
```
- `_:` = **รายชื่อ state ที่เปิดใช้** (comment ออก = ปิด เช่น Mimic)
- `id` เริ่มที่ 1 เพราะ **0 แปลว่า "ไม่เปลี่ยน state"** ใน `run_()`
- `type` = ชื่อคลาส ถ้าไม่ใส่ใช้ชื่อ state → Velocity ใช้คลาส `State_RLBase`
- **ลำดับสำคัญ:** state แรกในรายการ (Passive) คือ state เริ่มต้น

```yaml
17   Passive:
18     transitions:
19       FixStand: LT + up.on_pressed
23       Handover: LB(1s) + RB(1s) + start.on_pressed
24     mode: [1,1,...]     # เปิดมอเตอร์ทั้ง 29 ช่อง
31     kd: [4.0, ...]       # damping ของ Passive
38   FixStand:
39     transitions:
40       Passive: LT + B.on_pressed
41       Velocity: RT + A.on_pressed
42     kp: [...]  kd: [...]  ts: [0, 3]  qs: [[], [-0.1, 0, 0, 0.3, -0.2, 0, ...]]
```
- `transitions:` = **ปลายทาง: เงื่อนไขปุ่ม** (LT = L2, RT = R2, LB = L1, RB = R1)
  - `.on_pressed` = เพิ่งกดในรอบนี้ (ขอบขาขึ้น)
  - `LB(1s)` = กดค้างอย่างน้อย 1 วินาที
  - `+` = และ
- อาร์เรย์ทุกตัวยาว 29 = ช่อง SDK (ช่อง 13, 14, 20, 21, 27, 28 ไม่มีข้อต่อใน 23dof) ([Joint Map and Slots](joint_map_and_slots.md))

---

## 4. CtrlFSM.h constructor: สร้าง state จาก config
```cpp
17  CtrlFSM(YAML::Node cfg) {
19      auto fsms = cfg["_"];                       // enabled FSMs
21      for (auto it = fsms.begin(); ...) {         // รอบที่ 1
23          std::string fsm_name = it->first.as<std::string>();
24          int id = it->second["id"].as<int>();
25          FSMStringMap.insert({id, fsm_name});
26      }
```
- **รอบที่ 1: ลงชื่อ/id ของทุก state ก่อน** ยังไม่สร้าง object
- เหตุผล: ตอนสร้าง Passive (รอบที่ 2) constructor ต้องแปลง `Handover:` ใน transitions เป็น id ถ้า Handover ยังไม่ลงชื่อ จะหาไม่เจอ (`warn ... not found` แล้วข้ามไป)

```cpp
29      for (auto it = fsms.begin(); ...) {         // รอบที่ 2
31          std::string fsm_name = ...; int id = ...;
33          std::string fsm_type = it->second["type"] ? it->second["type"].as<std::string>() : fsm_name;
34          auto fsm_class = getFsmMap().find("State_" + fsm_type);
35          if (fsm_class == getFsmMap().end())
36              throw std::runtime_error("FSM: Unknown FSM type " + fsm_type);
38          auto state_instance = fsm_class->second(id, fsm_name);
39          add(state_instance);
```
- **รอบที่ 2: สร้าง object** หาโรงงานด้วยชื่อ `"State_" + type` ในตารางของ `REGISTER_FSM` แล้วเรียกสร้าง
- `fsm_name` ส่งเข้าไปด้วย → state รู้ว่าต้องอ่าน config ส่วนไหน (`config["FSM"]["Velocity"]` ทั้งที่คลาสชื่อ RLBase)
- ตอนสร้าง constructor ของ `FSMState` จะทำงาน (› 5. FSMState.h: แปลงปุ่มเป็นเงื่อนไข + timeout)

```cpp
add(state):
    for(auto & s : states) if(s->isState(state->getState())) { error "already exists"; exit(0); }
    states.push_back(std::move(state));
```
- กัน id ซ้ำ แล้วเก็บใน `states` ตามลำดับใน yaml → `states[0]` = Passive

---

## 5. FSMState.h: แปลงปุ่มเป็นเงื่อนไข + timeout
`FSMState` เป็นคลาสกลางระหว่าง `BaseState` กับ state จริง (`State_Passive : public FSMState`)

```cpp
14  inline static bool keyboard_fsm_shortcuts_enabled = false;
16  FSMState(int state, std::string state_string) : BaseState(state, state_string) {
19      spdlog::info("Initializing State_{} ...", state_string);
21      auto transitions = param::config["FSM"][state_string]["transitions"];
25      auto transition_map = transitions.as<std::map<std::string, std::string>>();
27      for(auto it = transition_map.begin(); ...) {
29          std::string target_fsm = it->first;               // เช่น "FixStand"
30          if(!FSMStringMap.right.count(target_fsm)) { warn; continue; }
36          int fsm_id = FSMStringMap.right.at(target_fsm);
38          std::string condition = it->second;               // "LT + up.on_pressed"
39          unitree::common::dsl::Parser p(condition);
40          auto ast = p.Parse();
41          auto func = unitree::common::dsl::Compile(*ast);
42          registered_checks.emplace_back(
44              [func]()->bool{ return func(FSMState::lowstate->joystick); },
45              fsm_id);
```
- บรรทัด log `Initializing State_Passive ...` ที่เห็นใน T3 มาจากบรรทัด 19
- อ่าน `transitions` ของ state ตัวเอง → **แปลงเป็น `std::map` ซึ่งเรียงตามตัวอักษร** (ดู › 10. จุดที่ควรรู้ (gotchas))
- ปลายทางที่ไม่อยู่ในรายการเปิดใช้ → เตือนแล้วข้าม (Mimic ถูกปิดไว้ transition ไป Mimic จึงหายไปเงียบๆ)
- **ข้อความปุ่ม → Parser → AST → Compile → ฟังก์ชัน** ที่รับสถานะรีโมท (`lowstate->joystick` แกะจาก `wireless_remote` ใน LowState) แล้วคืน true/false
- เก็บเป็นคู่ (ฟังก์ชัน, id ปลายทาง) ใน `registered_checks`

```cpp
48-72   // Laptop-keyboard shortcuts for local simulation (เราเพิ่ม, commit 233aac8)
51      if (state_string == "Passive" && target_fsm == "FixStand")        keyboard_key = "u";
53      else if (state_string == "FixStand" && target_fsm == "Velocity")  keyboard_key = "v";
55      else if ((FixStand || Velocity) && target_fsm == "Passive")       keyboard_key = "p";
61      registered_checks.emplace_back([keyboard_key]{ return keyboard_fsm_shortcuts_enabled && keyboard
                                                          && keyboard->on_pressed && keyboard->key() == keyboard_key; }, fsm_id);
```
- ผูกคีย์ไว้กับ **transition ที่มีอยู่แล้วใน yaml เท่านั้น** ถ้าลบ `Velocity: RT + A` (แบบ `fixstand_train_gains.sh`) คีย์ `v` ก็หายไปด้วย → ปลอดภัย
- ⚠️ ไฟล์นี้เป็นไฟล์ร่วม (ทุกหุ่นใช้) เราแก้ก่อนตั้งกติกา

```cpp
77  registered_checks.emplace_back(
79      []()->bool{ return lowstate->isTimeout(); },
80      FSMStringMap.right.at("Passive"));
```
- **ทุก state ได้เงื่อนไขนี้ต่อท้าย:** LowState ไม่มาเกิน 100 ms → Passive
- `isTimeout()` ใน SDK = `now - last_update_time_ > timeout_ms_` (`unitree/dds_wrapper/common/Subscription.h`)
- ⚠️ ถ้า DDS ขาดจริง คำสั่ง Passive ก็ส่งไม่ถึงหุ่นเหมือนกัน → ป้องกันได้เฉพาะกรณีที่ **ขาเข้า** ขาด (เช่นสายหลวมแค่ทางเดียว หรือ lowstate ค้าง)

```cpp
85  void pre_run()  { lowstate->update(); if(keyboard) keyboard->update(); }
91  void post_run() { lowcmd->unlockAndPublish(); }
96  static std::unique_ptr<LowCmd_t> lowcmd;  static std::shared_ptr<LowState_t> lowstate;  static std::shared_ptr<Keyboard> keyboard;
```
- `pre_run` (ค่าเริ่มต้นของทุก state): อัพเดทข้อมูล LowState/รีโมท และคีย์บอร์ด
- `post_run`: **ส่ง lowcmd ทุก 1 ms** `unlockAndPublish()` ของ SDK (`RealTimePublisher`, แนวทาง ros-controls realtime_tools) ไม่ได้ส่งเองตรงนั้น แต่ปลด lock แล้วส่งต่อให้ **thread ส่งข้อความเบื้องหลัง** loop FSM จึงไม่ต้องรอเครือข่าย
- Handover override `post_run` ให้ไม่ส่ง (`if (publishing_)`) จึงหยุด lowcmd ได้

---

## 6. CtrlFSM::start() และ run_(): loop 1 kHz
```cpp
start():
    currentState = states[0];                 // Passive
    currentState->enter();
    fsm_thread_ = std::make_shared<unitree::common::RecurrentThread>("FSM", 0, this->dt * 1e6, &CtrlFSM::run_, this);
    spdlog::info("FSM: Start {}", currentState->getStateString());
...
    const double dt = 0.001;
```
- เริ่มที่ `states[0]` และเรียก `enter()` ของมันก่อนเปิด thread
- `RecurrentThread` ของ Unitree เรียก `run_()` ซ้ำทุก `dt * 1e6` = **1000 µs (1 kHz)**
- log `FSM: Start Passive` ใน T3 มาจากตรงนี้

```cpp
82  void run_() {
84      currentState->pre_run();
85      currentState->run();
86      currentState->post_run();
```
- **ทุก 1 ms เรียก 3 ขั้นของ state ปัจจุบัน** ด้วย virtual dispatch: `currentState` เป็น pointer แบบ `BaseState` แต่เรียกฟังก์ชันของคลาสจริง (Passive / FixStand / RLBase / Handover)

```cpp
89      int nextStateMode = 0;
90      for(int i(0); i<currentState->registered_checks.size(); i++) {
92          if(currentState->registered_checks[i].first()) {
94              nextStateMode = currentState->registered_checks[i].second;
95              break;
```
- ไล่เงื่อนไขของ state ปัจจุบัน **ตามลำดับที่ลงทะเบียน** ตัวแรกที่เป็นจริงชนะ (`break`)

```cpp
99      if(nextStateMode != 0 && !currentState->isState(nextStateMode)) {
101         for(auto & state : states) {
103             if(state->isState(nextStateMode)) {
105                 spdlog::info("FSM: Change state from {} to {}", ...);
106                 currentState->exit();
107                 currentState = state;
108                 currentState->enter();
109                 break;
```
- 0 = ไม่มีเงื่อนไขไหนจริง → อยู่ state เดิม
- ปลายทางเป็น state เดิม → ไม่ทำอะไร (เช่น timeout ตอนอยู่ Passive จึงไม่เรียก `enter()` ซ้ำทุก ms)
- **ลำดับการเปลี่ยน:** log → `exit()` ของเดิม → สลับ pointer → `enter()` ของใหม่ ทั้งหมดอยู่ในรอบเดียวกัน
- `run()` ของ state ใหม่จะถูกเรียกครั้งแรกใน **รอบถัดไป** (1 ms ต่อมา)

---

## 7. State_Passive.h: state ที่ปลอดภัยที่สุด
```cpp
11  State_Passive(int state, std::string state_string = "Passive") : FSMState(state, state_string) {
14      auto motor_mode = param::config["FSM"]["Passive"]["mode"];
17      auto values = motor_mode.as<std::vector<int>>();
20      for(...) lowcmd->msg_.motor_cmd()[i].mode() = values[i];
```
- ตั้ง `mode` ของมอเตอร์ทุกช่องครั้งเดียวตอนสร้าง (1 = เปิดใช้) ค่านี้อยู่ใน lowcmd ตลอด state อื่นไม่ได้แก้

```cpp
25  void enter() {
29      static auto kd = param::config["FSM"]["Passive"]["kd"].as<std::vector<float>>();
30      for(int i(0); i < kd.size(); ++i) {
33          motor.kp() = 0;  motor.kd() = kd[i];  motor.dq() = 0;  motor.tau() = 0;
```
- **ตัด kp เป็น 0 ทันที** เหลือ kd (damping) → ข้อต่อไม่ดันกลับท่า แต่หนืด ล้มช้าลง (comment "Zero-Kp Pure Viscous Damping" เราเพิ่ม)
- `static` = อ่าน config ครั้งเดียวตอนเข้า Passive ครั้งแรก
- แรงบิด = `kd · (0 − dq)` = ต้านความเร็วอย่างเดียว ([PD Control](../04-explanation/pd_control.md))

```cpp
40  void run() {
42      for(i ...) lowcmd->msg_.motor_cmd()[i].q() = lowstate->msg_.motor_state()[i].q();
```
- ทุก 1 ms ตั้ง `q_des` = ตำแหน่งปัจจุบัน (kp เป็น 0 อยู่แล้ว ค่านี้จึงไม่มีผลต่อแรง)
- **ประโยชน์ซ่อน:** ตอนเข้า FixStand `q_des` ล่าสุดคือท่าปัจจุบันพอดี → FixStand ใช้เป็นจุดเริ่ม interpolate ไม่กระชาก (› 8. State_FixStand.h: ค่อยๆ เข้าท่ายืน)

```cpp
49  REGISTER_FSM(State_Passive)
```

---

## 8. State_FixStand.h: ค่อยๆ เข้าท่ายืน
```cpp
12  State_FixStand(...) : FSMState(...) {
15      ts_ = param::config["FSM"]["FixStand"]["ts"].as<std::vector<float>>();               // [0, 3]
16      qs_ = param::config["FSM"]["FixStand"]["qs"].as<std::vector<std::vector<float>>>();  // [[], ท่ายืน]
17      assert(ts_.size() == qs_.size());
```
- จุดเวลา `ts` คู่กับท่า `qs`: ที่ t = 0 s ใช้ท่าแรก (ว่างไว้ เติมตอน enter), ที่ t = 3 s ใช้ท่ายืน

```cpp
20  void enter() {
23      static auto kp = ...["FixStand"]["kp"];  static auto kd = ...["FixStand"]["kd"];
25      for(i) { motor.kp() = kp[i]; motor.kd() = kd[i]; motor.dq() = motor.tau() = 0; }
35      std::vector<float> q0;
36      for(i) q0.push_back(lowcmd->msg_.motor_cmd()[i].q());
39      qs_[0] = q0;
40      t0_ = GetCurrentTimeMillisecond() * 1e-3;
```
- ตั้ง gain ของ FixStand (ชุด Unitree 100/150/40/200 หรือชุดเทรนใน `/tmp/g1_fixstand_train`)
- **ท่าเริ่ม = `q_des` ล่าสุดใน lowcmd** (ซึ่ง Passive ตั้งเป็นท่าปัจจุบันไว้) ไม่ได้อ่าน lowstate ตรงๆ
- จดเวลาเริ่ม

```cpp
43  void run() {
45      float t = GetCurrentTimeMillisecond() * 1e-3 - t0_;
46      auto q = linear_interpolate(t, ts_, qs_);
48      for(i) lowcmd->msg_.motor_cmd()[i].q() = q[i];
```
- ทุก 1 ms คำนวณ `q_des` แบบเส้นตรงจากท่าเริ่มไปท่ายืนใน 3 วินาที หลัง 3 วินาทีค้างที่ท่ายืน (`LinearInterpolator.h`)
- PD ในมอเตอร์ทำให้ข้อต่อตาม `q_des` (3/11 ใช้ gain เทรน: ห่างท่า ขา ≤ 0.04 rad) ([FixStand Train Gains](../04-explanation/fixstand_train_gains.md))

---

## 9. ไล่เหตุการณ์จริง: กด L2 + ↑ แล้วเกิดอะไร
log จริงจาก 3/11 (T3)
```
19:54:01.047 [info] Initializing State_Passive ...        ← FSMState ctor บรรทัด 19 (ตอน new CtrlFSM)
19:54:01.065 [info] Initializing State_Handover ...
19:54:01.065 [info] FSM: Start Passive                     ← CtrlFSM::start()
19:54:30.088 [info] FSM: Change state from Passive to FixStand
19:59:58.295 [info] FSM: Change state from FixStand to Passive
```
ลำดับภายในโค้ดตอนกด L2 + ↑ (เวลา 19:54:30.088):
1. รอบ k: `pre_run()` → `lowstate->update()` อ่าน `wireless_remote` ใหม่ → joystick: LT กดอยู่, up เพิ่งกด
2. `run()` ของ Passive ตั้ง `q_des` = ท่าปัจจุบัน → `post_run()` ส่ง lowcmd (kp 0)
3. ไล่ `registered_checks` ของ Passive ตามลำดับ [FixStand ปุ่ม, คีย์ `u`, Handover ปุ่ม, timeout, คีย์ `h` (sim)] → ฟังก์ชันของ `LT + up.on_pressed` คืน true → `nextStateMode = 2`
4. log `Change state from Passive to FixStand` → `Passive::exit()` (ว่าง) → `currentState = FixStand` → `FixStand::enter()` ตั้ง kp/kd, `qs_[0]` = ท่าปัจจุบัน, `t0_` = ตอนนี้
5. รอบ k+1 (1 ms ต่อมา): `FixStand::run()` t ≈ 0.001 s → `q_des` ≈ ท่าปัจจุบัน → `post_run()` ส่ง lowcmd ที่มี kp แล้ว → มอเตอร์เริ่มออกแรงโดยไม่กระชาก
6. 3 วินาทีต่อมา `q_des` = ท่ายืน ค้างไว้จนกด L2 + B → `LT + B.on_pressed` → Passive

---

## 10. จุดที่ควรรู้ (gotchas)
| เรื่อง | รายละเอียด | ผล |
|---|---|---|
| **ลำดับเงื่อนไขเรียงตามตัวอักษร** | `transitions.as<std::map<...>>()` → `std::map` เรียงตามชื่อปลายทาง ไม่ใช่ตามลำดับใน yaml แต่ละปลายทางใส่ปุ่มก่อนแล้วตามด้วยคีย์ sim (ถ้ามี) จากนั้น timeout และสุดท้ายคีย์ที่ `main.cpp` ต่อท้าย เช่น Passive = [FixStand ปุ่ม, คีย์ `u`, Handover ปุ่ม, timeout, คีย์ `h`] | ถ้าสองเงื่อนไขจริงในรอบเดียว ตัวที่ชื่อมาก่อนชนะ เช่น FixStand: `Passive` < `Velocity` → กด L2 + B พร้อม R2 + A จะไป Passive (ปลอดภัย) |
| state เริ่มต้น = ตัวแรกใน `_:` | `start()` ใช้ `states[0]` comment เขียนว่า "Start From State_Passive" แต่โค้ดไม่ได้บังคับ | **อย่าย้าย Passive ออกจากบรรทัดแรก** |
| เช็ค lowcmd ซ้อนไม่หยุดโปรแกรม | `exit(0)` ใน `init_fsm_state()` ถูก comment | ต้องเช็ค lowcmd = 0 เองก่อนเปิด (`robot_health.py`) |
| timeout ป้องกันได้แค่ขาเข้า | ถ้าเน็ตขาดทั้งสองทาง คำสั่ง Passive ก็ไปไม่ถึง | มอเตอร์ใช้คำสั่งล่าสุดต่อ ยังต้องพึ่งรอก/คนคุม |
| `run()` ของ state ใหม่ช้ากว่า enter 1 รอบ | เปลี่ยน state ท้ายรอบ | ใน 1 ms นั้น lowcmd ยังเป็นค่าที่ `enter()` ตั้ง (เช่น FixStand: kp ใหม่ + `q_des` เดิม = ท่าปัจจุบัน) |
| `static` ใน `enter()` | อ่าน config ครั้งแรกครั้งเดียว | แก้ `config.yaml` ระหว่างรันไม่มีผล ต้องเปิด g1_ctrl ใหม่ |
| ทุก state ใช้ lowcmd ก้อนเดียว | ค่าที่ state ก่อนหน้าตั้งค้างอยู่ถ้า state ใหม่ไม่ได้เขียนทับ | ตัวอย่าง: `mode` ตั้งครั้งเดียวใน Passive ctor |
| include = ลงทะเบียน | ลืม `#include "State_X.h"` ใน main.cpp | `Unknown FSM type X` ตอนเริ่ม |

---

## 11. แบบฝึกหัด
ลองตอบจากโค้ด แล้วเช็คด้วย sim (`--network lo`)
1. ถ้าเพิ่ม `Passive: RT + B.on_pressed` ใน transitions ของ Velocity มันจะถูกเช็คก่อนหรือหลัง `LT + B` ทำไม
2. ทำไม Handover เข้าจาก FixStand ไม่ได้ (ดู `config.yaml` อย่างเดียว ไม่ต้องแก้โค้ด)
3. ถ้า LowState ขาด 150 ms ระหว่างอยู่ใน FixStand แล้วกลับมา หุ่นจะอยู่ state ไหน และต้องกดอะไรถึงจะกลับไปยืน
4. ถ้าเปลี่ยน `ts: [0, 3]` เป็น `[0, 1]` อะไรเปลี่ยน และเสี่ยงอะไรบนหุ่นจริง
5. เขียน state ใหม่ `State_HoldPose` ที่ค้างท่าปัจจุบันด้วย kp ต่ำ ต้องแก้ไฟล์ไหนบ้าง (ใบ้: ดูว่า Handover เพิ่มอะไร: [00 Code Map › 4. unitree_rl_mjlab: g1_ctrl ตัว deploy (C++)](code_map.md))

## ไฟล์ถัดไปที่ควรอ่าน
- `deploy/include/FSM/State_RLBase.h` + `deploy/robots/g1_23dof/src/State_RLBase.cpp`: state ที่รัน policy, soft start, เช็คเอียง ([Soft Start](../04-explanation/soft_start.md))
- `deploy/robots/g1_23dof/include/State_Handover.h`: override `post_run` + thread ([Handover](../02-how-to/handover.md))
- `deploy/include/unitree_joystick_dsl.hpp`: Parser / Compile ของข้อความปุ่ม
