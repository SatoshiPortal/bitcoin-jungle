import 'package:dio/dio.dart';

import '../models/place_submission_model.dart';

/// The proxy in front of BTC Map's submission API.
class AddPlaceDatasource {
  final Dio _dio;

  AddPlaceDatasource({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  /// Throws [DioException] when the proxy cannot be reached or does not answer 2xx.
  Future<void> submit(Uri url, PlaceSubmissionModel model) async {
    await _dio.postUri<Object?>(url, data: model.json);
  }
}
