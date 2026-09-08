/*
 * Sense&Safe — turn_approach
 * --------------------------
 * The six stages of approaching one turn, on demand, with live tuning.
 *
 * WHY THE PULSES GOT LONGER (revised after the first wrist test)
 * A vibration motor needs 50-100 ms to spin up to speed. The first pass used
 * 140 ms taps, so most of every tap was spent accelerating and the wearer
 * never felt the strength the duty asked for — it read as "too weak" AND
 * "too short", which are the same complaint. Longer taps feel stronger at
 * the same duty, for free, because the motor actually reaches its rated
 * speed before it is told to stop.
 *
 * Duties were also raised off the 135 floor. That floor was measured sitting
 * still, arm on a desk, concentrating; it is the threshold of perception,
 * not a usable working level.
 *
 * Board:  ESP32-C3 Super Mini   Wiring: AH024 IN -> GPIO 4, VCC -> 5V
 * Serial: 115200, line ending "New Line"
 * Strap the motor to the inside of your wrist first.
 */

const int MOTOR_PIN = 4;
const int LED_PIN   = 8;

// Change to feel the approach at a different speed. 40 km/h is what
// DriveController simulates.
float SPEED_KMH = 40.0;

struct Stage {
  int         atM;         // distance this stage begins
  int         duty;        // 0-255
  int         tapMs;       // length of ONE tap (or the whole buzz for NOW)
  int         gapMs;       // PREP only: silence between its two taps
  int         intervalMs;  // 0 = one-shot, else gap between repeating taps
  const char* label;
};

// Tunable at runtime — mode [t] edits these in place.
Stage STAGES[] = {
  {300, 185, 300, 200,    0, "2 ตุ๊บ — มีทางเลี้ยวข้างหน้า"},
  {250, 200, 350,   0, 4000, "ตุ๊บเดี่ยว ทุก 4 วิ"},
  {150, 220, 350,   0, 2000, "ตุ๊บเดี่ยว ทุก 2 วิ"},
  { 80, 238, 350,   0, 1000, "ตุ๊บเดี่ยว ทุก 1 วิ"},
  { 40, 248, 350,   0,  500, "ตุ๊บเดี่ยว ทุก 0.5 วิ"},
  { 20, 255,1500,   0,    0, "สั่นยาวรวดเดียว — เลี้ยวเดี๋ยวนี้"},
};
const int N_STAGES = 6;
const int PREP = 0, NOW = 5;

// ---------------------------------------------------------------- helpers

void motor(int duty) { analogWrite(MOTOR_PIN, duty); }

void buzz(int duty, int ms) {
  motor(duty);
  delay(ms);
  motor(0);
}

void drain() { while (Serial.available()) Serial.read(); }

String readLine() {
  String s = "";
  while (true) {
    while (!Serial.available()) delay(10);
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (s.length() > 0 || c == '\n') { drain(); return s; }
    } else {
      s += c;
    }
  }
}

bool keyPressed() {
  if (Serial.available()) { drain(); return true; }
  return false;
}

int clampi(int v, int lo, int hi) { return v < lo ? lo : (v > hi ? hi : v); }

// ---------------------------------------------------------------- patterns

void playStagePattern(int idx) {
  const Stage& s = STAGES[idx];
  if (idx == PREP) {
    buzz(s.duty, s.tapMs);
    delay(s.gapMs);
    buzz(s.duty, s.tapMs);
  } else {
    buzz(s.duty, s.tapMs);
  }
}

/// Sit on one stage. Repeating stages loop until you press Enter.
void playStage(int idx) {
  const Stage& s = STAGES[idx];
  Serial.printf("\n  [%d] %d ม.  duty %d  ยาว %d ms  —  %s\n",
                idx + 1, s.atM, s.duty, s.tapMs, s.label);

  if (s.intervalMs == 0) {
    playStagePattern(idx);
    Serial.println("  จบ");
    return;
  }

  Serial.println("  กำลังเล่นซ้ำ... กด Enter เพื่อหยุด");
  drain();
  for (int i = 0; i < 8; i++) {
    playStagePattern(idx);
    unsigned long t0 = millis();
    while (millis() - t0 < (unsigned long)s.intervalMs) {
      if (keyPressed()) { Serial.println("  หยุด"); return; }
      delay(10);
    }
  }
  Serial.println("  จบ (ครบ 8 ครั้ง)");
}

/// Drive the whole approach with a shrinking distance, the way
/// ProximityPulser will deliver it in the app.
void runApproach() {
  Serial.printf("\n=== ขับเข้าหาทางเลี้ยว ที่ %.0f กม./ชม. ===\n", SPEED_KMH);
  Serial.println("กด Enter เพื่อหยุดกลางคัน\n");
  delay(1200);
  drain();

  const float mps = SPEED_KMH / 3.6f;
  bool prepFired = false;
  unsigned long startMs = millis();
  unsigned long lastTap = 0;

  while (true) {
    if (keyPressed()) { motor(0); Serial.println("\n  หยุด"); return; }

    const float dist = 330 - mps * (millis() - startMs) / 1000.0f;

    if (dist <= STAGES[NOW].atM) {
      Serial.printf("   <%d ม.  duty %d  — เลี้ยวเดี๋ยวนี้\n",
                    STAGES[NOW].atM, STAGES[NOW].duty);
      playStagePattern(NOW);
      Serial.println("\n  ถึงทางเลี้ยวแล้ว");
      return;
    }

    if (!prepFired && dist <= STAGES[PREP].atM) {
      Serial.printf("   %d ม.  duty %d  — 2 ตุ๊บ\n",
                    STAGES[PREP].atM, STAGES[PREP].duty);
      playStagePattern(PREP);
      prepFired = true;
      lastTap = millis();
    }

    // Nearest matching rung of the ladder (stages 4 down to 1).
    int rung = -1;
    for (int i = N_STAGES - 2; i >= 1; i--) {
      if (dist <= STAGES[i].atM) { rung = i; break; }
    }

    if (rung > 0 && millis() - lastTap >= (unsigned long)STAGES[rung].intervalMs) {
      Serial.printf("   %3d ม.  duty %d\n", (int)dist, STAGES[rung].duty);
      playStagePattern(rung);
      lastTap = millis();
    }

    delay(20);
  }
}

// ---------------------------------------------------------------- tuning

/// Adjust one stage while feeling it, so the numbers can be settled without
/// a recompile between every guess.
void tuneStage(int idx) {
  Stage& s = STAGES[idx];
  Serial.printf("\n=== ปรับด่านที่ %d (%d ม.) ===\n", idx + 1, s.atM);
  Serial.println("  +  /  -   ความแรง  ±5      (พิมพ์ ++ หรือ -- เพื่อ ±20)");
  Serial.println("  ]  /  [   ความยาว  ±50 ms");
  Serial.println("  <Enter>   เล่นซ้ำ");
  Serial.println("  s         บันทึกแล้วออก\n");

  while (true) {
    Serial.printf("  duty %3d   ยาว %4d ms  >  ", s.duty, s.tapMs);
    playStagePattern(idx);

    String c = readLine();
    if (c.length() == 0) continue;              // Enter = play again
    c.toLowerCase();

    if (c.startsWith("s")) {
      Serial.printf("\n  บันทึก: duty %d, ยาว %d ms\n", s.duty, s.tapMs);
      return;
    }
    if (c == "++")      s.duty  = clampi(s.duty + 20, 0, 255);
    else if (c == "--") s.duty  = clampi(s.duty - 20, 0, 255);
    else if (c[0] == '+') s.duty = clampi(s.duty + 5, 0, 255);
    else if (c[0] == '-') s.duty = clampi(s.duty - 5, 0, 255);
    else if (c[0] == ']') s.tapMs = clampi(s.tapMs + 50, 50, 3000);
    else if (c[0] == '[') s.tapMs = clampi(s.tapMs - 50, 50, 3000);
    else Serial.println("  ใช้ + - ] [ Enter หรือ s");
  }
}

/// Print every current value in a form that can be pasted back into the app.
void dumpValues() {
  Serial.println("\n=== ค่าปัจจุบันทั้งหมด — ส่งบล็อกนี้ให้ Claude ===");
  Serial.println("ระยะ    duty   ยาว(ms)  จังหวะ");
  for (int i = 0; i < N_STAGES; i++) {
    const Stage& s = STAGES[i];
    if (s.intervalMs == 0) {
      Serial.printf("%4d ม.  %3d    %4d     one-shot\n", s.atM, s.duty, s.tapMs);
    } else {
      Serial.printf("%4d ม.  %3d    %4d     ทุก %.1f วิ\n",
                    s.atM, s.duty, s.tapMs, s.intervalMs / 1000.0);
    }
  }
  Serial.println("=================================================");
}

// ---------------------------------------------------------------- menu

void menu() {
  Serial.println("\n\n=== Sense&Safe — ทดสอบการเข้าหาทางเลี้ยว ===\n");
  for (int i = 0; i < N_STAGES; i++) {
    const Stage& s = STAGES[i];
    Serial.printf("  %d = %4d ม.   duty %3d  ยาว %4d ms   %s\n",
                  i + 1, s.atM, s.duty, s.tapMs, s.label);
  }
  Serial.println("\n  r  = ขับเข้าหาทางเลี้ยวทั้งหมด  <- ตัวจริง");
  Serial.println("  t1..t6 = ปรับความแรง/ความยาวของด่านนั้นแบบสด");
  Serial.println("  d  = สรุปค่าปัจจุบันทั้งหมด");
  Serial.print("\nเลือก: ");
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  pinMode(MOTOR_PIN, OUTPUT);
  motor(0);
  delay(1500);

  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, LOW);  delay(120);
    digitalWrite(LED_PIN, HIGH); delay(120);
  }
  menu();
}

void loop() {
  if (!Serial.available()) { delay(50); return; }
  String s = readLine();
  if (s.length() == 0) return;
  s.toLowerCase();

  if (s.startsWith("r")) {
    runApproach();
  } else if (s.startsWith("d")) {
    dumpValues();
  } else if (s.startsWith("t")) {
    int n = s.substring(1).toInt();
    if (n >= 1 && n <= N_STAGES) tuneStage(n - 1);
    else Serial.println("  พิมพ์ t1 ถึง t6");
  } else {
    int n = s.toInt();
    if (n >= 1 && n <= N_STAGES) playStage(n - 1);
    else Serial.println("  พิมพ์ 1-6, r, t1-t6 หรือ d");
  }
  menu();
}
