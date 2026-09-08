/*
 * Sense&Safe — turn_approach
 * --------------------------
 * The six stages of approaching one turn, on demand.
 *
 *   1  300 m   two taps                    duty 135   "a turn is coming"
 *   2  250 m   single tap every 4.0 s      duty 165
 *   3  150 m   single tap every 2.0 s      duty 185
 *   4   80 m   single tap every 1.0 s      duty 205
 *   5   40 m   single tap every 0.5 s      duty 230
 *   6  <20 m   one long unbroken buzz      duty 255   "turn NOW"
 *
 * Press a number to sit on that stage. Press r to drive the whole approach
 * at 40 km/h and feel it the way it will actually arrive — which is the only
 * way to judge whether the escalation reads as one rising signal or as six
 * unrelated buzzes.
 *
 * Board:  ESP32-C3 Super Mini   Wiring: AH024 IN -> GPIO 4, VCC -> 5V
 * Serial: 115200, line ending "New Line"
 * Strap the motor to the inside of your wrist first.
 */

const int MOTOR_PIN = 4;
const int LED_PIN   = 8;

// Change this to feel the approach at a different speed. 40 km/h is the
// value DriveController simulates.
const float SPEED_KMH = 40.0;
const float SPEED_MPS = SPEED_KMH / 3.6;

struct Stage {
  int         atM;         // distance this stage begins
  int         duty;
  int         intervalMs;  // 0 = one-shot, not a repeating tap
  const char* label;
};

const Stage STAGES[] = {
  {300, 135,    0, "2 ตุ๊บ — มีทางเลี้ยวข้างหน้า"},
  {250, 165, 4000, "ตุ๊บเดี่ยว ทุก 4 วิ"},
  {150, 185, 2000, "ตุ๊บเดี่ยว ทุก 2 วิ"},
  { 80, 205, 1000, "ตุ๊บเดี่ยว ทุก 1 วิ"},
  { 40, 230,  500, "ตุ๊บเดี่ยว ทุก 0.5 วิ"},
  { 20, 255,    0, "สั่นยาวรวดเดียว — เลี้ยวเดี๋ยวนี้"},
};
const int N_STAGES = 6;

const int TAP_MS       = 140;   // one approach tap
const int PREP_TAP_MS  = 180;   // PREP is a slightly longer tap
const int PREP_GAP_MS  = 140;
const int NOW_MS       = 800;   // the continuous "turn now" buzz

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

// ---------------------------------------------------------------- patterns

void playPrep() {
  buzz(STAGES[0].duty, PREP_TAP_MS);
  delay(PREP_GAP_MS);
  buzz(STAGES[0].duty, PREP_TAP_MS);
}

void playNow() {
  buzz(STAGES[5].duty, NOW_MS);
}

/// Sit on one stage. Repeating stages run until you press Enter, capped so
/// it can never get stuck.
void playStage(int idx) {
  const Stage& s = STAGES[idx];
  Serial.printf("\n  [%d] %d ม.  duty %d  —  %s\n", idx + 1, s.atM, s.duty, s.label);

  if (s.intervalMs == 0) {
    if (idx == 0) playPrep(); else playNow();
    Serial.println("  จบ");
    return;
  }

  Serial.println("  กำลังเล่นซ้ำ... กด Enter เพื่อหยุด");
  drain();
  for (int i = 0; i < 8; i++) {
    buzz(s.duty, TAP_MS);
    unsigned long t0 = millis();
    while (millis() - t0 < (unsigned long)s.intervalMs) {
      if (keyPressed()) { Serial.println("  หยุด"); return; }
      delay(10);
    }
  }
  Serial.println("  จบ (ครบ 8 ครั้ง)");
}

/// Drive the whole approach with a shrinking distance, exactly the way
/// ProximityPulser will do it in the app.
void runApproach() {
  Serial.printf("\n=== ขับเข้าหาทางเลี้ยว ที่ %.0f กม./ชม. ===\n", SPEED_KMH);
  Serial.println("กด Enter เพื่อหยุดกลางคัน\n");
  delay(1200);
  drain();

  float dist = 330;
  bool prepFired = false;
  unsigned long startMs = millis();
  unsigned long lastTap = 0;
  int lastShown = 999;

  while (true) {
    if (keyPressed()) { motor(0); Serial.println("\n  หยุด"); return; }

    dist = 330 - SPEED_MPS * (millis() - startMs) / 1000.0f;

    if (dist <= 20) {
      Serial.println("   <20 ม.  duty 255  — เลี้ยวเดี๋ยวนี้");
      playNow();
      Serial.println("\n  ถึงทางเลี้ยวแล้ว");
      return;
    }

    if (!prepFired && dist <= 300) {
      Serial.println("   300 ม.  duty 135  — 2 ตุ๊บ");
      playPrep();
      prepFired = true;
      lastTap = millis();
    }

    // Which rung of the ladder are we on?
    int duty = 0, interval = 0;
    if (dist <= 40)       { duty = 230; interval = 500;  }
    else if (dist <= 80)  { duty = 205; interval = 1000; }
    else if (dist <= 150) { duty = 185; interval = 2000; }
    else if (dist <= 250) { duty = 165; interval = 4000; }

    if (duty > 0 && millis() - lastTap >= (unsigned long)interval) {
      Serial.printf("   %3d ม.  duty %d\n", (int)dist, duty);
      buzz(duty, TAP_MS);
      lastTap = millis();
      lastShown = (int)dist;
    }
    (void)lastShown;

    delay(20);
  }
}

// ---------------------------------------------------------------- menu

void menu() {
  Serial.println("\n\n=== Sense&Safe — ทดสอบการเข้าหาทางเลี้ยว ===\n");
  for (int i = 0; i < N_STAGES; i++) {
    Serial.printf("  %d = %4d ม.   duty %3d   %s\n",
                  i + 1, STAGES[i].atM, STAGES[i].duty, STAGES[i].label);
  }
  Serial.println("\n  r = ขับเข้าหาทางเลี้ยวทั้งหมดตั้งแต่ต้นจนจบ  <- ตัวจริง");
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
  } else {
    int n = s.toInt();
    if (n >= 1 && n <= N_STAGES) playStage(n - 1);
    else Serial.println("  พิมพ์ 1-6 หรือ r");
  }
  menu();
}
