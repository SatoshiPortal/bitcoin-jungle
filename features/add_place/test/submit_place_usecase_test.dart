import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/entities/payment_method.dart';
import 'package:add_place/src/domain/usecases/submit_place_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primitives/primitives.dart';

import 'helpers.dart';

void main() {
  late FakeRepository repository;
  late SubmitPlaceUsecase usecase;

  setUp(() {
    repository = FakeRepository();
    usecase = SubmitPlaceUsecase(repository);
  });

  test('a valid place reaches the repository', () async {
    ok(
      await usecase.execute(
        name: 'Surf Shack',
        location: location,
        category: null,
        otherCategory: 'Surf shop',
        paymentMethods: {PaymentMethod.onchain},
        contact: 'owner@example.com',
      ),
    );

    expect(repository.submitted.single.category, 'Surf shop');
  });

  test('an invalid place is refused before the repository', () async {
    final result = await usecase.execute(
      name: 'Surf Shack',
      location: location,
      category: null,
      paymentMethods: {PaymentMethod.onchain},
      contact: 'owner@example.com',
    );

    expect(err(result), isA<PlaceCategoryMissingFailure>());
    expect(repository.submitted, isEmpty);
  });

  test('a repository failure is passed on', () async {
    repository.result = const Err(AddPlaceNetworkFailure());

    final result = await usecase.execute(
      name: 'Surf Shack',
      location: location,
      category: null,
      otherCategory: 'Surf shop',
      paymentMethods: {PaymentMethod.onchain},
      contact: 'owner@example.com',
    );

    expect(err(result), isA<AddPlaceNetworkFailure>());
  });
}
