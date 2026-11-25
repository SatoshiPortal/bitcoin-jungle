import 'package:dio/dio.dart';

import '../models/nominatim_address_model.dart';

/// OpenStreetMap's Nominatim reverse geocoding, or a proxy that answers like it.
///
/// Usage policy (operations.osmfoundation.org/policies/nominatim, checked 2026-11-24): at most one request per second, a User-Agent that names the app, attribution (the map shown with the picker keeps OpenStreetMap's attribution visible), and a service that can be switched without an app update, hence the configurable [url].
class AddressLookupDatasource {
  static final defaultUrl = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse',
  );

  /// Names the app, as the policy requires; a library's default User-Agent is refused.
  static const userAgent =
      'BitcoinJungleWallet/1.0 (+https://bitcoinjungle.app)';

  /// Building level: the pin sits on the business entrance.
  static const _buildingZoom = 18;

  final Uri url;
  final Dio _dio;

  AddressLookupDatasource({Uri? url, Dio? dio})
    : url = url ?? defaultUrl,
      _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              headers: {'User-Agent': userAgent},
            ),
          );

  /// Throws [DioException] when the service cannot be reached, and [FormatException] when it answers with something unreadable.
  Future<NominatimAddressModel?> reverse({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    final response = await _dio.getUri<Object?>(
      url.replace(
        queryParameters: {
          ...url.queryParameters,
          'lat': '$latitude',
          'lon': '$longitude',
          'format': 'jsonv2',
          'zoom': '$_buildingZoom',
          'addressdetails': '1',
          'accept-language': languageCode,
        },
      ),
    );
    return NominatimAddressModel.fromJson(response.data);
  }
}
