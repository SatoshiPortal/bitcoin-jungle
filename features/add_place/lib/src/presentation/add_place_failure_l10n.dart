import 'package:bull_ui/bull_ui.dart' show BuildContext;

import '../domain/add_place_failure.dart';
import 'add_place_localizations_x.dart';

extension AddPlaceFailureL10n on AddPlaceFailure {
  String toTranslated(BuildContext context) => switch (this) {
    AddPlaceUnavailableFailure() => context.addPlaceLoc.addPlaceUnavailable,
    AddPlaceNetworkFailure() => context.addPlaceLoc.addPlaceNetworkFailure,
    AddPlaceRejectedFailure() => context.addPlaceLoc.addPlaceRejected,
    PlaceNameMissingFailure() => context.addPlaceLoc.placeNameRequired,
    PlaceCategoryMissingFailure() => context.addPlaceLoc.placeCategoryRequired,
    PlaceOtherCategoryMissingFailure() =>
      context.addPlaceLoc.placeOtherCategoryRequired,
    PaymentMethodMissingFailure() => context.addPlaceLoc.paymentMethodRequired,
    ContactEmailInvalidFailure() => context.addPlaceLoc.contactEmailInvalid,
  };
}
