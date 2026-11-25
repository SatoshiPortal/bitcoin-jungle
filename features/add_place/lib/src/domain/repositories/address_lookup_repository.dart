import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../add_place_failure.dart';

abstract interface class AddressLookupRepository {
  /// The street address at [location], in [languageCode] where available, or null when none is known there.
  @useResult
  Future<Result<String?, AddPlaceFailure>> addressAt(
    GeoPoint location, {
    required String languageCode,
  });
}
