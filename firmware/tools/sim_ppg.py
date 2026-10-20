"""Synthetic-PPG test bench for firmware/test/max30102_test/max30102_test.ino (v3).

Line-by-line Python mirror of the two heart-rate estimators in the sketch,
driven by a synthetic pulse signal, so a change to a constant can be checked
on the PC in seconds instead of on a wrist. Keep the constants in sync with
the .ino by hand; if they drift apart this bench proves nothing.

    python firmware/tools/sim_ppg.py

Each row: one scenario. `beat` = per-beat detector output over the second
half of the run. `win` = window estimator: how many 1 s reports were valid,
how many of those were wrong by more than 5 BPM (should be 0), and the range.
"""
import math, random

# ---------------------------------------------------------------- constants (mirror the .ino)
FS = 100.0; SAMPLE_MS = 1000.0 / FS
CONTACT_THRESHOLD = 50000
BPM_MIN, BPM_MAX = 40, 180

BEAT_INIT_HOLDOFF_MS = 2000; BEAT_MASK_MS = 250; BEAT_LOST_MS = 2000
BEAT_MIN_THRESHOLD = 30; BEAT_MAX_THRESHOLD = 4000; BEAT_STEP_RESILIENCY = 30
BEAT_FALLOFF_TARGET = 0.3; BEAT_DECAY = 0.99; BEAT_PERIOD_ALPHA = 0.6; BEAT_WARMUP = 4

WIN_FS = 25; WIN_N = 100; WIN_STEP = 25; WIN_MA = 25
LAG_MIN = int(WIN_FS * 60 / BPM_MAX); LAG_MAX = int(WIN_FS * 60 / BPM_MIN)
WIN_MIN_PEARSON = 0.8; WIN_MIN_PEAK = 0.3; WIN_MAX_VALLEY = 0.5; WIN_REL_MAX = 0.6

# ---------------------------------------------------------------- filters
class DcBlocker:
    def __init__(self, a): self.a = a; self.w = 0.0; self.primed = False
    def step(self, x):
        if not self.primed: self.w = x / (1 - self.a); self.primed = True; return 0.0
        prev = self.w; self.w = x + self.a * self.w; return self.w - prev
    def reset(self): self.w = 0.0; self.primed = False

class LowPass4Hz:
    def __init__(self): self.xp = 0.0; self.y = 0.0
    def step(self, x):
        self.y = 0.112160 * (x + self.xp) + 0.775680 * self.y; self.xp = x; return self.y
    def reset(self): self.xp = 0.0; self.y = 0.0

class Channel:
    def __init__(self): self.dc1 = DcBlocker(0.95); self.dc2 = DcBlocker(0.95); self.lp = LowPass4Hz()
    def step(self, raw): return self.lp.step(-self.dc2.step(self.dc1.step(raw)))
    def reset(self): self.dc1.reset(); self.dc2.reset(); self.lp.reset()

# ---------------------------------------------------------------- "beat"
class BeatDetector:
    def __init__(self): self.reset(0)
    def reset(self, now):
        self.state = 'INIT'; self.threshold = BEAT_MIN_THRESHOLD; self.lastPeak = 0.0; self.periodMs = 0.0
        self.tsInit = now; self.tsLastBeat = 0; self.count = 0
    def ready(self): return self.periodMs > 0 and self.count >= BEAT_WARMUP
    def bpm(self): return 60000.0 / self.periodMs if self.periodMs > 0 else 0
    def decay(self):
        if self.lastPeak > 0 and self.periodMs > 0:
            self.threshold -= self.lastPeak * (1 - BEAT_FALLOFF_TARGET) / (self.periodMs / SAMPLE_MS)
        else:
            self.threshold *= BEAT_DECAY
        if self.threshold < BEAT_MIN_THRESHOLD: self.threshold = BEAT_MIN_THRESHOLD
    def add(self, s, now):
        beat = False; st = self.state
        if st == 'INIT':
            if now - self.tsInit > BEAT_INIT_HOLDOFF_MS: self.state = 'WAITING'
        elif st == 'WAITING':
            if s > self.threshold: self.threshold = min(s, BEAT_MAX_THRESHOLD); self.state = 'FOLLOWING'
            if self.tsLastBeat and now - self.tsLastBeat > BEAT_LOST_MS:
                self.periodMs = 0; self.lastPeak = 0; self.count = 0
            self.decay()
        elif st == 'FOLLOWING':
            if s < self.threshold: self.state = 'MAYBE'
            else: self.threshold = min(s, BEAT_MAX_THRESHOLD)
        elif st == 'MAYBE':
            if s + BEAT_STEP_RESILIENCY < self.threshold:
                beat = True; self.lastPeak = self.threshold
                if self.tsLastBeat:
                    delta = now - self.tsLastBeat; b = 60000.0 / delta
                    if BPM_MIN <= b <= BPM_MAX:
                        self.periodMs = (BEAT_PERIOD_ALPHA * delta + (1 - BEAT_PERIOD_ALPHA) * self.periodMs
                                         if self.periodMs > 0 else delta)
                        self.count = min(255, self.count + 1)
                self.tsLastBeat = now; self.state = 'MASKING'
            else:
                self.state = 'FOLLOWING'
        elif st == 'MASKING':
            if now - self.tsLastBeat > BEAT_MASK_MS: self.state = 'WAITING'
            self.decay()
        return beat

# ---------------------------------------------------------------- "win"
class WindowEstimator:
    def __init__(self): self.reset()
    def reset(self):
        self.ir = []; self.red = []; self.sinceCalc = 0; self.accIr = 0.0; self.accRed = 0.0; self.accN = 0
        self.valid = False; self.bpm = 0.0; self.pearson = 0.0; self.acRatio = 0.0; self.why = 'filling'
    def filled(self): return len(self.ir) >= WIN_N
    def addRaw(self, i, r):
        self.accIr += i; self.accRed += r; self.accN += 1
        if self.accN < 4: return
        self.push(self.accIr / 4, self.accRed / 4); self.accIr = self.accRed = 0.0; self.accN = 0
    def push(self, i, r):
        if len(self.ir) < WIN_N: self.ir.append(i); self.red.append(r)
        else: self.ir = self.ir[1:] + [i]; self.red = self.red[1:] + [r]
        if len(self.ir) < WIN_N: return
        self.sinceCalc += 1
        if self.sinceCalc >= WIN_STEP: self.sinceCalc = 0; self.compute()
    @staticmethod
    def detrend(v):
        meanT = (WIN_N - 1) / 2.0; mean = sum(v) / WIN_N
        sTV = sum((i - meanT) * (v[i] - mean) for i in range(WIN_N)); sTT = sum((i - meanT) ** 2 for i in range(WIN_N))
        beta = sTV / sTT
        return [(v[i] - mean) - beta * (i - meanT) for i in range(WIN_N)]
    def compute(self):
        x = self.detrend(self.ir); y = self.detrend(self.red)
        sxy = sum(a * b for a, b in zip(x, y)); sxx = sum(a * a for a in x); syy = sum(b * b for b in y)
        self.pearson = sxy / math.sqrt(sxx * syy) if sxx > 0 and syy > 0 else 0
        if self.pearson < WIN_MIN_PEARSON: self.valid = False; self.why = 'noisy'; return
        z = []
        for i in range(WIN_N):
            lo = i - WIN_MA // 2 if i >= WIN_MA // 2 else 0
            hi = i + WIN_MA // 2 + 1 if i + WIN_MA // 2 + 1 < WIN_N else WIN_N
            z.append(x[i] - sum(x[lo:hi]) / (hi - lo))
        acs = [sum(z[i] * z[i + L] for i in range(WIN_N - L)) / (WIN_N - L) for L in range(LAG_MAX + 2)]
        ac0 = acs[0]; acMax = max(acs[LAG_MIN:LAG_MAX + 1])
        minSoFar = ac0
        for L in range(1, LAG_MAX + 1):
            if acs[L] < minSoFar: minSoFar = acs[L]
            if L < LAG_MIN: continue
            if not (acs[L] > acs[L - 1] and acs[L] >= acs[L + 1]): continue
            if minSoFar > WIN_MAX_VALLEY * ac0: continue
            if acs[L] < WIN_MIN_PEAK * ac0: continue
            if acs[L] < WIN_REL_MAX * acMax: continue
            p, c, n = acs[L - 1], acs[L], acs[L + 1]
            denom = p - 2 * c + n; frac = 0.5 * (p - n) / denom if denom != 0 else 0
            frac = max(-0.5, min(0.5, frac))
            self.bpm = WIN_FS * 60.0 / (L + frac); self.acRatio = c / ac0; self.valid = True; self.why = 'ok'
            return
        self.valid = False; self.why = 'no peak'; self.acRatio = acMax / ac0

# ---------------------------------------------------------------- synthetic PPG
def ppg_wave(phase):
    """One cardiac cycle, phase 0..1 -> 0..1: systolic peak + dicrotic notch."""
    g = lambda c, w: math.exp(-((phase - c) / w) ** 2)
    return g(0.18, 0.09) + 0.45 * g(0.45, 0.12)

def run(hr, amp=1500, noise=30, drift=800, seconds=24, contact_from=2.0, contact_to=None,
        artifact=None, seed=1):
    random.seed(seed); contact_to = contact_to or seconds
    irChan, redChan = Channel(), Channel(); beat = BeatDetector(); win = WindowEstimator()
    irLevel = 0.0; contact = False; phase = 0.0
    beats = []; beatBpm = []; winOut = []; ghosts = 0
    def reset_all(now):
        irChan.reset(); redChan.reset(); beat.reset(now); win.reset()
    for k in range(int(seconds * FS)):
        t = k / FS; now = int(t * 1000); phase = (phase + hr / 60.0 / FS) % 1.0
        on = contact_from <= t < contact_to
        dr = drift * math.sin(2 * math.pi * 0.25 * t); pulse = amp * ppg_wave(phase)
        if on:
            ir = 90000 - pulse + dr + random.gauss(0, noise)
            red = 60000 - 0.5 * pulse + 0.5 * dr + random.gauss(0, noise)
            if artifact and artifact[0] <= t < artifact[1]:
                ir += random.gauss(0, 3000); red += random.gauss(0, 3000)   # independent per channel
        else:
            ir = 2000 + random.gauss(0, noise); red = 1500 + random.gauss(0, noise)
        # ---- processSample()
        irLevel = ir if irLevel == 0 else irLevel + 0.05 * (ir - irLevel)
        if not contact and irLevel >= CONTACT_THRESHOLD: contact = True; reset_all(now)
        elif contact and irLevel < CONTACT_THRESHOLD * 0.8: contact = False; reset_all(now)
        if not contact: continue
        irAc = irChan.step(ir); redAc = redChan.step(red)
        if beat.add(irAc, now):
            beats.append(t)
            if not on: ghosts += 1
            if beat.ready(): beatBpm.append(beat.bpm())
        win.addRaw(irAc, redAc)
        if k % 25 == 0 and win.filled(): winOut.append((t, win.valid, win.bpm, win.why))
    stable = beatBpm[len(beatBpm) // 2:]
    valids = [w for w in winOut if w[1]]; wrong = [w for w in valids if abs(w[2] - hr) > 5]
    return dict(beats=len(beats), ghosts=ghosts,
                beat=(min(stable), max(stable)) if stable else None,
                win_valid=len(valids), win_total=len(winOut), win_wrong=len(wrong),
                win=(min(w[2] for w in valids), max(w[2] for w in valids)) if valids else None,
                beats_after_leave=[round(b, 2) for b in beats if b > contact_to])

CASES = [
    ('clean fingertip 45',      dict(hr=45)),
    ('clean fingertip 60',      dict(hr=60)),
    ('clean fingertip 72',      dict(hr=72)),
    ('clean fingertip 95',      dict(hr=95)),
    ('clean fingertip 120',     dict(hr=120)),
    ('clean fingertip 160',     dict(hr=160)),
    ('noisy fingertip',         dict(hr=72, noise=150)),
    ('weak wrist-like 0.28%',   dict(hr=72, amp=250, noise=40)),
    ('weak + HR 50',            dict(hr=50, amp=250, noise=40)),
    ('weak + HR 45',            dict(hr=45, amp=250, noise=40)),
    ('weak + HR 120',           dict(hr=120, amp=250, noise=40)),
    ('very weak 0.13%',         dict(hr=72, amp=120, noise=40)),
    ('very weak + HR 50',       dict(hr=50, amp=120, noise=40)),
    ('weak, noisier',           dict(hr=72, amp=250, noise=80)),
    ('weak, drift 2000',        dict(hr=72, amp=250, noise=40, drift=2000)),
    ('motion 8-12 s',           dict(hr=72, artifact=(8, 12))),
    ('finger leaves at 12 s',   dict(hr=72, seconds=16, contact_to=12)),
    ('NO PULSE, just noise',    dict(hr=72, amp=0, noise=40)),
    ('NO PULSE, big drift',     dict(hr=72, amp=0, noise=40, drift=3000)),
    ('NO PULSE, no drift',      dict(hr=72, amp=0, noise=40, drift=0)),
]

if __name__ == '__main__':
    fmt = lambda r: f"{r[0]:5.1f}-{r[1]:5.1f}" if r else "   --      "
    print(f"{'scenario':24s} {'HR':>3s} | beat n  range        ghosts | win valid wrong range")
    total_wrong = 0
    for label, kw in CASES:
        r = run(**kw)
        total_wrong += r['win_wrong']
        extra = f"  beats after leave: {r['beats_after_leave']}" if 'contact_to' in kw else ''
        print(f"{label:24s} {kw['hr']:3d} | {r['beats']:3d}  {fmt(r['beat'])}  {r['ghosts']:3d}   | "
              f"{r['win_valid']:2d}/{r['win_total']:2d}  {r['win_wrong']:3d}   {fmt(r['win'])}{extra}")
    print(f"\nwindow estimator wrong answers across all cases: {total_wrong}  (target: 0)")
