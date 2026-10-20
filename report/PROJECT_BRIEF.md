# PROJECT_BRIEF.md — Sense&Safe (โน้ตสรุปสำหรับ Claude อ่านเร็ว)

> ไฟล์นี้คือ "ความจำ" ของโปรเจกต์ อ่านไฟล์นี้ก่อนตอบทุกครั้งเพื่อไม่ต้องเปิด PDF ทั้งเล่ม
> อ้างอิงเต็ม: `SenseSafe-Report.pdf` (รายงานหลัก อยู่โฟลเดอร์เดียวกัน), `../planning/Tech-Plan.md`
> อัปเดตล่าสุด: 10 ก.ค. 2026 (เพิ่มหัวข้อ 3b — BOM ฮาร์ดแวร์ต้นแบบเปลี่ยน)

> ⚠️ **สถานะ 10 ต.ค. 2026:** ไฟล์นี้สรุป**รายงานฉบับเดิม** (นำทางขับรถด้วยการสั่น, LD 4 กลุ่มรวม ADHD)
> ตั้งแต่ 13 ก.ย. 2026 ทีมเสนอเปลี่ยนทิศเป็น **"Everyday Life & Mobility Copilot for Pure LD"**
> (ผู้ช่วยงานประจำวัน + เดินเท้า/ขนส่งสาธารณะ, เฉพาะ Pure LD ไม่รวม ADHD/ASD, ไม่ทำนำทางในอาคาร)
> สเปกและการตัดสินใจทั้งหมดอยู่ที่ `../planning/Pivot-2026-09-13-Everyday-Copilot.md`
> และสรุปใน `../CLAUDE.md` หัวข้อ Pivot — ยังรอยืนยันอย่างเป็นทางการก่อนแก้รายงาน

---

## 1. โปรเจกต์คืออะไร (1 ประโยค)
**Sense&Safe: LD Haptic Drive Assistant** — แอปมือถือ + สายรัดข้อมือสั่น 2 ข้าง (ซ้าย/ขวา) ที่นำทางขับรถ **ด้วยการสัมผัส (สั่น) แทนการมอง/ฟัง** ออกแบบเพื่อผู้บกพร่องการเรียนรู้ (LD) 4 กลุ่ม
- ทีม: **กลุ่ม Sense&Safe** (ธีทัต ธีรสถาพรกุล, วิธยุตม์ พิชรานันท์, ณัฐฐนิตา อิงคากุล) — คณะ ICT ม.มหิดล
- งานนำเสนอ: ค่ายฝึกอบรม AI เพื่อผู้พิการ 5 หมวด, 22–24 พ.ค. 2569
- แนวคิดหลัก: ตัด step การ "แปลซ้าย-ขวา / อ่านตัวเลข / อ่านป้าย" ทิ้ง → ข้อมือซ้ายสั่น = เลี้ยวซ้าย, ยิ่งใกล้จุดเลี้ยวยิ่งสั่นแรง/ถี่ (แมประยะเป็นความรู้สึก)

## 2. กลุ่มเป้าหมาย LD 4 กลุ่ม (ทำไมสั่นถึงช่วย)
- **Spatial Dyspraxia** — แยกซ้าย-ขวาไม่ทัน → รู้สึกจากข้างที่สั่นทันที (egocentric encoding)
- **Dyscalculia** — แปลงตัวเลขระยะไม่ได้ → ความแรงสั่น = ระยะ (ไม่บอกตัวเลขเลย)
- **Dyslexia** — อ่านป้าย/จอไม่ทัน → ไม่มีข้อความให้อ่านเลยระหว่างขับ
- **ADHD** — วอกแวกง่าย → สัญญาณสัมผัสตัดผ่านสิ่งรบกวน + ตรวจ stress ปรับสั่นให้เบาลงอัตโนมัติ

## 3. ★ ฮาร์ดแวร์สายรัดข้อมือ (คำตอบ "อุปกรณ์ที่ใช้ทำ device") — จากรายงานจริง
ทำ **2 ชุด (ซ้าย+ขวา)** แต่ละสายรัดประกอบด้วย:
| ชิ้นส่วน | รุ่น | หน้าที่ |
|---|---|---|
| ตัวควบคุมหลัก (MCU) | **ESP32** | สมองของสายรัด, มี BLE ในตัว (ไม่ต้องมีชิป BLE แยก), กินไฟต่ำ |
| ตัวขับมอเตอร์ | **DRV2605L** (Haptic Motor Driver) | รับ PWM จาก ESP32 → ขับ LRA, คุมความแรง/ความถี่ละเอียด (ขาด driver นี้ ESP32 ขับ LRA ตรงๆ ไม่ได้) |
| มอเตอร์สั่น | **LRA Motor** (Linear Resonant Actuator) | มอเตอร์แบนแบบใน iPhone, สั่นนุ่มนวล/ปรับแรงละเอียด (ดีกว่า ERM) — จำเป็นต่อ HAPU ที่ต้อง dynamic intensity |
| เซ็นเซอร์หัวใจ | **MAX30102** (Heart Rate & SpO2) | วัด heart rate แบบ optical → ป้อน LSTM ตรวจ stress |
| เซ็นเซอร์การเคลื่อนไหว | **LSM6DS3** (IMU: accel + gyro) | วัดการขยับมือ → ช่วยกรอง noise ออกจาก PPG + ป้อน stress detection |

**อุปกรณ์ประกอบระบบอื่น (ไม่ได้อยู่บนสายรัด):** Dashcam/กล้องหน้ารถ (ส่งภาพผ่าน WiFi ให้ YOLO), ไมโครโฟน (สั่งเสียง), โทรศัพท์ (รันแอป = สมองกลาง), สายรัดมีสัญลักษณ์ L/R + ไอคอนคนยกแขนกันใส่ผิดข้าง

> หมายเหตุ: เอกสาร `../planning/Tech-Plan.md` (เก่ากว่า) เคยพูดถึง XIAO nRF52840 ฯลฯ — **ยึดตามรายงาน PDF ที่ใช้ ESP32 เป็นหลัก**

### ★★ อัปเดต 14 ก.ค. 2026 — เซ็ตอุปกรณ์จริงที่จัดหา (เปลี่ยนเพราะของเดิมหายาก)
| หน้าที่ | ของจริงที่ใช้ | แทนที่ | หมายเหตุ |
|---|---|---|---|
| MCU + BLE | **ESP32-C3 Super Mini (CB021)** ×2 | ESP32 | เล็กกว่า เหมาะข้อมือ, BLE 5, Arduino ได้ |
| IMU | **MPU-6050** | LSM6DS3 | แทนกันได้ library เยอะกว่าด้วย |
| Heart rate | **GY-MAX30102 (NB199)** | MAX30102 | ตัวเดิม คนละ breakout |
| มอเตอร์สั่น | **AH024 (PWM motor module)** | DRV2605L + LRA | ⚠️ ขับ PWM ตรงจาก ESP32; intensity = duty cycle 0–255 — หยาบกว่า LRA แต่พอสำหรับโปรโตไทป์; LRA ไว้อัปเกรดรุ่นหน้า |
| ชาร์จ | **AA477 Type-C charger** | (ไม่มีในแผนเดิม) | + **LiPo 3.7V 500mAh** — ใส่จริงได้ไม่ต้องเสียบสาย |

ผลต่อแอป: ไม่กระเทือน — `BleController.pulse(intensity, durationMs)` map เป็น
(PWM duty, ms) ตรง ๆ; spec 7-byte packet ใช้ต่อได้ ช่อง intensity = 0–255

---

## ★★★ RE-CHECK 21 ก.ค. 2026 — ตรวจไฟล์ "Sense&Safe (1).pdf" เวอร์ชันใหม่ (54 หน้า, จากเดิม 44 หน้า)

**สิ่งที่แก้แล้วจริง ✅** — อินโฟกราฟิก "System Architecture: AI Across 4 Layers"
(หน้าพิมพ์ 13, หัวข้อ 2.1) แก้ครบทั้ง 4 จุดที่เคยตามในรอบ 17 ก.ค.:
Layer 1 หัวคอลัมน์เปลี่ยนเป็น "AI & Signal Processing ที่ใช้" แล้ว, Layer 2
Navigation Engine (Fusion) เปลี่ยนเป็น "rule-based, AI-informed" (ไม่เขียน ML
Fusion Model แล้ว), Action Dispatcher เปลี่ยนเป็น "Rule-based Command Router"
(ตัดคำ AI/Model แล้ว), Firebase เปลี่ยนเป็น "Data & Sync Service" (ตัดคำ ML
แล้ว) — **ปิดประเด็นนี้ได้**

**ยังไม่แก้ 🔴** — หน้า Hardware 2.8 (หน้าพิมพ์ 20) ยังโชว์รูป/บรรยาย BOM ทฤษฎีเดิม
(ESP32 บอร์ดเขียว, DRV2605L, LRA coin motor, MAX30102 บอร์ดแดง, LSM6DS3)
เหมือนเดิมทุกตัวอักษร ไม่มี erratum บอกว่าของจริงที่ประกอบคือ ESP32-C3 Super
Mini + AH024 PWM + GY-MAX30102 (ม่วง) + MPU6050 (ดูตาราง 3b) — ยังเป็นความเสี่ยง
อันดับ 1 ถ้ากรรมการถามว่า "นี่คือของที่ประกอบจริงหรือเปล่า"

**พบใหม่ 🔴 (ใหญ่กว่าที่คิด) — สารบัญ/เลขบทไม่ตรงกับเนื้อในทั้งเล่ม**
เดาว่าเกิดจากรายงานยาวขึ้นจาก 44→54 หน้า (เพิ่มบท "กลุ่มเป้าหมายและแนวทาง"
เต็มบท + บท "แผนรับมือ Negative case" เต็มบท) แต่ไม่มีใครย้อนกลับไปอัปเดต
สารบัญ/เลขบทให้ตรง:
- หัวบท System Architecture (หน้าพิมพ์ 12) พิมพ์ว่า **"บทที่ -"** เฉยๆ (เลขบทหาย)
- ในเนื้อหาจริงบทนี้มาหลังบท "บทที่ 2: กลุ่มเป้าหมายและแนวทาง" (มีเนื้อหาจริง
  หน้า ~8–11) แต่สารบัญหน้า 2 กลับเรียก System Architecture ว่า "บทที่ 2"
  แล้วไม่มีชื่อบท "กลุ่มเป้าหมายและแนวทาง" อยู่ในสารบัญเลย
- สารบัญไม่มีรายการของ "บทที่ 5: แผนรับมือ Negative case" เลยทั้งบท (เนื้อหา
  จริงอยู่หน้า ~49–51 มี flow ของ GPS fail / CV fail / BLE disconnect / AI
  uncertainty)
- เลขหน้าในสารบัญเพี้ยนหมดทุกบทหลังบท 1 (เช่น สารบัญบอกบทธุรกิจเริ่มหน้า 35
  แต่ในไฟล์จริงเริ่มหน้า ~47 — ห่างกัน 12 หน้า)
- สารบัญภาพก็เพี้ยนตามกัน (อ้างหน้าเดิมจากตอน 44 หน้า)
→ **นี่คือจุดที่ควรแก้ก่อนสุด** เพราะเป็นสิ่งแรกที่กรรมการ/อาจารย์เปิดดู และ
เป็นงานแก้เชิงกลไก (renumber + sync เลขหน้า) ไม่ต้องเขียนเนื้อหาใหม่

**พบเล็กน้อย** — มีคำหลุด "insiaht" (พิมพ์ผิดของ "insight") ลอยอยู่บรรทัดเดี่ยว
หน้าพิมพ์ 19 ก่อนแผนภาพ Process 5.0 Path Recommendation — เป็น note ที่ลืมลบ

### เนื้อหาที่ยังขาด/บางเกินไป (ตอบคำถาม "ควรเพิ่มหัวข้อไหน", 21 ก.ค. 2026)
1. 🔴 **ตัวเลขธุรกิจ** — บท 4 มี Business Model Canvas ครบ 9 box (เช็คแล้วในภาพ
   จริง หน้า 48) แต่ไม่มีย่อหน้าอธิบายเลยทั้งบท (ทุก diagram อื่นในรายงานมี
   คำอธิบายประกอบ 1-2 ย่อหน้า อันนี้ไม่มี) และไม่มีตัวเลขที่เป็นรูปธรรมเลยสัก
   จุด: ราคาขายจริง, ต้นทุน BOM ต่อชุด, กำไรต่อหน่วย, ขนาดตลาด LD ในไทย
   (TAM/SAM/SOM), เป้ารายได้/จำนวนลูกค้าปีแรก — เช็ค grep "บาท/ราคา" แล้วเจอ
   แค่ตอนเทียบ Tesla (1.2-4 ล้านบาท) ไม่มีราคาของเราเองเลย
2. 🔴 **หลักฐานการทดสอบ/validation** — บทที่ 1 (หน้า 8) ประกาศไว้ชัดว่าจะวัด
   Navigation accuracy, Reaction time, Missed turns, Visual distraction,
   Cognitive workload, User confidence แต่ทั้ง 54 หน้าไม่มีตอนไหนกลับมาพูดถึง
   testing methodology, จำนวน/ลักษณะผู้เข้าร่วมทดสอบที่มี LD จริง, หรือผลลัพธ์
   เบื้องต้นเลย — เป็นช่องว่างใหญ่สุดเพราะรายงานเองสัญญาไว้แล้วไม่ส่งมอบ
3. 🟠 **Privacy/PDPA** — ระบบส่ง heart rate + ตำแหน่ง GPS ต่อเนื่อง + ประเภท LD
   ขึ้น Firebase ตลอด แต่ไม่มีย่อหน้าไหนพูดถึงการขอ consent, PDPA (กฎหมาย
   คุ้มครองข้อมูลส่วนบุคคลไทย), การเก็บ/ลบข้อมูล หรือใครเข้าถึง shared
   Landmark DB ได้บ้าง — grep "PDPA/privacy/consent/ยินยอม" ไม่เจอเลยสักคำ
4. 🟡 **Liability/กฎระเบียบ** — อุปกรณ์แจ้งเตือนขณะขับจริง (safety-critical)
   แต่ไม่มีพูดถึงมาตรฐานที่เกี่ยวข้อง, ข้อจำกัดความรับผิด, หรือประเด็นกรมการขนส่ง
   สำหรับอุปกรณ์ aftermarket เลย
5. 🟡 ส่วน "Demo prototype" (หน้า 21) บางไป มีแค่ 2 ย่อหน้าเรื่อง L/R marker —
   ยังไม่พูดถึงอายุแบต, การกันน้ำ/เหงื่อ, รอบชาร์จ, ความกระชับกับข้อมือหลายขนาด

## ★★ ผล audit รายงานฉบับเต็ม (อ่านครบ 44 หน้า, 14 ก.ค. 2026) — เวอร์ชันเก่ากว่า

> ⚠️ **RE-CHECK 17 ก.ค. 2026 — เปิด PDF จริงอีกรอบ (แปลงเป็นภาพทีละหน้าตรวจ)
> พบว่าโน้ตเก่าที่บอกว่า "สไลด์แก้เสร็จแล้ว" ไม่ตรงกับไฟล์ปัจจุบัน**
> อินโฟกราฟิก "AI Architecture Across System Layers" (หน้า 6, หัวข้อ 2.1)
> ยังมีปัญหาเดิมอยู่ครบ:
> - Layer 1 หัวข้อย่อยยังเขียน "AI ที่ใช้" ครอบ Motion Artifact Removal
>   (มีคำ "Signal Processing (Filter)" กำกับไว้ข้างๆ แล้ว แต่หัวคอลัมน์ยังไม่เปลี่ยน)
> - Layer 2 ยังเขียน "Navigation Engine (Fusion): **Rule + ML Fusion
>   Model**" — ขัดกับเนื้อในที่เขียนเองว่าเป็น "โมเดลคณิตศาสตร์ Weighted
>   Sensor Fusion" (ไม่ใช่ ML)
> - Layer 2 ยังเขียน "**Action Dispatcher AI** / Intent Routing Model" —
>   ตัว dispatcher จริงคือ lookup table ส่งต่อคำสั่ง ไม่ใช่ AI
> - Layer 4 Firebase ยังเขียน "**ML**/Sync Service" — Firebase ไม่ได้ทำ ML
>   ในระบบนี้ ควรเป็นแค่ "Data & Sync Service"
> **สรุป: ยังไม่มีจุดไหนถูกแก้จริงในไฟล์ PDF นี้ — ต้องแก้ทั้ง 4 จุดก่อนพรีเซนต์ครั้งหน้า**
> **ยังค้างเพิ่ม**: hardware erratum (หน้า 2.8 ~น.13-14 ยังเขียน ESP32 เฉยๆ +
> DRV2605L+LRA + MAX30102/LSM6DS3 ตัวเต็ม; ของจริงคือ ESP32-C3 Super Mini +
> AH024 PWM + GY-MAX30102 + MPU6050 — ดูตาราง ★★ ด้านบน) — ยืนยันแล้วว่ายังไม่แก้

**คำตัดสินรวม: เนื้อในรายงานสอบผ่าน — ปัญหาส่วนใหญ่อยู่ที่สไลด์สรุป
("AI Architecture Across System Layers") ที่ย่อจนเคลมเกินเนื้อใน**

### จุดที่ต้องแก้ (เรียงตามความเสี่ยงโดนกรรมการเจาะ)
1. 🔴 สไลด์ Layer 1: **"Motion Artifact Removal" อยู่ใต้หัว "AI ที่ใช้"** —
   รายงานเองเรียก adaptive filtering (= DSP ไม่ใช่ ML) → ย้ายออกจากคอลัมน์ AI
   หรือเปลี่ยนหัวเป็น "AI & Signal Processing"
2. 🟠 **หน้า Hardware 2.8 ตกยุค** — ยังเขียน DRV2605L + LRA; ของจริงคือ
   AH024 PWM (ดูตาราง ★★ ด้านบน) → ต้องมี erratum ก่อนนำเสนอครั้งหน้า
3. 🟡 สไลด์: "Action Dispatcher **AI** / Intent Routing **Model**" — ตัว dispatcher
   เป็นตารางส่งต่อคำสั่ง (AI จริงคือ Gemini ที่อยู่ก่อนหน้า) → ตัดคำ AI/Model
4. 🟡 สไลด์: "Rule + **ML** Fusion Model" ขัดกับเนื้อในที่เขียนเองว่า
   "โมเดล**คณิตศาสตร์** Weighted Sensor Fusion" → ใช้คำของรายงานเอง

### จุดที่เคยสงสัยแต่รายงานอธิบายไว้แล้ว (ไม่ต้องแก้)
- **Path Recommender "AI"** — ป้องกันได้: pipeline มี Gemini landmark hint
  ("เลี้ยวซ้ายตรงปั๊ม PTT", cache ด้วย route hash) + `history_hit_rate`
  ที่อัปเดตจากพฤติกรรมจริงทุกทริป → เรียก "AI-assisted" ได้อย่างมีเหตุผล
- **Haptic Controller (Process 4.0) ไม่เคลม AI เลย** ✅ และระบุว่า
  ทิศทางสั่นมาจาก maneuver ของ Google Maps step — ตรงกับ safety invariant
  ที่ใช้ในโค้ดแอปเป๊ะ (`wristForManeuver()`)
- ตารางคู่แข่ง "AI ✅ 6 layers" — ใช้ได้ถ้าตอบตามสคริปต์ล่างนี้

### สคริปต์ตอบกรรมการ (อ้างอิงจากรายงานเองได้ทุกคำ)
> "ใน 6 ชั้น มี 4 ชั้นเป็น ML แท้ — YOLO, LSTM, HAPU (K-Means + Collaborative
> Filtering), Whisper/Gemini — อีก 2 ชั้น (Fusion, LD Score) เป็นโมเดล
> คณิตศาสตร์ที่รับข้อมูลจาก AI และเรียนจากพฤติกรรมผู้ใช้ (yolo_conf,
> history_hit_rate) เราจงใจไม่ให้ ML ตัดสินจุดปล่อยสัญญาณซ้าย/ขวา
> เพราะเป็นจุด safety-critical ที่ต้องพิสูจน์ได้ 100%"

### ตัวเลขสำคัญจากรายงาน (กันเปิด PDF ใหม่)
- readiness = 0.50·gps + 0.35·yolo_conf + 0.15·speed → PREP >0.40 @500m,
  PULSE >0.60 @200m, URGENT >0.80 @50m, CONFIRM (YOLO ยืนยัน) >0.90
- LD Score = 0.35·(1/turns) + 0.25·(1−complexity) + 0.25·landmark_density
  + 0.15·history_hit_rate
- HAPU: EMA α=0.3 ทุกทริป; K-Means (sensitive/standard/robust) เมื่อครบ 10
  ทริป; Cold start = Cosine similarity Top-3 เฉลี่ย
- Stress: LSTM, input 30 timestep × 4 features (heart_rate, acc x/y/z),
  เครียดเกิน threshold → ลด intensity 30% + rhythm นุ่มลง
- YOLO เปิดเฉพาะใกล้จุดเลี้ยว 500m, confidence threshold 0.5, ยืนยันใน 50m (ตารางข้างบนคือสเปคทางทฤษฎีตามรายงาน — ดู 3b สำหรับ BOM ที่ใช้ทำต้นแบบจริง)

## 3b. BOM ต้นแบบ (Prototype) — เปลี่ยนจากสเปครายงาน 10 ก.ค. 2569
เหตุผล: ของตามสเปคทฤษฎี (ชิ้นละ) **หาซื้อยาก/แพง/ต่อสายยาก** จึงสลับเป็นอุปกรณ์ที่หาได้จริงในไทยและเสียบต่อง่ายกว่า **ใช้เฉพาะเวอร์ชัน prototype เท่านั้น** — เวอร์ชันผลิตจริงอาจกลับไปใช้สเปคทฤษฎีในข้อ 3 ถ้าจำเป็น (เช่น LRA/DRV2605L ให้ dynamic intensity ละเอียดกว่า)

| หมวดหมู่ | แผนเดิม (ทฤษฎี/รายงาน) | แผนใหม่ (Prototype) | เหตุผลที่เปลี่ยน |
|---|---|---|---|
| บอร์ดควบคุมหลัก | XIAO ESP32-C3 หรือ S3 (~311–540 บาท) | **ESP32-C3 Super Mini + TP4056** (ชาร์จแบต, รวม ~150 บาท) | ประหยัดงบกว่าครึ่ง ได้พลังประมวลผล+BLE เพียงพอเท่ากัน |
| เซ็นเซอร์วัดชีพจร | MAX30102 รุ่นปกติ (บอร์ดแดง 7 ขา) | **GY-MAX30102** (บอร์ดม่วง 5 ขา) | ชิปตัวเดียวกัน แต่แผงวงจรออกแบบดีกว่า ตัดขาที่ไม่จำเป็นออก เสียบสายง่าย ไม่สับสน |
| เซ็นเซอร์การเคลื่อนไหว | MPU6050 หรือ LSM6DS3 ทั่วไป | **MPU6050** (รุ่น MPU-6050-S) | ชิปรุ่นใหม่ประหยัดแบตกว่า มี buffer เก็บข้อมูลในตัว ลดภาระ ESP32 ไม่ต้องตื่นรับข้อมูลบ่อย |
| ระบบสั่นเตือน | ชิป DRV2605L + LRA Motor (หาซื้อยาก, แพง, ต่อสายยาก) | **โมดูลมอเตอร์สั่น AH024** (ไม่ต้องมี DRV2605L แล้ว) | เสียบจัมเปอร์แค่ 3 เส้น ไม่บัดกรี ไม่ต้องต่อ I2C ปรับความแรงผ่านโค้ด PWM ได้เหมือนเดิม |

**รายการสั่งซื้อขั้นสุดท้าย (Plug & Play, 5 ชิ้นหลัก):** ESP32-C3 Super Mini (+ TP4056 เมื่อจะต่อแบต Li-Po ภายหลัง), GY-MAX30102 (ม่วง), MPU6050 (ม่วง), AH024 Vibration Motor Module, Breadboard + สายจัมเปอร์

> ⚠ ข้อควรเช็ค: เอกสารต้นฉบับที่ส่งมาเขียนสรุปรายการซื้อท้ายเอกสารว่า "LSM6DS3 (สีม่วง)" แต่ตารางเปรียบเทียบด้านบน (ซึ่งมีเหตุผลละเอียดกว่า) ระบุว่าเปลี่ยนเป็น **MPU6050** — สองจุดนี้ขัดกันเอง ยึดตามตารางไว้ก่อน แต่ควรเช็คให้ชัวร์ก่อนสั่งของจริงว่าจะใช้ตัวไหน

## 4. สถาปัตยกรรม AI 6 ชั้น (หัวใจที่ทำให้ต่างจากคู่แข่ง)
1. **YOLOv8** (CNN) — object detection จาก dashcam realtime, ยืนยันจุดเลี้ยวด้วยวัตถุจริง (เช่น ปั๊ม PTT, 7-Eleven) ไม่ใช่แค่ GPS
2. **Navigation Fusion Engine** — รวม GPS + speed + yolo_conf → `readiness = 0.50·gps + 0.35·yolo_conf + 0.15·speed`; ออก event: **PREP(500m) / PULSE(200m) / URGENT(50m) / CONFIRM(double-tap)**
3. **HAPU** (Haptic Adaptive Personalization Unit) — ปรับสั่นเฉพาะบุคคล: **EMA** (α=0.3 อัปเดตทุกทริป) + **K-Means** (ครบ 10 ทริป → จัดกลุ่ม sensitive/standard/robust) + **Collaborative Filtering** (Cosine sim, แก้ cold start ผู้ใช้ใหม่)
4. **Stress Detection** — **LSTM** วิเคราะห์ heart_rate + acc_x/y/z (30 timestep × 4 feature) → stress_level 0–1; ถ้าเครียด ลด intensity 30% + rhythm นุ่มลง realtime
5. **AI Path Recommender** — คำนวณ **LD Score** = `0.35·(1/turns) + 0.25·(1-complexity) + 0.25·landmark_density + 0.15·history_hit_rate` → แนะนำเส้นทาง LD-Friendly
6. **NLP Voice** — **Whisper** (STT ไทย on-device, wake word "เฮ้ ไดรฟ์") → **Gemini** (LLM วิเคราะห์ intent → JSON) → Action Dispatcher → module + **Flutter TTS** ตอบกลับ

Haptic flow: intensity คูณ user pref → packet **7 bytes** ผ่าน **BLE** → ESP32 → PWM → DRV2605L → LRA สั่น

## 5. เทคสแตกซอฟต์แวร์ (จาก Tech_Plan)
Dart + **Flutter** / Riverpod 3 / **flutter_blue_plus** (BLE) / **Mapbox หรือ Google Maps** Directions API + geolocator / **Firebase** (Auth+Firestore) + **SQLite local** (ทำงาน offline ได้) / go_router / flutter_local_notifications
- ภายนอก: Google Maps Directions/Places API, **Gemini API** (landmark hint + intent, มี cache ด้วย route hash ประหยัด quota)
- เครื่องมือ: Android Studio/VS Code, Git+GitHub, Figma, flutter_test + mocktail (mock BLE)

## 6. โฟลว์ผู้ใช้ 4 เฟส + หน้าจอแอป
เฟส: (1) ตั้งค่าเริ่มต้น+calibration → (2) ก่อนเดินทาง เลือกเส้นทาง LD-Friendly → (3) ระหว่างขับ สั่นนำทาง+สั่งเสียง+re-route อัตโนมัติ → (4) หลังทริป survey 5 ข้อ (<30 วิ) → HAPU ปรับ profile
หน้าจอ: Login, Register (เลือก LD type / "I'm not sure" → แบบสอบถาม 6 ข้อ), Home (favorites+ไมค์), Assessment Results (แถบ %), Devices (Connect/Test Vibration), Connecting/Success (แบต+สัญญาณ L/R), Test Vibration (calibrate 5 ระดับ), Account/Settings (haptic prefs, confirm style), Pick Route (MOST LD-FRIENDLY), Active Navigation, Quick Survey

## 7. คู่แข่ง & จุดต่าง
- ตรง: **Wayband** (สายรัดนำทางคนตาบอด เดินเท้า, ไม่มี AI/personalize), **Lechal** (รองเท้าสั่น—อันตรายตอนขับ)
- อ้อม: Google/Apple Maps (เสียง/ภาพ), Tesla ADAS (แพง ไม่เจาะ LD), Car Lane-Departure Haptics (แค่เตือน ไม่นำทาง)
- **จุดต่าง = ผสาน AI 6 ชั้นในอุปกรณ์เดียว + เจาะ LD + ราคาหลักพัน (aftermarket ติดรถไหนก็ได้)**

## 8. สถานะปัจจุบัน
แอปเวอร์ชันแรกรันได้ ใช้ **mock** ของ BLE/maps/cloud (ทดสอบบนแล็ปท็อปได้โดยไม่ต้องมีฮาร์ดแวร์) — ทำ auth, assessment, "เชื่อม" สายรัด+test buzz ได้แล้ว. ขั้นต่อไป: ต่อ BLE/GPS/cloud จริง + สร้าง Haptic Engine loop จริง
**Dependency ใหญ่สุดที่ยังต้องเคลียร์:** นิยาม BLE protocol ของ firmware (service/characteristic UUID + ความหมายของ 7-byte packet)
