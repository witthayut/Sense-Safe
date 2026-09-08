import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_drive/models/survey.dart';
import 'package:haptic_drive/models/trip_survey.dart';
import 'package:haptic_drive/models/vibration_profile.dart';
import 'package:haptic_drive/services/hapu_ema.dart';

VibrationProfile profile({double intensity = 0.6, int lead = 5}) =>
    VibrationProfile(
      scores: const {ProfileDimension.attention: 0.85},
      intensity: intensity,
      leadTimeSeconds: lead,
      rhythm: HapticRhythm.medium,
      spatialType: 'ADHD-leaning',
    );

TripSurvey survey({
  SurveyTiming timing = SurveyTiming.justRight,
  SurveyStrength strength = SurveyStrength.justRight,
}) =>
    TripSurvey(
      missedTurns: false,
      timing: timing,
      strength: strength,
      confusing: false,
      comfort: 4,
      at: DateTime(2026, 7, 21, 9),
    );

void main() {
  group('HAPU EMA — intensity (report §3.4, α=0.3)', () {
    test('"too strong" lowers intensity by exactly α × step = 0.09', () {
      final r = HapuEma.apply(
          profile(intensity: 0.6), survey(strength: SurveyStrength.tooStrong));
      expect(r.intensity, closeTo(0.51, 1e-9));
    });

    test('"too soft" raises intensity by exactly 0.09', () {
      final r = HapuEma.apply(
          profile(intensity: 0.6), survey(strength: SurveyStrength.tooSoft));
      expect(r.intensity, closeTo(0.69, 1e-9));
    });

    test('"just right" returns the EXACT same value — no floating-point drift',
        () {
      final r = HapuEma.apply(profile(intensity: 0.6), survey());
      expect(r.intensity, 0.6); // identical, not closeTo
      expect(r.leadTimeSeconds, 5);
    });

    test('repeated "too soft" converges toward max and never exceeds 1.0', () {
      var p = profile(intensity: 0.9);
      for (var trip = 0; trip < 50; trip++) {
        final r =
            HapuEma.apply(p, survey(strength: SurveyStrength.tooSoft));
        expect(r.intensity, lessThanOrEqualTo(HapuEma.maxIntensity));
        expect(r.intensity, greaterThanOrEqualTo(p.intensity)); // monotonic up
        p = p.copyWith(intensity: r.intensity);
      }
      expect(p.intensity, closeTo(1.0, 0.01));
    });

    test('repeated "too strong" never goes below the Settings minimum (0.1)',
        () {
      var p = profile(intensity: 0.2);
      for (var trip = 0; trip < 50; trip++) {
        final r =
            HapuEma.apply(p, survey(strength: SurveyStrength.tooStrong));
        expect(r.intensity, greaterThanOrEqualTo(HapuEma.minIntensity));
        p = p.copyWith(intensity: r.intensity);
      }
      expect(p.intensity, closeTo(HapuEma.minIntensity, 0.01));
    });
  });

  group('HAPU EMA — lead time', () {
    test('"too late" means the user wants MORE warning: 5s → 6s', () {
      final r = HapuEma.apply(
          profile(lead: 5), survey(timing: SurveyTiming.tooLate));
      expect(r.leadTimeSeconds, 6); // 0.3×8 + 0.7×5 = 5.9 → 6
    });

    test('"too early" means LESS warning: 5s → 4s', () {
      final r = HapuEma.apply(
          profile(lead: 5), survey(timing: SurveyTiming.tooEarly));
      expect(r.leadTimeSeconds, 4); // 0.3×2 + 0.7×5 = 4.1 → 4
    });

    test('clamps to the Settings slider range 2..10', () {
      final low = HapuEma.apply(
          profile(lead: 2), survey(timing: SurveyTiming.tooEarly));
      expect(low.leadTimeSeconds, HapuEma.minLeadSeconds);
      final high = HapuEma.apply(
          profile(lead: 10), survey(timing: SurveyTiming.tooLate));
      expect(high.leadTimeSeconds, HapuEma.maxLeadSeconds);
    });

    test('repeated "too late" walks up one second at a time to the cap', () {
      var p = profile(lead: 5);
      final seen = <int>[];
      for (var trip = 0; trip < 12; trip++) {
        final r = HapuEma.apply(p, survey(timing: SurveyTiming.tooLate));
        seen.add(r.leadTimeSeconds);
        p = p.copyWith(leadTimeSeconds: r.leadTimeSeconds);
      }
      expect(seen.first, 6);
      expect(seen.last, HapuEma.maxLeadSeconds);
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i] - seen[i - 1], inInclusiveRange(0, 1)); // smooth, no jumps
      }
    });
  });

  group('TripSurvey model', () {
    test('survives a Firestore round-trip', () {
      final original = survey(
          timing: SurveyTiming.tooLate, strength: SurveyStrength.tooSoft);
      final restored = TripSurvey.fromMap(original.toMap());
      expect(restored, isNotNull);
      expect(restored!.timing, SurveyTiming.tooLate);
      expect(restored.strength, SurveyStrength.tooSoft);
      expect(restored.comfort, 4);
      expect(restored.at, original.at);
    });

    test('malformed data is rejected or safely defaulted', () {
      expect(TripSurvey.fromMap(null), isNull);
      expect(TripSurvey.fromMap({'timing': 'tooLate'}), isNull); // no date
      final odd = TripSurvey.fromMap({
        'at': '2026-07-21T09:00:00.000',
        'timing': 'garbage',
        'comfort': 99,
      });
      expect(odd, isNotNull);
      expect(odd!.timing, SurveyTiming.justRight); // safe default
      expect(odd.comfort, 5); // clamped
    });
  });
}
