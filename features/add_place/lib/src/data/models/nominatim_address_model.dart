/// Nominatim's reverse geocoding answer (`format=jsonv2`, `addressdetails=1`).
final class NominatimAddressModel {
  final String? road;
  final String? houseNumber;
  final String? postcode;

  /// The most specific settlement: village, town, city or municipality.
  final String? settlement;
  final String? displayName;

  const NominatimAddressModel({
    this.road,
    this.houseNumber,
    this.postcode,
    this.settlement,
    this.displayName,
  });

  /// Null when Nominatim knows no address at the point (it answers 200 with an `error`). Throws [FormatException] when the answer is not an object.
  static NominatimAddressModel? fromJson(Object? json) {
    if (json is! Map<String, Object?>) {
      throw const FormatException('not a Nominatim answer');
    }
    if (json['error'] != null) return null;
    final parts = json['address'];
    String? part(String key) =>
        parts is Map<String, Object?> ? _text(parts[key]) : null;
    return NominatimAddressModel(
      road: part('road'),
      houseNumber: part('house_number'),
      postcode: part('postcode'),
      settlement:
          part('village') ??
          part('town') ??
          part('city') ??
          part('municipality'),
      displayName: _text(json['display_name']),
    );
  }

  static String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
