/*
 * Sense&Safe — duty_levels
 * ------------------------
 * Every vibration strength the system actually uses, on one wrist, so you
 * can judge for yourself how many of them are really different.
 *
 * The app expresses strength as 0.0-1.0. The firmware maps that onto the
 * motor's usable range, measured on a real wrist (firmware/MEASUREMENTS.md):
 *
 *     duty = FLOOR + intensity * (255 - FLOOR)        FLOOR = 135
 *
 * The twelve fixed levels below are squeezed into 120 duty steps, and skin
 * resolves maybe two or three steps across that span. Several pairs sit 2-7
 * apart. Mode [c] exists to prove which pairs are real and which are
 * bookkeeping: if you cannot tell 183 from 185, the app does not have twelve
 * levels, it has three, and the design should say so.
 *
 * Board:  ESP32-C3 Super Mini   Wiring: AH024 IN -> GPIO 4, VCC -> 5V
 * Serial: 115200, line ending "New Line"
 * Strap the motor to the inside of your wrist before judging anything.
 */

const int MOTOR_PIN = 4;
const int LED_PIN   = 8;

const int FLOOR_DUTY = 135;   // measured 2026-09-08, n=1

struct Level {
  int         duty;
  const char* intensity;
  const char* usedBy;
};

// Ordered weakest to strongest.
const Level LEVELS[] = {
  {135, "0.00 ", "PREP - two taps at 300 m"},
  {165, "0.25 ", "ladder - 250 m, every 4.0 s"},
  {171, "0.30 ", "calibration level 1 of 5"},
  {183, "0.40 ", "ARRIVAL - both wrists"},
  {185, "0.42 ", "ladder - 150 m, every 2.0 s"},
  {192, "0.475", "calibration level 2 of 5"},
  {205, "0.58 ", "ladder - 80 m, every 1.0 s"},
  {213, "0.65 ", "calibration level 3 of 5"},
  {219, "0.70 ", "Devices screen - Test Vibration"},
  {230, "0.79 ", "ladder - 40 m, every 0.5 s"},
  {234, "0.825", "calibration level 4 of 5"},
  {255, "1.00 ", "NOW (below 20 m) + calibration 5 of 5"},
};
const int N_LEVELS = sizeof(LEVELS) / sizeof(LEVELS[0]);

// ---------------------------------------------------------------- helpers

void motor(int duty) { analogWrite(MOTOR_PIN, duty); }

void buzz(int duty, int ms) {
  motor(duty);
  delay(ms);
  motor(0);
}

void drain() { while (Serial.available()) Serial.read(); }

/// Read one line. Returns "" if the user just pressed Enter.
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

// ---------------------------------------------------------------- modes

void printTable() {
  Serial.println("\n  #   intensity   duty   ใช้ที่ไหน");
  Serial.println("  --  ---------   ----   ----------------------------------");
  for (int i = 0; i < N_LEVELS; i++) {
    Serial.printf("  %2d    %s     %3d   %s\n",
                  i + 1, LEVELS[i].intensity, LEVELS[i].duty, LEVELS[i].usedBy);
  }
}

/// Three taps at one level, so you can settle on how it feels.
void playLevel(int idx) {
  const Level& L = LEVELS[idx];
  Serial.printf("\n  [%d] duty %d  (intensity %s)  <- %s\n",
                idx + 1, L.duty, L.intensity, L.usedBy);
  for (int i = 0; i < 3; i++) {
    buzz(L.duty, 250);
    delay(250);
  }
}

/// Walk the whole ladder weakest to strongest.
void playAll() {
  Serial.println("\n=== ไล่ทุกระดับ เบา -> แรง ===");
  Serial.println("สังเกตว่าระดับไหนเริ่มรู้สึกต่างจากระดับก่อนหน้าจริงๆ");
  for (int i = 0; i < N_LEVELS; i++) {
    playLevel(i);
    delay(700);
  }
  Serial.println("\n  จบ");
}

/// A/B every neighbouring pair. This is the mode that matters: it says how
/// many of the twelve levels are distinguishable rather than merely distinct
/// in the source code.
void compareAdjacent() {
  Serial.println("\n=== เทียบทีละคู่ที่อยู่ติดกัน ===");
  Serial.println("แต่ละคู่จะเล่น A แล้ว B  ตอบว่าแยกออกไหม: y = ต่าง / n = เหมือนกัน");
  Serial.println("อย่ามองหน้าจอตอนมันสั่น\n");

  int same = 0, diff = 0;
  for (int i = 0; i + 1 < N_LEVELS; i++) {
    const int a = LEVELS[i].duty;
    const int b = LEVELS[i + 1].duty;

    Serial.printf("  คู่ที่ %2d/%d — ห่างกัน %d duty\n", i + 1, N_LEVELS - 1, b - a);
    delay(600);
    Serial.println("    A ...");
    buzz(a, 400);
    delay(700);
    Serial.println("    B ...");
    buzz(b, 400);

    Serial.print("    แยกออกไหม (y/n): ");
    String ans = readLine();
    ans.toLowerCase();
    bool isDiff = ans.startsWith("y");
    if (isDiff) diff++; else same++;
    Serial.printf("%s   (duty %d vs %d)\n\n", isDiff ? "ต่าง" : "เหมือน", a, b);
  }

  Serial.println("  ---------------------------------------");
  Serial.printf("   แยกออก %d คู่ / เหมือนกัน %d คู่\n", diff, same);
  Serial.printf("   => ระดับที่ใช้ได้จริงประมาณ %d ระดับ จากที่โค้ดมี %d\n",
                diff + 1, N_LEVELS);
  if (diff + 1 < N_LEVELS) {
    Serial.println("   ระดับที่เหลือคือความละเอียดที่ฮาร์ดแวร์แสดงออกมาไม่ได้");
  }
  Serial.println("  ---------------------------------------");
}

/// Free-run any duty you type, for trying values the app does not use yet.
void freeRun() {
  Serial.println("\n=== ลองค่าเอง ===");
  Serial.println("พิมพ์ตัวเลข 0-255 แล้ว Enter  (พิมพ์ q เพื่อออก)");
  while (true) {
    Serial.print("  duty: ");
    String s = readLine();
    if (s.length() == 0) continue;
    s.toLowerCase();
    if (s.startsWith("q")) return;
    int d = s.toInt();
    if (d < 0 || d > 255) { Serial.println("    ต้องอยู่ระหว่าง 0-255"); continue; }
    if (d > 0 && d < FLOOR_DUTY) {
      Serial.printf("    (%d ต่ำกว่าพื้น %d - น่าจะไม่รู้สึก)\n", d, FLOOR_DUTY);
    }
    for (int i = 0; i < 3; i++) { buzz(d, 250); delay(250); }
    Serial.println();
  }
}

// ---------------------------------------------------------------- menu

void menu() {
  Serial.println("\n\n=== Sense&Safe — ความแรงทั้งหมดที่ระบบใช้ ===");
  printTable();
  Serial.println("\n  1-12 = เล่นระดับนั้น 3 ครั้ง");
  Serial.println("  a    = ไล่ทุกระดับ เบา -> แรง");
  Serial.println("  c    = เทียบทีละคู่  <- โหมดที่สำคัญที่สุด");
  Serial.println("  f    = ลองใส่ค่า duty เอง");
  Serial.print("\nเลือก: ");
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  pinMode(MOTOR_PIN, OUTPUT);
  motor(0);
  delay(1500);

  for (int i = 0; i < 3; i++) {            // board-alive blink
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

  if (s.startsWith("a"))      playAll();
  else if (s.startsWith("c")) compareAdjacent();
  else if (s.startsWith("f")) freeRun();
  else {
    int n = s.toInt();
    if (n >= 1 && n <= N_LEVELS) playLevel(n - 1);
    else { Serial.println("  ไม่รู้จักคำสั่งนี้"); }
  }
  menu();
}
