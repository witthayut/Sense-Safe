/// One completed/started drive, recorded when the user taps "Start drive".
/// Powers the Home tab's "Resume last route" card and Recent trips section.
class RecentTrip {
  const RecentTrip({
    required this.destination,
    required this.durationSec,
    required this.at,
  });

  /// Full routable destination text (came from a successful route search).
  final String destination;

  /// Route duration at the time of the trip, for the "· 18 min" meta.
  final int durationSec;

  /// When the trip was started.
  final DateTime at;

  /// Short display name — first part of the place description.
  String get label => destination.split(',').first.trim();

  /// "Today · 18 min" / "Yesterday · 32 min" / "3 days ago · 41 min".
  String metaText(DateTime now) {
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(at.year, at.month, at.day))
        .inDays;
    final when = days <= 0
        ? 'Today'
        : days == 1
            ? 'Yesterday'
            : '$days days ago';
    return '$when · ${(durationSec / 60).round()} min';
  }

  Map<String, dynamic> toMap() => {
        'destination': destination,
        'durationSec': durationSec,
        'at': at.toIso8601String(),
      };

  static RecentTrip? fromMap(dynamic data) {
    if (data is! Map) return null;
    final destination = data['destination'] as String?;
    final at = DateTime.tryParse(data['at'] as String? ?? '');
    if (destination == null || at == null) return null;
    return RecentTrip(
      destination: destination,
      durationSec: (data['durationSec'] as num?)?.toInt() ?? 0,
      at: at,
    );
  }
}
