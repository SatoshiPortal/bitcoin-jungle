import 'dart:ui' show Size;

import 'package:btc_map/src/domain/entities/geo_bounds.dart';
import 'package:btc_map/src/ui/zoom_to_fit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const view = Size(800, 600);

  test('a wide area is fitted to the width of the view', () {
    final wide = GeoBounds(
      south: 9.166,
      west: -83.75,
      north: 9.168,
      east: -83.73,
    );

    expect(zoomToFit(wide, view), closeTo(14.7796, 0.0001));
  });

  test('a tall area is fitted to the height of the view', () {
    final tall = GeoBounds(
      south: 9.165,
      west: -83.74,
      north: 9.169,
      east: -83.738,
    );

    expect(zoomToFit(tall, view), closeTo(16.6679, 0.0001));
  });

  test('an area across the date line is measured the short way round', () {
    final fiji = GeoBounds(
      south: -17.9,
      west: 179.9,
      north: -17.7,
      east: -179.9,
    );

    expect(zoomToFit(fiji, view), closeTo(10.9718, 0.0001));
  });

  test('the zoom stays within what the map can show', () {
    final world = GeoBounds(south: -85, west: -180, north: 85, east: 180);
    final point = GeoBounds(
      south: 9.1670,
      west: -83.7390,
      north: 9.1670,
      east: -83.7390,
    );

    expect(zoomToFit(world, view), greaterThanOrEqualTo(0));
    expect(zoomToFit(point, view), lessThanOrEqualTo(22));
  });
}
