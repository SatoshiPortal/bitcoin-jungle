import 'dart:math' as math;

import 'package:btc_map/btc_map.dart' show GeoBounds, GeoPoint;
import 'package:meta/meta.dart';

/// The area the location picker shows. The pin sits at its centre, and it only counts once the user has zoomed in far enough to tell one building from the next.
@immutable
final class PinArea {
  /// From the centre to the farthest corner: about street level on a phone.
  static const maxRadiusMetres = 500.0;

  /// Web Mercator, the map's projection, has no poles.
  static const _maxLatitude = 85.05112878;

  final GeoBounds bounds;

  const PinArea(this.bounds);

  bool get isCloseEnough => bounds.radiusMetres <= maxRadiusMetres;

  /// Where the pin points: the centre of the screen. The map is drawn in Web Mercator, so that is the middle in projected space, not the average of the two latitudes.
  GeoPoint get pin => GeoPoint(
    latitude: _latitude((_project(bounds.south) + _project(bounds.north)) / 2),
    longitude: bounds.center.longitude,
  );

  static double _project(double latitude) {
    final clamped = latitude.clamp(-_maxLatitude, _maxLatitude);
    return math.log(math.tan(math.pi / 4 + clamped * math.pi / 360));
  }

  static double _latitude(double projected) =>
      (2 * math.atan(math.exp(projected)) - math.pi / 2) * 180 / math.pi;
}
