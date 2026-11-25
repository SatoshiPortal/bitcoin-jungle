import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/entities/payment_method.dart';
import 'package:add_place/src/domain/entities/place_category.dart';
import 'package:add_place/src/domain/usecases/submit_place_usecase.dart';
import 'package:add_place/src/presentation/add_place_cubit.dart';
import 'package:add_place/src/presentation/add_place_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:primitives/primitives.dart';

import 'helpers.dart';

void main() {
  late FakeRepository repository;
  late AddPlaceCubit cubit;

  setUp(() {
    repository = FakeRepository();
    cubit = AddPlaceCubit(SubmitPlaceUsecase(repository));
  });

  tearDown(() => cubit.close());

  Future<void> submit({String contact = 'owner@example.com'}) => cubit.submit(
    name: 'Soda Tica',
    location: location,
    category: PlaceCategory.coffee,
    paymentMethods: {PaymentMethod.lightning},
    contact: contact,
  );

  test('a valid place is sent and ends as sent', () async {
    final states = <AddPlaceState>[];
    final subscription = cubit.stream.listen(states.add);

    await submit();
    await subscription.cancel();

    expect(states.first, isA<AddPlaceSending>());
    expect(cubit.state, isA<AddPlaceSent>());
    expect(repository.submitted.single.category, 'coffee');
  });

  test('an invalid place fails without reaching the repository', () async {
    await submit(contact: 'not an email');

    expect(switch (cubit.state) {
      AddPlaceFailed(:final failure) => failure,
      _ => null,
    }, isA<ContactEmailInvalidFailure>());
    expect(repository.submitted, isEmpty);
  });

  test('a repository failure is shown', () async {
    repository.result = const Err(AddPlaceUnavailableFailure());

    await submit();

    expect(switch (cubit.state) {
      AddPlaceFailed(:final failure) => failure,
      _ => null,
    }, isA<AddPlaceUnavailableFailure>());
  });
}
