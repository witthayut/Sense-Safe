import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_drive/models/favourite.dart';

void main() {
  test('Favourite survives a Firestore round-trip (toMap → fromMap)', () {
    const original = Favourite(
      label: 'มอ',
      destination: 'Mahidol University, Salaya, Nakhon Pathom, Thailand',
    );
    final restored = Favourite.fromMap(original.toMap());
    expect(restored, isNotNull);
    expect(restored!.label, original.label);
    expect(restored.destination, original.destination);
  });

  test('fromMap rejects malformed data instead of crashing', () {
    expect(Favourite.fromMap(null), isNull);
    expect(Favourite.fromMap('not a map'), isNull);
    expect(Favourite.fromMap({'label': 'Home'}), isNull); // no destination
    expect(Favourite.fromMap({'destination': 'x'}), isNull); // no label
  });
}
