/*
 * Sense&Safe — motor_test
 * -----------------------
 * Hardware smoke test for ONE wristband. No BLE, no sensors.
 * Answers three questions before any protocol work starts:
 *
 *   1. Is the board alive and flashable?          -> LED blinks
 *   2. Does the AH024 motor respond to PWM?       -> intensity ramp
 *   3. Are the app's cue patterns distinguishable
 *      on real skin?                              -> pattern playback
 *
 * Board:  ESP32-C3 Super Mini  (Tools > Board > ESP32C3 Dev Module)
 *         Tools > USB CDC On Boot > Enabled   <- required for Serial
 *
 * Wiring: AH024 VCC -> 5V, GND -> GND, IN -> GPIO 4
 *
 * Open Serial Monitor at 115200 and wear the motor against your wrist
 * while it runs — the point is what you FEEL, not what you read.
 */

// ---------------------------------------------------------------- pins
const int MOTOR_PIN = 4;   // AH024 signal pin. Change if you wired elsewhere.
const int LED_PIN   = 8;   // Onboard LED on most C3 Super Mini clones.
const bool LED_ACTIVE_LOW = true;  // Set false if the LED logic looks inverted.

// The app sends intensity as 0.0-1.0; firmware converts to PWM duty 0-255.
// This is the same mapping the real firmware will use.
const float TEST_INTENSITY = 0.7f;   // matches BleController.testVibration default

// ---------------------------------------------------------------- helpers

/// Convert the app's 0.0-1.0 intensity into an 8-bit PWM duty cycle.
int dutyFor(float intensity) {
  if (intensity < 0.0f) intensity = 0.0f;
  if (intensity > 1.0f) intensity = 1.0f;
  return (int)(intensity * 255.0f + 0.5f);
}

/// One buzz: run the motor at `duty` for `ms`, then stop.
void buzz(int duty, int ms) {
  analogWrite(MOTOR_PIN, duty);
  delay(ms);
  analogWrite(MOTOR_PIN, 0);
}

void led(bool on) {
  digitalWrite(LED_PIN, LED_ACTIVE_LOW ? !on : on);
}

// ---------------------------------------------------------------- tests

/// TEST 1 — prove the board runs the code we just flashed.
void testBoardAlive() {
  Serial.println("\n[1/3] Board alive — LED blinks 5 times");
  for (int i = 0; i < 5; i++) {
    led(true);  delay(150);
    led(false); delay(150);
  }
}

/// TEST 2 — find the motor's real usable range.
///
/// Vibration motors do not start turning at duty 1. There is a floor below
/// which nothing happens. FIND THAT NUMBER and write it down: the app
/// currently allows intensity down to 0.1 (duty ~26), which may be silent
/// on this motor. If so, the app's minimum has to be raised to match.
void testIntensityRamp() {
  Serial.println("\n[2/3] Intensity ramp — note the FIRST step you can feel");
  for (int duty = 0; duty <= 255; duty += 15) {
    Serial.printf("   duty %3d / 255   (intensity %.2f)\n", duty, duty / 255.0f);
    analogWrite(MOTOR_PIN, duty);
    delay(700);
  }
  analogWrite(MOTOR_PIN, 0);
  Serial.println("   ramp done");
}

/// TEST 3 — the three turn cues, exactly as lib/services/haptic_cue_player.dart
/// defines them. If PREP and NOW feel the same on the wrist, the app's haptic
/// design needs changing — better to learn that now than during a drive.
void testCuePatterns() {
  const int i    = dutyFor(TEST_INTENSITY);
  const int half = dutyFor(TEST_INTENSITY * 0.5f);          // PREP
  const int strong = dutyFor(TEST_INTENSITY + 0.25f);       // NOW (clamped in dutyFor)

  Serial.println("\n[3/3] Cue patterns from the app");

  Serial.println("   PREP  — one gentle pulse (\"a turn is coming\")");
  buzz(half, 200);
  delay(1500);

  Serial.println("   ALERT — two pulses, 'medium' rhythm (\"turn soon\")");
  buzz(i, 220);
  delay(150);
  buzz(i, 220);
  delay(1500);

  Serial.println("   NOW   — two hard pulses (\"turn NOW\")");
  buzz(strong, 180);
  delay(90);
  buzz(strong, 180);
  delay(1500);

  Serial.println("   ARRIVAL — one long soft pulse (both wrists in the real device)");
  buzz(dutyFor(0.4f), 600);
}

// ---------------------------------------------------------------- lifecycle

void setup() {
  Serial.begin(115200);
  delay(1500);              // give the USB CDC port time to enumerate

  pinMode(LED_PIN, OUTPUT);
  pinMode(MOTOR_PIN, OUTPUT);
  analogWrite(MOTOR_PIN, 0);

  Serial.println("=====================================");
  Serial.println(" Sense&Safe wristband — motor test");
  Serial.printf("  motor pin GPIO %d\n", MOTOR_PIN);
  Serial.println("=====================================");

  testBoardAlive();
  testIntensityRamp();
}

void loop() {
  testCuePatterns();
  Serial.println("\n--- repeating in 5s (Ctrl+C / unplug to stop) ---");
  delay(5000);
}
