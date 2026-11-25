import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../domain/add_place_failure.dart';
import '../domain/repositories/address_lookup_repository.dart';
import 'datasources/address_lookup_datasource.dart';
import 'models/nominatim_address_model.dart';

/// Looks up and remembers addresses, so moving back to a spot already looked up sends no new request.
final class AddressLookupRepositoryImpl implements AddressLookupRepository {
  final AddressLookupDatasource _datasource;

  /// Keyed by the point rounded to about a metre, and the language.
  final Map<String, String?> _cache = {};

  AddressLookupRepositoryImpl(this._datasource);

  @override
  @useResult
  Future<Result<String?, AddPlaceFailure>> addressAt(
    GeoPoint location, {
    required String languageCode,
  }) async {
    final key =
        '${location.latitude.toStringAsFixed(5)},'
        '${location.longitude.toStringAsFixed(5)},$languageCode';
    if (_cache.containsKey(key)) return Ok(_cache[key]);
    try {
      final model = await _datasource.reverse(
        latitude: location.latitude,
        longitude: location.longitude,
        languageCode: languageCode,
      );
      return Ok(_cache[key] = model == null ? null : _oneLine(model));
    } on DioException catch (error) {
      return Err(AddPlaceNetworkFailure(error.type.name));
    } on FormatException {
      // Not remembered: a later try may get a proper answer.
      return const Err(AddPlaceNetworkFailure('unreadable answer'));
    }
  }

  /// "Road 12, 12345 Town", as BTC Map's own form suggests it; the full display name only when there are no parts. Null when nothing is known.
  static String? _oneLine(NominatimAddressModel model) {
    final street = [model.road, model.houseNumber].nonNulls.join(' ');
    final locality = [model.postcode, model.settlement].nonNulls.join(' ');
    final line = [street, locality].where((s) => s.isNotEmpty).join(', ');
    return line.isNotEmpty ? line : model.displayName;
  }
}
