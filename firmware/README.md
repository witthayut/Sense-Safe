# Sense&Safe — Wristband Firmware

โค้ด Arduino สำหรับสายรัดข้อมือ ESP32-C3 ทั้งสองข้าง (ซ้าย + ขวา)

> **ทำไมอยู่ในโฟลเดอร์นี้:** repo นี้ (`Sense-Safe`) เก็บทั้งแอปและ firmware ไว้ด้วยกัน
> เพราะทั้งสองฝั่งต้องตกลง **BLE packet format เดียวกัน** — อยู่ที่เดียวกันแปลว่า
> แก้ทั้งสองฝั่งใน commit เดียวได้ และ protocol จะไม่มีวันหลุดจากกัน
> firmware **ไม่เคย** อยู่ใน `lib/` (นั่นเป็นของ Dart เท่านั้น)

---

## โครงสร้าง

```
firmware/
  README.md              ← ไฟล์นี้ (ตั้งค่าบอร์ด + การต่อสาย)
  PROTOCOL.md            ← ยังไม่มี — งานชิ้นแรก (issue #9)
                            UUID ของ service/characteristic + ความหมายของ 7 ไบต์
  wristband/             ← sketch จริง (ยังว่าง — รอ #10)
    wristband.ino
  test/
    motor_test/
      motor_test.ino     ← ✅ พร้อมใช้: ทดสอบว่าฮาร์ดแวร์รอด ยังไม่ยุ่งกับ BLE
```

> ⚠️ **กฎของ Arduino:** ชื่อโฟลเดอร์ต้องตรงกับชื่อไฟล์ `.ino` เป๊ะๆ
> (`motor_test/motor_test.ino`) ถ้าไม่ตรง Arduino IDE จะเปิดไม่ขึ้น

---

## ลำดับงานที่แนะนำ

| # | งาน | ทำไมลำดับนี้ |
|---|---|---|
| **0** | **`test/motor_test` — ทำให้มอเตอร์สั่นให้ได้ก่อน** | พิสูจน์ว่าบอร์ด สายไฟ และมอเตอร์ใช้ได้จริง ถ้าของเสียให้รู้ตอนนี้ ไม่ใช่ตอน debug BLE |
| 1 | `PROTOCOL.md` (issue #9) | ตกลงสัญญาก่อนเขียนโค้ดสองฝั่ง |
| 2 | `wristband.ino` — BLE advertise + connect (#10) | ให้แอปมองเห็นสายรัดก่อน |
| 3 | รับ packet → สั่งมอเตอร์ (#11) | ต่อท่อให้ครบ |
| 4 | เปลี่ยน `BleController` ในแอปเป็น BLE จริง (#12) | ฝั่ง Dart |

ขั้นที่ 0 ใช้เวลาไม่เกิน 20 นาที และไม่ต้องรอ PROTOCOL.md

---

## ตั้งค่า Arduino IDE (ครั้งแรกครั้งเดียว)

1. **ติดตั้ง ESP32 core** — `File → Preferences → Additional boards manager URLs` ใส่:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
   แล้วไป `Tools → Board → Boards Manager` ค้น **esp32** (by Espressif Systems) → Install

2. **เลือกบอร์ด** — `Tools → Board → ESP32 Arduino` → **ESP32C3 Dev Module**
   (ถ้า core เวอร์ชันใหม่มี "ESP32C3 Super Mini" ให้เลือกอันนั้นแทน)

3. **ตั้งค่าที่ต้องแก้** (สำคัญมากสำหรับบอร์ด Super Mini):
   | ตัวเลือก | ค่า | ทำไม |
   |---|---|---|
   | **USB CDC On Boot** | **Enabled** | ถ้าไม่เปิด `Serial.print()` จะไม่ออกอะไรเลยทาง USB — เป็นปัญหาที่คนติดกันมากที่สุด |
   | Flash Size | 4MB | ค่ามาตรฐานของบอร์ดนี้ |
   | Upload Speed | 921600 | ถ้า upload fail ให้ลดเหลือ 115200 |

4. **ถ้า upload ไม่ผ่านครั้งแรก** — กดปุ่ม **BOOT ค้างไว้** แล้วแตะ **RESET** หนึ่งที
   ปล่อย BOOT แล้วค่อยกด Upload (บอร์ดจะเข้าโหมด bootloader)

---

## การต่อสาย (สำหรับ `motor_test`)

**AH024 — โมดูลมอเตอร์สั่น (3 ขา)**

| ขาบนโมดูล | ต่อไปที่ ESP32-C3 Super Mini |
|---|---|
| `VCC` / `+` | **5V** (หรือ `3V3` ถ้าไม่มีขา 5V — จะสั่นเบากว่า) |
| `GND` / `−` | **GND** |
| `IN` / `SIG` / `S` | **GPIO 4** |

> ถ้าคุณต่อขาสัญญาณไว้ที่ GPIO อื่น ให้แก้บรรทัด `MOTOR_PIN` ใน `motor_test.ino`
>
> **ห้ามใช้** GPIO 9 (ปุ่ม BOOT) และ GPIO 8 (LED บนบอร์ด) เป็นขามอเตอร์

**เริ่มจากบอร์ดเดียวก่อน** — ต่อ ESP32 ตัวเดียว + มอเตอร์ตัวเดียว ให้ผ่านก่อน
แล้วค่อยทำตัวที่สอง ยังไม่ต้องต่อ MPU-6050 / MAX30102 / แบตในขั้นนี้

---

## ซ้าย vs ขวา — ใช้ sketch เดียว

บอร์ดสองตัวรันโค้ดชุดเดียวกัน ต่างกันแค่บรรทัดเดียว ตอนจะแฟลชแต่ละตัวให้แก้
`config.h` (จะมีในขั้นที่ 2):

```cpp
#define WRIST_SIDE 'L'   // เปลี่ยนเป็น 'R' ก่อนแฟลชบอร์ดอีกตัว
```

**อย่าสร้างเป็นสอง sketch แยกกัน** — โค้ดจะ drift ออกจากกันแน่นอน และนี่คือ
โค้ด safety-critical ที่ตัดสินว่าข้อมือข้างไหนสั่น

**ติดสติกเกอร์ L / R บนตัวบอร์ดทันทีหลังแฟลชเสร็จ** ไม่งั้นจะแยกไม่ออกว่าตัวไหนเป็นตัวไหน

---

## ความเชื่อมโยงกับฝั่งแอป

ตอนนี้แอปยังใช้ BLE จำลองอยู่ที่ [`lib/services/ble_controller.dart`](../lib/services/ble_controller.dart)
เมธอดที่ firmware ต้องรองรับมีแค่สองตัว:

```dart
pulse(wrist, intensity: 0.0–1.0, durationMs: int)   // สั่งสั่นหนึ่งครั้ง
testVibration(wrist, intensity)                      // ปุ่ม Test บนหน้า Devices
```

`intensity` ฝั่ง Dart เป็น `0.0–1.0` → ฝั่ง firmware แปลงเป็น **PWM duty `0–255`**
(ตามที่บันทึกไว้ใน `PROJECT_BRIEF.md` หัวข้อ ★★)

รูปแบบการสั่นจริงของแต่ละ cue อยู่ที่ [`lib/services/haptic_cue_player.dart`](../lib/services/haptic_cue_player.dart)
— `motor_test.ino` เล่นแพตเทิร์นชุดเดียวกันนี้ให้ลองรู้สึกดูบนฮาร์ดแวร์จริง
