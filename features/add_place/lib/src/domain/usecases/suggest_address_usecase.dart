import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../add_place_failure.dart';
import '../repositories/address_lookup_repository.dart';

/// The address at the pin, as a suggestion the user can correct.
class SuggestAddressUsecase {
  final AddressLookupRepository _repository;

  const SuggestAddressUsecase(this._repository);

  @useResult
  Future<Result<String?, AddPlaceFailure>> execute(
    GeoPoint location, {
    required String languageCode,
  }) => _repository.addressAt(location, languageCode: languageCode);
}
