import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:btc_map/src/domain/entities/geo_bounds.dart';

/// The zoom at which [bounds] fills a map of [size] logical pixels. MapLibre draws Web Mercator with 512-pixel tiles.
double zoomToFit(GeoBounds bounds, Size size) {
  const tile = 512.0;
  double project(double latitude) => math.log(
    math.tan(math.pi / 4 + latitude.clamp(-85.0511, 85.0511) * math.pi / 360),
  );
  double log2(double value) =>
      value > 0 && value.isFinite ? math.log(value) / math.ln2 : 22.0;
  final lonSpan = bounds.crossesAntimeridian
      ? bounds.east + 360 - bounds.west
      : bounds.east - bounds.west;
  final latFraction =
      (project(bounds.north) - project(bounds.south)) / (2 * math.pi);
  final byWidth = log2(size.width * 360 / (lonSpan * tile));
  final byHeight = log2(size.height / (latFraction * tile));
  return math.min(byWidth, byHeight).clamp(0.0, 22.0);
}
