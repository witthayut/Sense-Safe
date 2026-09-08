/*
 * Sense&Safe — haptic_calibrate
 * -----------------------------
 * Measures the three numbers the BLE protocol design needs, on a real wrist:
 *
 *   1. Perception floor   — the lowest PWM duty that can actually be FELT.
 *                           Measured 3 times and averaged, because a single
 *                           trial is not a measurement.
 *   2. Comfortable level  — method of adjustment: the user tunes it live.
 *   3. Pattern separation — a BLIND test. The sketch plays PREP/ALERT/NOW in
 *                           random order and the user guesses. Self-report
 *                           ("do they feel different?") is worthless here,
 *                           because knowing what is coming makes anything
 *                           feel different. Only a score beats that bias.
 *
 * Wiring: AH024 VCC -> 5V, GND -> GND, IN -> GPIO 4  (same as motor_test)
 * Serial Monitor at 115200, line ending "Newline" or "Both NL & CR".
 *
 * STRAP THE MOTOR TO THE INSIDE OF YOUR WRIST BEFORE STARTING.
 * A motor loose on a desk is measuring the desk, not your skin.
 */

const int MOTOR_PIN = 4;
const int LED_PIN   = 8;

// ---------------------------------------------------------------- results
int  floorDuty      = -1;   // test 1
int  comfortDuty    = -1;   // test 2
int  blindCorrect   = -1;   // test 3
const int BLIND_TRIALS      = 9;
const int FLOOR_ASC_TRIALS  = 3;
const int FLOOR_DESC_TRIALS = 2;

// ---------------------------------------------------------------- helpers

int dutyFor(float intensity) {
  if (intensity < 0) intensity = 0;
  if (intensity > 1) intensity = 1;
  return (int)(intensity * 255.0f + 0.5f);
}

void motor(int duty) { analogWrite(MOTOR_PIN, duty); }

void drain() { while (Serial.available()) Serial.read(); }

/// Wait up to ms, returning true early if the user pressed anything.
bool waitOrKey(int ms) {
  unsigned long t0 = millis();
  while (millis() - t0 < (unsigned long)ms) {
    if (Serial.available()) { drain(); return true; }
    delay(5);
  }
  return false;
}

/// Block until the user sends a character; return the first one.
char waitKey() {
  while (!Serial.available()) delay(10);
  char c = Serial.read();
  delay(30);
  drain();
  return c;
}

void buzz(int duty, int ms) {
  motor(duty);
  delay(ms);
  motor(0);
}

// ---------------------------------------------------------------- test 1

/// One pulse cycle at `duty`. Returns true if the user pressed during it.
/// Pulsed rather than continuous: continuous vibration numbs the skin within
/// seconds and drags the measured threshold upward.
bool pulseCycle(int duty) {
  motor(duty);
  if (waitOrKey(250)) { motor(0); return true; }
  motor(0);
  return waitOrKey(300);
}

/// ASCENDING trial — start silent, rise until "I feel it".
/// Biased HIGH by reaction time: you press ~0.3 s after noticing, by which
/// point the staircase has already climbed a step.
int ascendTrial() {
  Serial.println("    (ขาขึ้น) กด Enter ทันทีที่ 'เริ่มรู้สึก'");
  delay(2000);
  drain();
  for (int duty = 0; duty <= 255; duty += 5) {
    if (pulseCycle(duty)) return duty;
  }
  motor(0);
  return -1;
}

/// DESCENDING trial — start clearly felt, fall until "I lost it".
/// Biased LOW for the mirror-image reason. Averaging the two directions
/// cancels most of the reaction-time error: this is the classic method of
/// limits, and it is why one direction alone is not a measurement.
int descendTrial(int startDuty) {
  if (startDuty > 255) startDuty = 255;
  Serial.println("    (ขาลง) กด Enter ทันทีที่ 'หยุดรู้สึก'");
  delay(2000);
  drain();
  for (int duty = startDuty; duty >= 0; duty -= 5) {
    if (pulseCycle(duty)) return duty;
  }
  motor(0);
  return 0;
}

/// CATCH trial — the motor never runs. Pressing here means the answers are
/// guesses, not sensations, and the whole session has to be redone.
bool catchTrial() {
  Serial.println("    (รอบนี้เหมือนเดิม) กด Enter เมื่อรู้สึก");
  delay(2000);
  drain();
  for (int i = 0; i < 12; i++) {
    if (pulseCycle(0)) return true;   // duty 0 = silent throughout
  }
  return false;
}

void testFloor() {
  Serial.println("\n=============================================");
  Serial.println(" [1] หาค่าต่ำสุดที่รู้สึกได้ (method of limits)");
  Serial.println("=============================================");
  Serial.println(" 3 รอบขาขึ้น + 2 รอบขาลง + 1 รอบหลอก");
  Serial.println();
  Serial.println(" ** ก่อนเริ่ม ทำ 3 อย่างนี้ให้เหมือนกันทุกครั้งที่วัด **");
  Serial.println("   1. รัดสายให้แน่น (สอดนิ้วได้ 1 นิ้ว ไม่มากกว่านั้น)");
  Serial.println("   2. วางมอเตอร์ตรงข้อมือด้านใน ตำแหน่งเดิมทุกครั้ง");
  Serial.println("   3. วางแขนนิ่งบนโต๊ะ อย่าเกร็ง");
  Serial.println();
  Serial.println(" กด Enter เพื่อเริ่ม...");
  waitKey();

  int asc[FLOOR_ASC_TRIALS], desc[FLOOR_DESC_TRIALS];
  int nAsc = 0, nDesc = 0;
  bool cheated = false;
  int est = 150;   // rough start for the first descent, refined below

  // Five real trials in a fixed A/D alternation (an ascent always comes
  // first, so the descents have an estimate to start from), with the catch
  // trial dropped in at a RANDOM position each run.
  //
  // The position must never be predictable — and must never be written down
  // anywhere the person being measured can read it. A catch trial whose
  // location is known measures nothing at all.
  randomSeed(micros());
  const char* real = "ADADA";
  char order[7];
  int catchPos = random(1, 6);          // 1..5, never the opening trial
  for (int i = 0, r = 0; i < 6; i++) {
    order[i] = (i == catchPos) ? 'C' : real[r++];
  }
  order[6] = '\0';

  for (int i = 0; order[i]; i++) {
    Serial.printf("\n  -- ช่วงที่ %d/6 --\n", i + 1);
    switch (order[i]) {
      case 'A': {
        int d = ascendTrial();
        if (d < 0) { Serial.println("    ไม่รู้สึกเลยแม้ที่ 255 (เช็คสายไฟ)"); }
        else { Serial.printf("    -> %d\n", d); asc[nAsc++] = d; est = d; }
        break;
      }
      case 'D': {
        int d = descendTrial(est + 60);
        Serial.printf("    -> %d\n", d);
        desc[nDesc++] = d;
        break;
      }
      case 'C': {
        if (catchTrial()) { cheated = true; Serial.println("    !! กดในรอบหลอก"); }
        else Serial.println("    -> ผ่าน (ไม่กด)");
        break;
      }
    }
    Serial.println("    พัก 3 วิ ให้ผิวหนังคลายตัว...");
    delay(3000);
  }

  if (nAsc == 0) { Serial.println("\n วัดไม่ได้"); return; }

  int sum = 0, lo = 999, hi = -1;
  for (int i = 0; i < nAsc;  i++) { sum += asc[i];  lo = min(lo, asc[i]);  hi = max(hi, asc[i]); }
  for (int i = 0; i < nDesc; i++) { sum += desc[i]; lo = min(lo, desc[i]); hi = max(hi, desc[i]); }
  int n = nAsc + nDesc;
  floorDuty = sum / n;
  int spread = hi - lo;

  Serial.println("\n  ---------------------------------------");
  Serial.printf("   ค่าเฉลี่ยรวม = duty %d  (intensity %.2f)\n",
                floorDuty, floorDuty / 255.0f);
  Serial.printf("   กระจายตัว    = %d ถึง %d  (ห่างกัน %d)\n", lo, hi, spread);

  if (cheated) {
    Serial.println("   !! กดในรอบหลอก -> ข้อมูลชุดนี้เชื่อไม่ได้ วัดใหม่");
  } else if (spread <= 15) {
    Serial.println("   สถานะ: เสถียร - ใช้ค่านี้ได้");
  } else if (spread <= 30) {
    Serial.println("   สถานะ: พอใช้ - ควรวัดซ้ำอีกรอบคนละวัน");
  } else {
    Serial.println("   สถานะ: ไม่เสถียร - สายรัดน่าจะขยับ ให้รัดแน่นขึ้นแล้ววัดใหม่");
  }
  Serial.println("  ---------------------------------------");
}

// ---------------------------------------------------------------- test 2

void testComfort() {
  Serial.println("\n=============================================");
  Serial.println(" [2] หาค่าที่รู้สึกกำลังดี");
  Serial.println("=============================================");
  Serial.println(" + = แรงขึ้น    - = เบาลง    s = บันทึก");
  Serial.println(" มันจะสั่นเป็นจังหวะไปเรื่อยๆ ปรับจนรู้สึกพอดี");
  Serial.println(" (พอดี = ขับรถอยู่ต้องสังเกตเห็นแน่นอน แต่ไม่ตกใจ)\n");

  int duty = (floorDuty > 0) ? floorDuty + 30 : 128;
  drain();

  while (true) {
    Serial.printf("  duty %3d / 255   (intensity %.2f)\n", duty, duty / 255.0f);
    motor(duty); delay(250); motor(0);

    unsigned long t0 = millis();
    while (millis() - t0 < 700) {
      if (Serial.available()) {
        char c = Serial.read();
        delay(30); drain();
        if (c == '+' || c == '=') { duty += 10; if (duty > 255) duty = 255; }
        else if (c == '-' || c == '_') { duty -= 10; if (duty < 0) duty = 0; }
        else if (c == 's' || c == 'S') {
          comfortDuty = duty;
          Serial.printf("\n  ** บันทึกแล้ว: duty %d **  (intensity %.2f)\n",
                        duty, duty / 255.0f);
          return;
        }
        break;
      }
      delay(5);
    }
  }
}

// ---------------------------------------------------------------- test 3

/// Cue patterns, v2 — redesigned 2026-09-08 after the first wrist
/// measurement on real hardware (floor 135, comfortable 185).
///
/// v1 came straight from lib/services/haptic_cue_player.dart and failed:
///   - PREP was base x 0.5 = 92, which is BELOW the 135 perception floor,
///     so it was not weak, it was physically silent.
///   - ALERT and NOW were both "two pulses" separated only by amplitude
///     (185 vs 249). Usable range on this motor is only 135-255, and skin
///     resolves maybe 2-3 amplitude steps in that span — so they blurred.
///
/// v2 encodes urgency in PULSE COUNT (1 / 2 / 4) instead of amplitude.
/// Counting beats comparing: nobody confuses one tap with four, even while
/// driving. Amplitude and total duration still escalate as backup cues, so
/// three independent dimensions all carry the same message.
///
/// Pulses stay >= 100 ms with >= 80 ms gaps: the AH024 needs time to spin up
/// and stop, and anything faster smears into one continuous buzz.
void playPattern(int which, int base) {
  int mid  = base + 15; if (mid > 255) mid = 255;
  const int hard = 255;

  switch (which) {
    case 0:  // PREP — ONE long tap ("a turn is coming")
      buzz(base, 250);
      break;
    case 1:  // ALERT — TWO taps ("turn soon")
      buzz(mid, 150); delay(130); buzz(mid, 150);
      break;
    case 2:  // NOW — FOUR fast taps at full power ("turn NOW")
      for (int i = 0; i < 4; i++) { buzz(hard, 100); if (i < 3) delay(80); }
      break;
  }
}

void testBlind() {
  Serial.println("\n=============================================");
  Serial.println(" [3] ทดสอบแยกแพตเทิร์นแบบปิดตา (9 ครั้ง)");
  Serial.println("=============================================");
  Serial.println(" ระบบจะสุ่มเล่น 1 ใน 3 แบบ แล้วให้คุณทาย");
  Serial.println("   1 = PREP  (เตรียมตัว)");
  Serial.println("   2 = ALERT (ใกล้แล้ว)");
  Serial.println("   3 = NOW   (เลี้ยวเดี๋ยวนี้)");
  Serial.println("\n อย่ามองหน้าจอตอนมันสั่น! ให้ตัดสินด้วยความรู้สึกล้วนๆ");
  Serial.println("\n กด Enter เพื่อเริ่ม...");
  waitKey();

  randomSeed(micros());
  int base = (comfortDuty > 0) ? comfortDuty : 179;
  int correct = 0;

  for (int i = 1; i <= BLIND_TRIALS; i++) {
    int answer = random(3);
    Serial.printf("\n  ครั้งที่ %d/%d — กำลังเล่น...\n", i, BLIND_TRIALS);
    delay(800);
    playPattern(answer, base);
    Serial.println("  ทายเลย (1/2/3):");

    char c = waitKey();
    int guess = c - '1';
    bool right = (guess == answer);
    if (right) correct++;

    const char* names[] = {"PREP", "ALERT", "NOW"};
    Serial.printf("  %s  (คำตอบ: %s)\n", right ? "ถูก" : "ผิด", names[answer]);
  }

  blindCorrect = correct;
  Serial.printf("\n  ** คะแนน %d/%d **\n", correct, BLIND_TRIALS);
  Serial.println("  (เดามั่วจะได้ราวๆ 3/9 — ต่ำกว่า 6 ถือว่าแยกไม่ออกจริง)");
}

// ---------------------------------------------------------------- summary

void summary() {
  Serial.println("\n#############################################");
  Serial.println("  สรุปผล — ก๊อปทั้งบล็อกนี้ส่งให้ Claude");
  Serial.println("#############################################");

  if (floorDuty > 0)
    Serial.printf("1. duty ต่ำสุดที่รู้สึกได้ = %d   (intensity %.2f)\n",
                  floorDuty, floorDuty / 255.0f);
  else Serial.println("1. duty ต่ำสุดที่รู้สึกได้ = ยังไม่ได้วัด");

  if (comfortDuty > 0)
    Serial.printf("2. duty ที่กำลังดี        = %d   (intensity %.2f)\n",
                  comfortDuty, comfortDuty / 255.0f);
  else Serial.println("2. duty ที่กำลังดี        = ยังไม่ได้วัด");

  if (blindCorrect >= 0)
    Serial.printf("3. ทดสอบปิดตา            = %d/%d %s\n", blindCorrect, BLIND_TRIALS,
                  blindCorrect >= 6 ? "(แยกออก)" : "(แยกไม่ออก - ต้องแก้ดีไซน์)");
  else Serial.println("3. ทดสอบปิดตา            = ยังไม่ได้วัด");

  Serial.println("#############################################");
}

// ---------------------------------------------------------------- menu

void menu() {
  Serial.println("\n\n=== Sense&Safe — วัดค่าการสั่นบนข้อมือจริง ===");
  Serial.println("  1 = หาค่าต่ำสุดที่รู้สึกได้  (3 รอบ, ~2 นาที)");
  Serial.println("  2 = หาค่าที่กำลังดี");
  Serial.println("  3 = ทดสอบแยกแพตเทิร์นแบบปิดตา (9 ครั้ง)");
  Serial.println("  4 = ดูสรุปผล");
  Serial.println("  แนะนำให้ทำตามลำดับ 1 -> 2 -> 3 -> 4");
  Serial.print("\nเลือก: ");
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  pinMode(MOTOR_PIN, OUTPUT);
  motor(0);
  delay(1500);

  for (int i = 0; i < 3; i++) {          // board-alive blink
    digitalWrite(LED_PIN, LOW);  delay(120);
    digitalWrite(LED_PIN, HIGH); delay(120);
  }
  menu();
}

void loop() {
  if (!Serial.available()) { delay(50); return; }
  char c = waitKey();
  switch (c) {
    case '1': testFloor();   break;
    case '2': testComfort(); break;
    case '3': testBlind();   break;
    case '4': summary();     break;
    default:  return;        // ignore stray newlines
  }
  menu();
}
