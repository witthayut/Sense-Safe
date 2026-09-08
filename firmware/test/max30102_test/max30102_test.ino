/*
 * Sense&Safe — max30102_test
 * --------------------------
 * Hardware smoke test for the GY-MAX30102 pulse-oximeter module on ONE
 * wristband. No BLE, no motor. Answers four questions, in order, and stops
 * at the first one that fails so the failure points at the cause:
 *
 *   1. Is the board alive and flashable?            -> LED blinks
 *   2. Is the module wired to the right I2C pins?   -> I2C scan finds 0x57
 *   3. Is it really a MAX30102 and does it answer?  -> part ID reads 0x15
 *   4. Does it see a pulse on real skin?            -> IR/RED stream + BPM
 *
 * Board:   ESP32-C3 Super Mini  (Tools > Board > ESP32C3 Dev Module)
 *          Tools > USB CDC On Boot > Enabled   <- required for Serial
 *
 * Library: "SparkFun MAX3010x Pulse and Proximity Sensor Library"
 *          Tools > Manage Libraries... > search "MAX3010x" > Install.
 *          The class is named MAX30105 but it drives the MAX30102 as well.
 *
 * Wiring:  GY-MAX30102  VIN -> 3.3    (NOT 5V: the C3 pins are not 5V-tolerant
 *                                      and the module pull-ups follow VIN)
 *                       GND -> G
 *                       SDA -> GPIO 6
 *                       SCL -> GPIO 7
 *                       INT / IRD / RD -> leave unconnected
 *
 * Open Serial Monitor at 115200, then rest a fingertip on the sensor window
 * with light pressure and hold still. The onboard LED flashes on each beat.
 */

#include <Wire.h>
#include "MAX30105.h"
#include "heartRate.h"

// ---------------------------------------------------------------- pins
const int I2C_SDA = 6;   // moved off the default GPIO8 (onboard LED)
const int I2C_SCL = 7;   // moved off the default GPIO9 (BOOT button)
const int LED_PIN = 8;   // Onboard LED on most C3 Super Mini clones.
const bool LED_ACTIVE_LOW = true;  // Set false if the LED logic looks inverted.

// ---------------------------------------------------------------- sensor
const uint8_t MAX30102_ADDR    = 0x57;
const uint8_t MAX30102_PART_ID = 0x15;
const uint8_t MPU6050_ADDR     = 0x68;   // not tested here, just named if seen

// Below this raw IR reading nothing is touching the sensor window.
// SparkFun examples use 50000 for a fingertip. A wrist reflects less light,
// so if the band sits on skin and still says "no contact", lower this.
const long CONTACT_THRESHOLD = 50000;

MAX30105 sensor;

// ---------------------------------------------------------------- helpers

void led(bool on) {
  digitalWrite(LED_PIN, LED_ACTIVE_LOW ? !on : on);
}

/// True if a device ACKs its address on the I2C bus.
bool i2cPresent(uint8_t addr) {
  Wire.beginTransmission(addr);
  return Wire.endTransmission() == 0;
}

/// Fast blink = "stuck, read the Serial Monitor".
void haltBlinking() {
  while (true) { led(true); delay(60); led(false); delay(60); }
}

// ---------------------------------------------------------------- tests

/// TEST 1 — prove the board runs the code we just flashed.
void testBoardAlive() {
  Serial.println("\n[1/4] Board alive — LED blinks 5 times");
  for (int i = 0; i < 5; i++) {
    led(true);  delay(150);
    led(false); delay(150);
  }
}

/// TEST 2 — is anything answering on SDA/SCL?
///
/// Lists every address that ACKs. Keeps re-scanning until the MAX30102 shows
/// up, so you can fix the wiring with the board still plugged in.
void testI2cScan() {
  Serial.printf("\n[2/4] I2C scan on SDA=GPIO%d / SCL=GPIO%d\n", I2C_SDA, I2C_SCL);
  while (true) {
    int  found      = 0;
    bool haveSensor = false;

    for (uint8_t addr = 1; addr < 127; addr++) {
      if (!i2cPresent(addr)) continue;
      found++;
      Serial.printf("   0x%02X", addr);
      if (addr == MAX30102_ADDR)     { Serial.print("  <- MAX30102"); haveSensor = true; }
      else if (addr == MPU6050_ADDR) { Serial.print("  <- MPU-6050 (not tested here)"); }
      Serial.println();
    }

    if (haveSensor) {
      Serial.println("   sensor found");
      return;
    }

    if (found == 0) Serial.println("   nothing answered");
    Serial.printf("   MAX30102 (0x%02X) missing — check, in this order:\n", MAX30102_ADDR);
    Serial.println("     1. VIN on the 3.3 pin (not 5V), GND on G");
    Serial.printf ("     2. SDA <-> SCL swapped?  SDA must be GPIO%d, SCL GPIO%d\n", I2C_SDA, I2C_SCL);
    Serial.println("     3. loose Dupont wire, or the header pins on the module are not soldered");
    Serial.println("   re-scanning in 3s...");
    for (int i = 0; i < 15; i++) { led(true); delay(100); led(false); delay(100); }
  }
}

/// TEST 3 — talk to it properly.
///
/// begin() reads register 0xFF (part ID) and refuses anything that is not
/// 0x15. Failing here while 0x57 answered the scan means a clone chip or a
/// flaky bus (long wires, missing ground), not a pin mix-up.
void testSensorIdentity() {
  Serial.println("\n[3/4] Sensor identity");
  if (!sensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.printf("   part ID is not 0x%02X — not a MAX30102, or bus errors. Halting.\n",
                  MAX30102_PART_ID);
    haltBlinking();
  }
  Serial.printf("   part ID 0x%02X  revision 0x%02X  — OK\n",
                sensor.readPartID(), sensor.getRevisionID());

  // ledBrightness 0x1F (~6 mA), average 4 samples, mode 2 = Red + IR only
  // (the MAX30102 has no green LED), 400 Hz, 411 us pulse, 4096 nA ADC range.
  sensor.setup(0x1F, 4, 2, 400, 411, 4096);
  sensor.setPulseAmplitudeRed(0x0A);   // dim red glow = "sensor is running"
  Serial.println("   LEDs on — a faint red glow should be visible on the module");
}

// ---------------------------------------------------------------- lifecycle

void setup() {
  Serial.begin(115200);
  delay(1500);              // give the USB CDC port time to enumerate

  pinMode(LED_PIN, OUTPUT);
  led(false);

  Serial.println("=====================================");
  Serial.println(" Sense&Safe wristband — MAX30102 test");
  Serial.printf("  I2C  SDA GPIO %d / SCL GPIO %d\n", I2C_SDA, I2C_SCL);
  Serial.println("=====================================");

  Wire.begin(I2C_SDA, I2C_SCL);   // must run BEFORE sensor.begin()

  testBoardAlive();
  testI2cScan();
  testSensorIdentity();

  Serial.println("\n[4/4] Signal — rest a fingertip on the sensor window and hold still");
  Serial.println("   columns: IR  RED  BPM(now)  BPM(avg)    LED flashes on each beat");
}

// TEST 4 — beat detection, same algorithm as SparkFun Example5_HeartRate.
// IR should jump well above CONTACT_THRESHOLD when skin touches the window,
// and after a few seconds BPM(avg) should settle near your resting pulse.
const byte RATE_SIZE = 4;          // average over the last 4 beats
byte  rates[RATE_SIZE];
byte  rateSpot   = 0;
byte  rateCount  = 0;              // slots filled so far; avg is meaningless before RATE_SIZE
long  lastBeat   = 0;
float bpm        = 0;
int   bpmAvg     = 0;
unsigned long lastPrint = 0;
unsigned long ledOffAt  = 0;

void loop() {
  long ir  = sensor.getIR();
  long red = sensor.getRed();

  if (checkForBeat(ir)) {
    long delta = millis() - lastBeat;
    lastBeat = millis();
    bpm = 60.0f / (delta / 1000.0f);

    if (bpm > 20 && bpm < 255) {            // drop obvious glitches
      rates[rateSpot++] = (byte)bpm;
      rateSpot %= RATE_SIZE;
      if (rateCount < RATE_SIZE) rateCount++;
      // Average only the slots that hold a real beat. Averaging the empty
      // (zero) slots too, as SparkFun's example does, reads ~35-50 BPM for
      // the first few seconds and looks like a real low pulse.
      bpmAvg = 0;
      for (byte i = 0; i < rateCount; i++) bpmAvg += rates[i];
      bpmAvg /= rateCount;
    }
    led(true);
    ledOffAt = millis() + 60;
  }
  if (ledOffAt && millis() > ledOffAt) { led(false); ledOffAt = 0; }

  // Print at 4 Hz so the Serial Monitor stays readable; sampling above
  // runs as fast as loop() allows, which the beat detector needs.
  if (millis() - lastPrint >= 250) {
    lastPrint = millis();
    Serial.printf("   IR=%6ld  RED=%6ld  BPM=%5.1f  avg=%3d", ir, red, bpm, bpmAvg);
    if (ir < CONTACT_THRESHOLD)        Serial.print("   (no contact)");
    else if (rateCount < RATE_SIZE)    Serial.print("   (warming up - ignore avg)");
    Serial.println();
  }
}
