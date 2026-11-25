import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:primitives/primitives.dart';

import '../domain/add_place_failure.dart';
import '../domain/entities/place_submission.dart';
import '../domain/repositories/place_submission_repository.dart';
import 'datasources/add_place_datasource.dart';
import 'models/place_submission_model.dart';

/// The one place exceptions are caught: everything leaving it is an [AddPlaceFailure].
final class PlaceSubmissionRepositoryImpl implements PlaceSubmissionRepository {
  final AddPlaceDatasource _datasource;

  /// The proxy to BTC Map. Null until it exists, and then nothing is sent.
  final Uri? _submitUrl;

  PlaceSubmissionRepositoryImpl(this._datasource, this._submitUrl);

  @override
  @useResult
  Future<Result<void, AddPlaceFailure>> submit(PlaceSubmission place) async {
    final url = _submitUrl;
    if (url == null) return const Err(AddPlaceUnavailableFailure());
    try {
      await _datasource.submit(url, PlaceSubmissionModel.fromEntity(place));
      return const Ok(null);
    } on DioException catch (error) {
      return Err(switch (error.type) {
        DioExceptionType.badResponse => AddPlaceRejectedFailure(
          'status=${error.response?.statusCode}',
        ),
        _ => AddPlaceNetworkFailure(error.type.name),
      });
    }
  }
}
