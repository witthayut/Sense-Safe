/// A saved destination: a short user-chosen label ("Home", "มอ") plus the
/// full destination text that is guaranteed routable — favourites are only
/// created from a successful route search (Routes tab ⭐), never typed free-
/// hand, so tapping one can't produce a "no route found" surprise.
class Favourite {
  const Favourite({required this.label, required this.destination});

  final String label;
  final String destination;

  Map<String, dynamic> toMap() => {
        'label': label,
        'destination': destination,
      };

  static Favourite? fromMap(dynamic data) {
    if (data is! Map) return null;
    final label = data['label'] as String?;
    final destination = data['destination'] as String?;
    if (label == null || destination == null) return null;
    return Favourite(label: label, destination: destination);
  }
}
