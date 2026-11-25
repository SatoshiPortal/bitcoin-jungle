import 'package:add_place/src/data/place_submission_repository_impl.dart';
import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/entities/payment_method.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final url = Uri.parse('https://proxy.example/submit');

  test('without a proxy url nothing is sent', () async {
    final datasource = FakeDatasource();
    final repository = PlaceSubmissionRepositoryImpl(datasource, null);

    final result = await repository.submit(ok(createPlace()));

    expect(err(result), isA<AddPlaceUnavailableFailure>());
    expect(datasource.posted, isEmpty);
  });

  test('sends the BTC Map fields, leaving empty optionals out', () async {
    final datasource = FakeDatasource();
    final repository = PlaceSubmissionRepositoryImpl(datasource, url);

    ok(
      await repository.submit(
        ok(
          createPlace(
            paymentMethods: {PaymentMethod.onchain, PaymentMethod.nfc},
            address: 'Uvita',
          ),
        ),
      ),
    );

    final (postedUrl, body) = datasource.posted.single;
    expect(postedUrl, url);
    expect(body, {
      'name': 'Soda Tica',
      'lat': 9.32185,
      'lon': -83.66886,
      'category': 'restaurants',
      'payment_methods': ['onchain', 'nfc'],
      'contact': 'owner@example.com',
      'address': 'Uvita',
    });
  });

  test('no contact email means no contact field', () async {
    final datasource = FakeDatasource();
    final repository = PlaceSubmissionRepositoryImpl(datasource, url);

    ok(await repository.submit(ok(createPlace(contact: ''))));

    final (_, body) = datasource.posted.single;
    expect(body.containsKey('contact'), isFalse);
  });

  test("payment methods are sent in BTC Map's order", () async {
    final datasource = FakeDatasource();
    final repository = PlaceSubmissionRepositoryImpl(datasource, url);

    ok(
      await repository.submit(
        ok(
          createPlace(
            paymentMethods: {PaymentMethod.nfc, PaymentMethod.onchain},
          ),
        ),
      ),
    );

    final (_, body) = datasource.posted.single;
    expect(body['payment_methods'], ['onchain', 'nfc']);
  });

  test('a refused request is not reported as a connection problem', () async {
    final datasource = FakeDatasource()
      ..error = DioException(
        requestOptions: RequestOptions(path: '/submit'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/submit'),
          statusCode: 422,
        ),
      );
    final repository = PlaceSubmissionRepositoryImpl(datasource, url);

    final result = await repository.submit(ok(createPlace()));

    expect(err(result), isA<AddPlaceRejectedFailure>());
  });

  test('a network error becomes a network failure', () async {
    final datasource = FakeDatasource()
      ..error = DioException(
        requestOptions: RequestOptions(path: '/submit'),
        type: DioExceptionType.connectionError,
      );
    final repository = PlaceSubmissionRepositoryImpl(datasource, url);

    final result = await repository.submit(ok(createPlace()));

    expect(err(result), isA<AddPlaceNetworkFailure>());
  });
}
