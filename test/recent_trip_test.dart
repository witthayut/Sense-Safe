import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_drive/models/recent_trip.dart';

void main() {
  final trip = RecentTrip(
    destination: 'Central Festival, Hat Yai, Songkhla, Thailand',
    durationSec: 1080, // 18 min
    at: DateTime(2026, 7, 14, 8, 30),
  );

  test('survives a Firestore round-trip (toMap → fromMap)', () {
    final restored = RecentTrip.fromMap(trip.toMap());
    expect(restored, isNotNull);
    expect(restored!.destination, trip.destination);
    expect(restored.durationSec, 1080);
    expect(restored.at, trip.at);
  });

  test('label is the first part of the place description', () {
    expect(trip.label, 'Central Festival');
  });

  test('metaText renders relative day + minutes', () {
    expect(trip.metaText(DateTime(2026, 7, 14, 20)), 'Today · 18 min');
    expect(trip.metaText(DateTime(2026, 7, 15, 6)), 'Yesterday · 18 min');
    expect(trip.metaText(DateTime(2026, 7, 17)), '3 days ago · 18 min');
  });

  test('fromMap rejects malformed data instead of crashing', () {
    expect(RecentTrip.fromMap(null), isNull);
    expect(RecentTrip.fromMap({'destination': 'x'}), isNull); // no timestamp
    expect(RecentTrip.fromMap({'at': 'not-a-date', 'destination': 'x'}), isNull);
  });
}
