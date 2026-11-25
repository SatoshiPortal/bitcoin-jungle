import 'dart:async';

import 'package:add_place/src/data/address_lookup_repository_impl.dart';
import 'package:add_place/src/data/datasources/address_lookup_datasource.dart';
import 'package:add_place/src/data/models/nominatim_address_model.dart';
import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/repositories/address_lookup_repository.dart';
import 'package:add_place/src/domain/usecases/suggest_address_usecase.dart';
import 'package:add_place/src/presentation/address_suggestion_cubit.dart';
import 'package:btc_map/btc_map.dart' show GeoPoint;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primitives/primitives.dart';

import 'helpers.dart';

/// Answers like Nominatim, counting requests, or throws what the test sets.
class _FakeDatasource extends AddressLookupDatasource {
  NominatimAddressModel? answer;
  Exception? error;
  int requests = 0;

  _FakeDatasource() : super(dio: Dio());

  @override
  Future<NominatimAddressModel?> reverse({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    requests++;
    if (error case final error?) throw error;
    return answer;
  }
}

/// Answers each lookup when the test completes it.
class _ControlledLookup implements AddressLookupRepository {
  final List<Completer<Result<String?, AddPlaceFailure>>> pending = [];

  @override
  Future<Result<String?, AddPlaceFailure>> addressAt(
    GeoPoint location, {
    required String languageCode,
  }) {
    final completer = Completer<Result<String?, AddPlaceFailure>>();
    pending.add(completer);
    return completer.future;
  }
}

void main() {
  group('Nominatim answer', () {
    test('reads the parts, the most specific settlement first', () {
      final model = NominatimAddressModel.fromJson({
        'display_name':
            'Soda Tica, Calle 5, Uvita, Osa, Puntarenas, Costa Rica',
        'address': {
          'road': 'Calle 5',
          'house_number': '12',
          'postcode': '60504',
          'village': 'Uvita',
          'city': 'Osa',
        },
      });

      expect(model?.road, 'Calle 5');
      expect(model?.houseNumber, '12');
      expect(model?.postcode, '60504');
      expect(model?.settlement, 'Uvita');
    });

    test('no address at the point means no suggestion', () {
      expect(
        NominatimAddressModel.fromJson({'error': 'Unable to geocode'}),
        isNull,
      );
      expect(
        () => NominatimAddressModel.fromJson('not json'),
        throwsFormatException,
      );
    });
  });

  test(
    'the request names the app and asks for a building-level address',
    () async {
      final requests = <RequestOptions>[];
      final dio =
          Dio(
              BaseOptions(
                headers: {'User-Agent': AddressLookupDatasource.userAgent},
              ),
            )
            ..interceptors.add(
              InterceptorsWrapper(
                onRequest: (options, handler) {
                  requests.add(options);
                  handler.resolve(
                    Response(requestOptions: options, data: {'error': 'none'}),
                  );
                },
              ),
            );

      await AddressLookupDatasource(dio: dio)
          .reverse(latitude: 9.167, longitude: -83.739, languageCode: 'es');

      final request = requests.single;
      expect(request.uri.host, 'nominatim.openstreetmap.org');
      expect(request.headers['User-Agent'], startsWith('BitcoinJungle'));
      expect(request.uri.queryParameters, {
        'lat': '9.167',
        'lon': '-83.739',
        'format': 'jsonv2',
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'es',
      });
    },
  );

  group('repository', () {
    Future<String?> suggest(NominatimAddressModel answer) async => ok(
      await AddressLookupRepositoryImpl(_FakeDatasource()..answer = answer)
          .addressAt(location, languageCode: 'en'),
    );

    test(
      'suggests one line like BTC Map: road and number, then postcode and town',
      () async {
        expect(
          await suggest(
            const NominatimAddressModel(
              road: 'Calle 5',
              houseNumber: '12',
              postcode: '60504',
              settlement: 'Uvita',
            ),
          ),
          'Calle 5 12, 60504 Uvita',
        );
      },
    );

    test('falls back to the full name when there are no parts', () async {
      expect(
        await suggest(
          const NominatimAddressModel(displayName: 'Playa Uvita, Costa Rica'),
        ),
        'Playa Uvita, Costa Rica',
      );
    });

    test('a spot already looked up sends no new request', () async {
      final datasource = _FakeDatasource()
        ..answer = const NominatimAddressModel(road: 'Calle 5');
      final repository = AddressLookupRepositoryImpl(datasource);

      final first = await repository.addressAt(location, languageCode: 'en');
      final again = await repository.addressAt(location, languageCode: 'en');

      expect(ok(first), 'Calle 5');
      expect(ok(again), 'Calle 5');
      expect(datasource.requests, 1);
    });

    test(
      'an unreadable answer is not remembered, so the next try asks again',
      () async {
        final datasource = _FakeDatasource()
          ..error = const FormatException('not a Nominatim answer');
        final repository = AddressLookupRepositoryImpl(datasource);

        final first = await repository.addressAt(location, languageCode: 'en');
        datasource
          ..error = null
          ..answer = const NominatimAddressModel(road: 'Calle 5');
        final again = await repository.addressAt(location, languageCode: 'en');

        expect(err(first), isA<AddPlaceNetworkFailure>());
        expect(ok(again), 'Calle 5');
        expect(datasource.requests, 2);
      },
    );

    test('no address at a spot is remembered', () async {
      final datasource = _FakeDatasource();
      final repository = AddressLookupRepositoryImpl(datasource);

      expect(
        ok(await repository.addressAt(location, languageCode: 'en')),
        isNull,
      );
      expect(
        ok(await repository.addressAt(location, languageCode: 'en')),
        isNull,
      );
      expect(datasource.requests, 1);
    });

    test('a network error becomes a failure', () async {
      final datasource = _FakeDatasource()
        ..error = DioException(
          requestOptions: RequestOptions(path: '/reverse'),
          type: DioExceptionType.connectionTimeout,
        );

      final result = await AddressLookupRepositoryImpl(datasource)
          .addressAt(location, languageCode: 'en');

      expect(err(result), isA<AddPlaceNetworkFailure>());
    });
  });

  test('the use-case asks the repository in the given language', () async {
    final datasource = _FakeDatasource()
      ..answer = const NominatimAddressModel(settlement: 'Uvita');

    final result = await SuggestAddressUsecase(
      AddressLookupRepositoryImpl(datasource),
    ).execute(location, languageCode: 'es');

    expect(ok(result), 'Uvita');
  });

  group('suggestion cubit', () {
    test('a found address is suggested, a failure suggests nothing', () async {
      final lookup = _ControlledLookup();
      final cubit = AddressSuggestionCubit(SuggestAddressUsecase(lookup));
      addTearDown(cubit.close);

      final found = cubit.suggestFor(location, languageCode: 'en');
      expect(cubit.state, isA<AddressSuggestionLoading>());
      lookup.pending.single.complete(const Ok('Calle 5'));
      await found;
      expect(switch (cubit.state) {
        AddressSuggested(:final address) => address,
        _ => null,
      }, 'Calle 5');

      final failed = cubit.suggestFor(location, languageCode: 'en');
      lookup.pending.last.complete(const Err(AddPlaceNetworkFailure()));
      await failed;
      expect(cubit.state, isA<AddressNotFound>());
    });

    test('a late answer for an earlier pin is ignored', () async {
      final lookup = _ControlledLookup();
      final cubit = AddressSuggestionCubit(SuggestAddressUsecase(lookup));
      addTearDown(cubit.close);

      final earlier = cubit.suggestFor(location, languageCode: 'en');
      final later = cubit.suggestFor(
        GeoPoint(latitude: 9.2, longitude: -83.7),
        languageCode: 'en',
      );
      lookup.pending.last.complete(const Ok('New street'));
      await later;
      lookup.pending.first.complete(const Ok('Old street'));
      await earlier;

      expect(switch (cubit.state) {
        AddressSuggested(:final address) => address,
        _ => null,
      }, 'New street');
    });
  });
}
