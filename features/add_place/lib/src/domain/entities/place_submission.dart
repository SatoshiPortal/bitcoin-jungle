import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../add_place_failure.dart';
import 'payment_method.dart';
import 'place_category.dart';

/// A place to submit to BTC Map. Only [create] builds one, so it always has BTC Map's required fields.
@immutable
final class PlaceSubmission {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final String name;
  final GeoPoint location;

  /// A BTC Map category value, or the user's own text for "Other".
  final String category;
  final Set<PaymentMethod> paymentMethods;
  final String? contact;
  final String? address;
  final String? website;
  final String? phone;
  final String? openingHours;
  final String? notes;

  const PlaceSubmission._({
    required this.name,
    required this.location,
    required this.category,
    required this.paymentMethods,
    this.contact,
    this.address,
    this.website,
    this.phone,
    this.openingHours,
    this.notes,
  });

  /// [category] null with a non-null [otherCategory] means the user chose "Other" and typed it.
  @useResult
  static Result<PlaceSubmission, AddPlaceFailure> create({
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
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Err(PlaceNameMissingFailure());
    final categoryValue = category?.apiValue ?? _blankToNull(otherCategory);
    if (categoryValue == null) {
      return Err(
        otherCategory == null
            ? const PlaceCategoryMissingFailure()
            : const PlaceOtherCategoryMissingFailure(),
      );
    }
    if (paymentMethods.isEmpty) {
      return const Err(PaymentMethodMissingFailure());
    }
    // Optional: checked only when given, for BTC Map to follow up.
    final trimmedContact = _blankToNull(contact);
    if (trimmedContact != null && !_email.hasMatch(trimmedContact)) {
      return const Err(ContactEmailInvalidFailure());
    }
    return Ok(
      PlaceSubmission._(
        name: trimmedName,
        location: location,
        category: categoryValue,
        paymentMethods: Set.unmodifiable(paymentMethods),
        contact: trimmedContact,
        address: _blankToNull(address),
        website: _blankToNull(website),
        phone: _blankToNull(phone),
        openingHours: _blankToNull(openingHours),
        notes: _blankToNull(notes),
      ),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
