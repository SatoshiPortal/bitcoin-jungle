import 'package:add_place/src/domain/entities/pin_area.dart';
import 'package:btc_map/btc_map.dart' show GeoBounds;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a street-level view is close enough, a city view is not', () {
    final street = PinArea(
      GeoBounds(south: 9.1650, west: -83.7400, north: 9.1690, east: -83.7380),
    );
    final city = PinArea(
      GeoBounds(south: 9.10, west: -83.80, north: 9.25, east: -83.70),
    );

    expect(street.isCloseEnough, isTrue);
    expect(city.isCloseEnough, isFalse);
  });

  test('the pin is the centre of the screen in the map projection', () {
    // At city zoom in Costa Rica, the plain average of the latitudes is about
    // 14 metres south of the screen's centre.
    final area = PinArea(
      GeoBounds(south: 9.0, west: -84.0, north: 9.6, east: -83.4),
    );

    expect(area.pin.latitude, closeTo(9.300129, 0.000002));
    expect(area.pin.longitude, closeTo(-83.7, 1e-9));
  });

  test(
    'at street level the pin matches the centre within a few centimetres',
    () {
      final bounds = GeoBounds(
        south: 9.1650,
        west: -83.7400,
        north: 9.1690,
        east: -83.7380,
      );

      expect(PinArea(bounds).pin.distanceTo(bounds.center), lessThan(0.05));
    },
  );
}
