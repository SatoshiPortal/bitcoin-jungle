import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../add_place_failure.dart';
import '../entities/payment_method.dart';
import '../entities/place_category.dart';
import '../entities/place_submission.dart';
import '../repositories/place_submission_repository.dart';

/// Validates a suggested place and sends it on.
class SubmitPlaceUsecase {
  final PlaceSubmissionRepository _repository;

  const SubmitPlaceUsecase(this._repository);

  @useResult
  Future<Result<void, AddPlaceFailure>> execute({
    required String name,
    required GeoPoint location,
    required PlaceCategory? category,
    String? otherCategory,
    required Set<PaymentMethod> paymentMethods,
    String? contact,
    String? address,
    String? website,
    String? phone,
    String? openingHours,
    String? notes,
  }) async {
    switch (PlaceSubmission.create(
      name: name,
      location: location,
      category: category,
      otherCategory: otherCategory,
      paymentMethods: paymentMethods,
      contact: contact,
      address: address,
      website: website,
      phone: phone,
      openingHours: openingHours,
      notes: notes,
    )) {
      case Ok(value: final place):
        return _repository.submit(place);
      case Err(:final failure):
        return Err(failure);
    }
  }
}
