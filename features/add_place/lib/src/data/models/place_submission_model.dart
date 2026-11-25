import '../../domain/entities/payment_method.dart';
import '../../domain/entities/place_submission.dart';

/// The JSON body sent to the proxy, mirroring BTC Map's `submit_place`. Empty optional fields are left out.
final class PlaceSubmissionModel {
  final Map<String, Object> json;

  const PlaceSubmissionModel(this.json);

  factory PlaceSubmissionModel.fromEntity(PlaceSubmission place) =>
      PlaceSubmissionModel({
        'name': place.name,
        'lat': place.location.latitude,
        'lon': place.location.longitude,
        'category': place.category,
        // In BTC Map's order, whatever order the user tapped them in.
        'payment_methods': [
          for (final method in PaymentMethod.values)
            if (place.paymentMethods.contains(method)) method.apiValue,
        ],
        'contact': ?place.contact,
        'address': ?place.address,
        'website': ?place.website,
        'phone': ?place.phone,
        'opening_hours': ?place.openingHours,
        'notes': ?place.notes,
      });
}
