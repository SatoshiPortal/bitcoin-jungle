import 'package:primitives/primitives.dart';

/// Why a place could not be sent.
sealed class AddPlaceFailure extends Failure {
  const AddPlaceFailure([super.logMessage]);
}

/// The proxy is not configured yet, so nothing can be sent.
final class AddPlaceUnavailableFailure extends AddPlaceFailure {
  const AddPlaceUnavailableFailure() : super('no submit url');
}

/// The proxy could not be reached.
final class AddPlaceNetworkFailure extends AddPlaceFailure {
  const AddPlaceNetworkFailure([super.logMessage]);
}

/// The proxy was reached but did not accept the place.
final class AddPlaceRejectedFailure extends AddPlaceFailure {
  const AddPlaceRejectedFailure([super.logMessage]);
}

/// A place needs a name.
final class PlaceNameMissingFailure extends AddPlaceFailure {
  const PlaceNameMissingFailure() : super('name missing');
}

/// A place needs a category.
final class PlaceCategoryMissingFailure extends AddPlaceFailure {
  const PlaceCategoryMissingFailure() : super('category missing');
}

/// The user chose "Other" and must name the category.
final class PlaceOtherCategoryMissingFailure extends AddPlaceFailure {
  const PlaceOtherCategoryMissingFailure() : super('other category missing');
}

/// A place needs at least one payment method.
final class PaymentMethodMissingFailure extends AddPlaceFailure {
  const PaymentMethodMissingFailure() : super('payment method missing');
}

/// The optional contact email was given but is not a valid email.
final class ContactEmailInvalidFailure extends AddPlaceFailure {
  const ContactEmailInvalidFailure() : super('contact email invalid');
}
