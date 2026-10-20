/*
 * Sense&Safe — max30102_test  (v3)
 * --------------------------------
 * Hardware smoke test for the GY-MAX30102 pulse-oximeter module on ONE
 * wristband. No BLE, no motor. Answers four questions, in order, and stops
 * at the first one that fails so the failure points at the cause:
 *
 *   1. Is the board alive and flashable?            -> LED blinks
 *   2. Is the module wired to the right I2C pins?   -> I2C scan finds 0x57
 *   3. Is it really a MAX30102 and does it answer?  -> part ID reads 0x15
 *   4. Does it see a pulse on real skin?            -> two estimators, side by side
 *
 * Stage 4 runs TWO independent heart-rate estimators on the same samples,
 * so the Serial Monitor shows, for any placement, which one holds up:
 *
 *   beat — per-beat detector: adaptive threshold + refractory period.
 *          Fast, flashes the LED on every beat, needs a clean pulse.
 *          Design follows the MAX30100 BeatDetector by Oxullo (GPL-3),
 *          reimplemented from its description; no code copied.
 *   win  — 4-second window: heart rate = first peak of the IR
 *          autocorrelation, accepted only when red and IR show the same
 *          waveform (Pearson >= 0.8). Slow (4 s to fill, 1 value/s) but
 *          survives a weak wrist signal and says "noisy" instead of guessing.
 *          Design follows MAX30102_by_RF by R. Fraczkiewicz (MIT).
 *
 * Neither runs until the IR level says skin is on the window; both reset
 * the moment it leaves. v1/v2 used SparkFun's checkForBeat(), which has no
 * contact gate, no refractory period and never resets — see git history.
 *
 * Board:   ESP32-C3 Super Mini  (Tools > Board > ESP32C3 Dev Module)
 *          Tools > USB CDC On Boot > Enabled   <- required for Serial
 *
 * Library: "SparkFun MAX3010x Pulse and Proximity Sensor Library"
 *          Tools > Manage Libraries... > search "MAX3010x" > Install.
 *          Used for I2C + FIFO only; its heartRate.h is NOT used any more.
 *
 * Wiring:  GY-MAX30102  VIN -> 3.3    (NOT 5V: the C3 pins are not 5V-tolerant
 *                                      and the module pull-ups follow VIN)
 *                       GND -> G
 *                       SDA -> GPIO 6
 *                       SCL -> GPIO 7
 *                       INT / IRD / RD -> leave unconnected
 *
 * Open Serial Monitor at 115200. Fingertip first (rest it lightly, hold
 * still, shade the window); set WRIST_MODE 1 below to try the inner wrist.
 */

#include <Wire.h>
#include "MAX30105.h"

// ---------------------------------------------------------------- mode
// 0 = fingertip bench test. 1 = inner wrist: brighter LEDs, wider ADC range,
// lower contact threshold (a wrist reflects far less light than a finger).
#define WRIST_MODE 0

#if WRIST_MODE
const byte LED_BRIGHTNESS    = 0x7F;    // ~25 mA per LED
const int  ADC_RANGE         = 16384;   // nA full scale, keeps the brighter LEDs off the rail
const long CONTACT_THRESHOLD = 20000;   // raw IR below this = nothing on the window
#else
const byte LED_BRIGHTNESS    = 0x1F;    // ~6 mA per LED
const int  ADC_RANGE         = 4096;
const long CONTACT_THRESHOLD = 50000;   // SparkFun's fingertip figure
#endif

// ---------------------------------------------------------------- pins
const int I2C_SDA = 6;   // moved off the default GPIO8 (onboard LED)
const int I2C_SCL = 7;   // moved off the default GPIO9 (BOOT button)
const int LED_PIN = 8;   // Onboard LED on most C3 Super Mini clones.
const bool LED_ACTIVE_LOW = true;  // Set false if the LED logic looks inverted.

// ---------------------------------------------------------------- sensor
const uint8_t MAX30102_ADDR    = 0x57;
const uint8_t MAX30102_PART_ID = 0x15;
const uint8_t MPU6050_ADDR     = 0x68;   // not tested here, just named if seen

// Sensor set to 400 Hz with 4-sample averaging = 100 samples/s into the FIFO.
const float FS_HZ     = 100.0f;
const float SAMPLE_MS = 1000.0f / FS_HZ;

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

// ---------------------------------------------------------------- tests 1-3

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

  // brightness, average 4 samples, mode 2 = Red + IR (no green on a MAX30102),
  // 400 Hz, 411 us pulse (18-bit), ADC range. Red stays as bright as IR on
  // purpose: the window estimator compares the two channels.
  sensor.setup(LED_BRIGHTNESS, 4, 2, 400, 411, ADC_RANGE);
  sensor.clearFIFO();
  Serial.printf("   LEDs on at 0x%02X — a red glow should be visible on the module\n",
                LED_BRIGHTNESS);
}

// ================================================================ stage 4
// ---------------------------------------------------------------- filters

/// Removes the slow DC level, keeps the pulse:  y[n] = w[n] - w[n-1],
/// w[n] = x[n] + a*w[n-1]. Primed on the first sample so it starts at 0.
struct DcBlocker {
  float a, w = 0;
  bool  primed = false;
  explicit DcBlocker(float alpha) : a(alpha) {}
  float step(float x) {
    if (!primed) { w = x / (1.0f - a); primed = true; return 0; }
    float prev = w;
    w = x + a * w;
    return w - prev;
  }
  void reset() { w = 0; primed = false; }
};

/// 1st-order Butterworth low-pass, fc = 4 Hz at fs = 100 Hz (bilinear
/// transform: K = tan(pi*4/100), b0 = K/(1+K), a1 = (1-K)/(1+K)).
/// 4 Hz, not 6: the pulse lives below ~3 Hz, and at 6 Hz enough noise got
/// through to fake beats on a bare, pulse-less window in simulation.
struct LowPass4Hz {
  float xPrev = 0, y = 0;
  float step(float x) {
    y = 0.112160f * (x + xPrev) + 0.775680f * y;
    xPrev = x;
    return y;
  }
  void reset() { xPrev = 0; y = 0; }
};

/// One LED channel's conditioning chain: two DC blockers in series (one
/// left ~30 % of breathing drift through, two leave ~9 %), then the
/// low-pass, then a sign flip — more blood reflects LESS light, so the
/// pulse arrives as a dip and comes out as a peak.
struct Channel {
  DcBlocker   dc1{0.95f}, dc2{0.95f};
  LowPass4Hz  lp;
  float step(float raw) { return lp.step(-dc2.step(dc1.step(raw))); }
  void  reset() { dc1.reset(); dc2.reset(); lp.reset(); }
};

// ---------------------------------------------------------------- "beat"

const float    BPM_MIN = 40, BPM_MAX = 180;     // anything else is not a resting human

const uint32_t BEAT_INIT_HOLDOFF_MS = 2000;     // let the filters settle after contact
const uint32_t BEAT_MASK_MS         = 250;      // refractory: nothing counts within 250 ms
const uint32_t BEAT_LOST_MS         = 2000;     // no beat for 2 s -> forget the rate
const float    BEAT_MIN_THRESHOLD   = 30;       // ADC counts, above the ADC noise floor
const float    BEAT_MAX_THRESHOLD   = 4000;     // fingertip peaks reach 1-3 % of DC
const float    BEAT_STEP_RESILIENCY = 30;       // must fall this far below the peak to confirm
const float    BEAT_FALLOFF_TARGET  = 0.3f;     // threshold sinks to 30 % of last peak per beat
const float    BEAT_DECAY           = 0.99f;    // per-sample decay before the first beat
const float    BEAT_PERIOD_ALPHA    = 0.6f;     // EMA weight of the newest interval
const uint8_t  BEAT_WARMUP          = 4;        // beats needed before a rate is shown

enum BeatState : uint8_t { B_INIT, B_WAITING, B_FOLLOWING, B_MAYBE, B_MASKING };

/// Per-beat detector. Rides up each pulse, confirms the beat when the signal
/// falls back off the peak, then masks for 250 ms so the dicrotic notch
/// (the small second bump) cannot count as a beat. The threshold sinks
/// towards 30 % of the last peak over one beat period, so it adapts to
/// whoever is wearing it without fixed numbers.
struct BeatDetector {
  BeatState state     = B_INIT;
  float     threshold = BEAT_MIN_THRESHOLD;
  float     lastPeak  = 0;
  float     periodMs  = 0;      // EMA of beat-to-beat interval
  uint32_t  tsInit = 0, tsLastBeat = 0;
  uint8_t   count = 0;          // plausible beats in a row

  void reset(uint32_t now) {
    state = B_INIT; threshold = BEAT_MIN_THRESHOLD; lastPeak = 0; periodMs = 0;
    tsInit = now; tsLastBeat = 0; count = 0;
  }
  bool  ready() const { return periodMs > 0 && count >= BEAT_WARMUP; }
  float bpm()   const { return periodMs > 0 ? 60000.0f / periodMs : 0; }

  /// Feed one filtered sample. Returns true on the sample that confirms a beat.
  bool add(float s, uint32_t now) {
    bool beat = false;
    switch (state) {
      case B_INIT:
        if (now - tsInit > BEAT_INIT_HOLDOFF_MS) state = B_WAITING;
        break;

      case B_WAITING:
        if (s > threshold) { threshold = min(s, BEAT_MAX_THRESHOLD); state = B_FOLLOWING; }
        if (tsLastBeat && now - tsLastBeat > BEAT_LOST_MS) { periodMs = 0; lastPeak = 0; count = 0; }
        decay();
        break;

      case B_FOLLOWING:
        if (s < threshold) state = B_MAYBE;
        else threshold = min(s, BEAT_MAX_THRESHOLD);
        break;

      case B_MAYBE:
        if (s + BEAT_STEP_RESILIENCY < threshold) {
          beat = true;
          lastPeak = threshold;
          if (tsLastBeat) {
            float delta = now - tsLastBeat;
            float b = 60000.0f / delta;
            if (b >= BPM_MIN && b <= BPM_MAX) {
              periodMs = periodMs > 0 ? BEAT_PERIOD_ALPHA * delta + (1 - BEAT_PERIOD_ALPHA) * periodMs
                                      : delta;
              if (count < 255) count++;
            }
            // implausible interval (missed or doubled beat): keep the old rate, do not count it
          }
          tsLastBeat = now;
          state = B_MASKING;
        } else {
          state = B_FOLLOWING;   // just a wobble on the way up
        }
        break;

      case B_MASKING:
        if (now - tsLastBeat > BEAT_MASK_MS) state = B_WAITING;
        decay();
        break;
    }
    return beat;
  }

  void decay() {
    if (lastPeak > 0 && periodMs > 0)
      threshold -= lastPeak * (1 - BEAT_FALLOFF_TARGET) / (periodMs / SAMPLE_MS);
    else
      threshold *= BEAT_DECAY;
    if (threshold < BEAT_MIN_THRESHOLD) threshold = BEAT_MIN_THRESHOLD;
  }
};

// ---------------------------------------------------------------- "win"

const uint8_t WIN_FS   = 25;                          // Hz after 4:1 decimation
const uint8_t WIN_N    = 100;                         // 4 s of samples
const uint8_t WIN_STEP = 25;                          // recompute every 1 s
const uint8_t WIN_MA   = 25;                          // 1 s moving average removed before the period search
const uint8_t LAG_MIN  = (uint8_t)(WIN_FS * 60 / BPM_MAX);   // 8  samples -> 187 BPM
const uint8_t LAG_MAX  = (uint8_t)(WIN_FS * 60 / BPM_MIN);   // 37 samples -> 40 BPM
const float   WIN_MIN_PEARSON = 0.8f;   // red and IR must carry the same waveform
const float   WIN_MIN_PEAK    = 0.3f;   // autocorrelation at the period, as a fraction of lag 0
const float   WIN_MAX_VALLEY  = 0.5f;   // ...and it must have DIPPED below this first (real periodicity)
const float   WIN_REL_MAX     = 0.6f;   // ...and be within 60 % of the strongest peak in range (not a noise wiggle)

/// Window estimator. Keeps the last 4 s of the FILTERED red + IR at 25 Hz.
/// Every second: remove mean and linear drift from both, check that red and
/// IR agree (Pearson >= 0.8, else "noisy"), then search the IR
/// autocorrelation for the first peak between the 180- and 40-BPM lags.
/// No beats are counted, so a few weak pulses do not throw it — which is
/// what a wrist needs. Tuned on a synthetic PPG (breathing drift, dicrotic
/// notch, ADC noise, motion bursts, pulse-less windows): the three gates
/// below are what stopped it from reporting a heart rate for pure drift.
struct WindowEstimator {
  float   ir[WIN_N], red[WIN_N];
  uint8_t n = 0, sinceCalc = 0;
  float   accIr = 0, accRed = 0;
  uint8_t accN = 0;

  bool        valid = false;
  float       bpm = 0, pearson = 0, acRatio = 0;
  const char* why = "filling";

  void reset() {
    n = 0; sinceCalc = 0; accIr = accRed = 0; accN = 0;
    valid = false; bpm = pearson = acRatio = 0; why = "filling";
  }
  bool filled() const { return n >= WIN_N; }
  float secondsFilled() const { return n / (float)WIN_FS; }

  /// Feed one filtered 100 Hz sample pair; averages 4 into one 25 Hz sample.
  void addRaw(float irRaw, float redRaw) {
    accIr += irRaw; accRed += redRaw;
    if (++accN < 4) return;
    push(accIr / 4, accRed / 4);
    accIr = accRed = 0; accN = 0;
  }

  void push(float i, float r) {
    if (n < WIN_N) { ir[n] = i; red[n] = r; n++; }
    else {
      memmove(ir,  ir  + 1, (WIN_N - 1) * sizeof(float));
      memmove(red, red + 1, (WIN_N - 1) * sizeof(float));
      ir[WIN_N - 1] = i; red[WIN_N - 1] = r;
    }
    if (n < WIN_N) return;
    if (++sinceCalc >= WIN_STEP) { sinceCalc = 0; compute(); }
  }

  /// out = in minus its mean minus its best-fit straight line.
  static void detrend(const float* in, float* out) {
    const float meanT = (WIN_N - 1) / 2.0f;
    float mean = 0;
    for (uint8_t i = 0; i < WIN_N; i++) mean += in[i];
    mean /= WIN_N;
    float sTV = 0, sTT = 0;
    for (uint8_t i = 0; i < WIN_N; i++) { float t = i - meanT; sTV += t * (in[i] - mean); sTT += t * t; }
    float beta = sTV / sTT;
    for (uint8_t i = 0; i < WIN_N; i++) out[i] = (in[i] - mean) - beta * (i - meanT);
  }

  void compute() {
    float x[WIN_N], y[WIN_N];
    detrend(ir, x);
    detrend(red, y);

    // 1. quality gate: two LEDs looking at the same blood must agree
    float sxy = 0, sxx = 0, syy = 0;
    for (uint8_t i = 0; i < WIN_N; i++) { sxy += x[i] * y[i]; sxx += x[i] * x[i]; syy += y[i] * y[i]; }
    pearson = (sxx > 0 && syy > 0) ? sxy / sqrtf(sxx * syy) : 0;
    if (pearson < WIN_MIN_PEARSON) { valid = false; why = "noisy"; return; }

    // 2. for the period search only, strip what is left of the slow drift by
    //    subtracting a 1 s centred moving average (reuses y as scratch)
    for (uint8_t i = 0; i < WIN_N; i++) {
      uint8_t lo = (i >= WIN_MA / 2) ? i - WIN_MA / 2 : 0;
      uint8_t hi = (i + WIN_MA / 2 + 1 < WIN_N) ? i + WIN_MA / 2 + 1 : WIN_N;
      float m = 0;
      for (uint8_t k = lo; k < hi; k++) m += x[k];
      y[i] = x[i] - m / (hi - lo);
    }
    const float* z = y;

    // 3. autocorrelation at every lag up to the 40-BPM period (+1 for the peak test)
    float acs[LAG_MAX + 2];
    for (uint8_t L = 0; L <= LAG_MAX + 1; L++) {
      float s = 0;
      for (uint8_t i = 0; i + L < WIN_N; i++) s += z[i] * z[i + L];
      acs[L] = s / (WIN_N - L);
    }
    const float ac0 = acs[0];
    float acMax = acs[LAG_MIN];
    for (uint8_t L = LAG_MIN + 1; L <= LAG_MAX; L++) if (acs[L] > acMax) acMax = acs[L];

    // 4. the period = the FIRST local maximum inside the human range that
    //    (a) comes after a real dip, (b) is strong against lag 0, and
    //    (c) is not a small wiggle next to a much taller peak.
    //    "First" is what keeps 120 BPM from being reported as 60.
    float minSoFar = ac0;
    for (uint8_t L = 1; L <= LAG_MAX; L++) {
      if (acs[L] < minSoFar) minSoFar = acs[L];
      if (L < LAG_MIN) continue;
      if (!(acs[L] > acs[L - 1] && acs[L] >= acs[L + 1])) continue;       // not a peak
      if (minSoFar > WIN_MAX_VALLEY * ac0) continue;                       // (a) never dipped
      if (acs[L] < WIN_MIN_PEAK * ac0) continue;                           // (b) too weak
      if (acs[L] < WIN_REL_MAX * acMax) continue;                          // (c) wiggle
      // parabolic interpolation between neighbours for a sub-sample period
      float p = acs[L - 1], c = acs[L], n = acs[L + 1];
      float denom = p - 2 * c + n;
      float frac  = (denom != 0) ? 0.5f * (p - n) / denom : 0;
      if (frac >  0.5f) frac =  0.5f;
      if (frac < -0.5f) frac = -0.5f;
      bpm = WIN_FS * 60.0f / (L + frac);
      acRatio = c / ac0;
      valid = true; why = "ok";
      return;
    }
    valid = false; why = "no peak"; acRatio = acMax / ac0;
  }
};

// ---------------------------------------------------------------- contact + glue

Channel         irChan, redChan;
BeatDetector    beat;
WindowEstimator win;

float irLevel  = 0;       // slow EMA of raw IR = the DC level = "is skin there"
bool  contact  = false;
unsigned long ledOffAt  = 0;
unsigned long lastPrint = 0;

void resetEstimators(uint32_t now) {
  irChan.reset(); redChan.reset(); beat.reset(now); win.reset();
}

/// One 100 Hz sample pair straight from the FIFO.
void processSample(uint32_t irRaw, uint32_t redRaw, uint32_t now) {
  irLevel = (irLevel == 0) ? irRaw : irLevel + 0.05f * (irRaw - irLevel);

  // contact gate with hysteresis so a wobbling finger does not flap it
  if (!contact && irLevel >= CONTACT_THRESHOLD)         { contact = true;  resetEstimators(now); }
  else if (contact && irLevel < CONTACT_THRESHOLD * 0.8f) { contact = false; resetEstimators(now); }
  if (!contact) return;

  float irAc  = irChan.step((float)irRaw);     // pulse as a peak, drift mostly gone
  float redAc = redChan.step((float)redRaw);

  if (beat.add(irAc, now)) { led(true); ledOffAt = now + 60; }
  win.addRaw(irAc, redAc);
}

// ---------------------------------------------------------------- lifecycle

void setup() {
  Serial.begin(115200);
  delay(1500);              // give the USB CDC port time to enumerate

  pinMode(LED_PIN, OUTPUT);
  led(false);

  Serial.println("=====================================");
  Serial.println(" Sense&Safe wristband — MAX30102 test v3");
  Serial.printf("  I2C  SDA GPIO %d / SCL GPIO %d\n", I2C_SDA, I2C_SCL);
  Serial.printf("  mode %s   contact threshold %ld\n", WRIST_MODE ? "WRIST" : "FINGERTIP", CONTACT_THRESHOLD);
  Serial.println("=====================================");

  Wire.begin(I2C_SDA, I2C_SCL);   // must run BEFORE sensor.begin()

  testBoardAlive();
  testI2cScan();
  testSensorIdentity();

  Serial.println("\n[4/4] Signal — rest a fingertip on the window, hold still, shade it");
  Serial.println("   beat = per-beat detector (LED flashes)   win = 4 s window (needs red+IR to agree)");
  Serial.println("   '--' means not enough evidence yet; both go back to '--' when skin leaves");
}

void loop() {
  uint32_t now = millis();

  // Drain the sensor FIFO. The library keeps only 4 samples = 40 ms at
  // 100 Hz, so nothing in this loop may block longer than that.
  sensor.check();
  while (sensor.available()) {
    processSample(sensor.getFIFOIR(), sensor.getFIFORed(), now);
    sensor.nextSample();
  }

  if (ledOffAt && now > ledOffAt) { led(false); ledOffAt = 0; }

  if (now - lastPrint >= 250) {
    lastPrint = now;
    Serial.printf("   IR=%6ld", (long)irLevel);
    if (!contact) {
      Serial.println("   beat= --   win= --   (no contact)");
      return;
    }
    if (beat.ready()) Serial.printf("   beat=%3.0f", beat.bpm());
    else              Serial.print ("   beat= --");
    if (win.valid)    Serial.printf("   win=%3.0f  (r=%.2f ac=%.2f)", win.bpm, win.pearson, win.acRatio);
    else if (!win.filled()) Serial.printf("   win= --  (filling %.0f/4 s)", win.secondsFilled());
    else              Serial.printf("   win= --  (%s r=%.2f)", win.why, win.pearson);
    Serial.printf("   amp=%4.0f\n", beat.lastPeak);
  }
}
