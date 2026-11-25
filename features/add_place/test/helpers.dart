import 'package:add_place/src/data/datasources/add_place_datasource.dart';
import 'package:add_place/src/data/models/place_submission_model.dart';
import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/entities/payment_method.dart';
import 'package:add_place/src/domain/entities/place_category.dart';
import 'package:add_place/src/domain/entities/place_submission.dart';
import 'package:add_place/src/domain/repositories/place_submission_repository.dart';
import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primitives/primitives.dart';

final location = GeoPoint(latitude: 9.32185, longitude: -83.66886);

Result<PlaceSubmission, AddPlaceFailure> createPlace({
  String name = 'Soda Tica',
  PlaceCategory? category = PlaceCategory.restaurants,
  String? otherCategory,
  Set<PaymentMethod> paymentMethods = const {PaymentMethod.lightning},
  String? contact = 'owner@example.com',
  String? address,
  String? notes,
}) => PlaceSubmission.create(
  name: name,
  location: location,
  category: category,
  otherCategory: otherCategory,
  paymentMethods: paymentMethods,
  contact: contact,
  address: address,
  notes: notes,
);

T ok<T>(Result<T, AddPlaceFailure> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final failure) => fail('expected Ok, got $failure'),
};

AddPlaceFailure err<T>(Result<T, AddPlaceFailure> result) => switch (result) {
  Err(:final failure) => failure,
  Ok() => fail('expected a failure'),
};

/// Records what would be posted, or throws what the test sets.
class FakeDatasource extends AddPlaceDatasource {
  final List<(Uri, Map<String, Object>)> posted = [];
  DioException? error;

  FakeDatasource() : super(dio: Dio());

  @override
  Future<void> submit(Uri url, PlaceSubmissionModel model) async {
    if (error case final error?) throw error;
    posted.add((url, model.json));
  }
}

/// A repository whose answer the test sets.
class FakeRepository implements PlaceSubmissionRepository {
  Result<void, AddPlaceFailure> result = const Ok(null);
  final List<PlaceSubmission> submitted = [];

  @override
  Future<Result<void, AddPlaceFailure>> submit(PlaceSubmission place) async {
    submitted.add(place);
    return result;
  }
}
