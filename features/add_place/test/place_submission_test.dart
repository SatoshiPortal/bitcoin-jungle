import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/entities/payment_method.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('the required fields make a place, blank optionals are dropped', () {
    final place = ok(
      createPlace(name: '  Soda Tica ', address: ' ', notes: ''),
    );

    expect(place.name, 'Soda Tica');
    expect(place.category, 'restaurants');
    expect(place.paymentMethods, {PaymentMethod.lightning});
    expect(place.contact, 'owner@example.com');
    expect(place.address, isNull);
    expect(place.notes, isNull);
  });

  test('"Other" uses the typed category', () {
    final place = ok(createPlace(category: null, otherCategory: ' Surf shop '));

    expect(place.category, 'Surf shop');
  });

  test('missing required fields are refused', () {
    expect(err(createPlace(name: ' ')), isA<PlaceNameMissingFailure>());
    expect(
      err(createPlace(category: null, otherCategory: ' ')),
      isA<PlaceOtherCategoryMissingFailure>(),
    );
    expect(
      err(createPlace(category: null)),
      isA<PlaceCategoryMissingFailure>(),
    );
    expect(
      err(createPlace(paymentMethods: {})),
      isA<PaymentMethodMissingFailure>(),
    );
  });

  test('the contact email is optional', () {
    expect(ok(createPlace(contact: '  ')).contact, isNull);
  });

  test('a contact email that is given must be valid', () {
    expect(
      err(createPlace(contact: 'owner@')),
      isA<ContactEmailInvalidFailure>(),
    );
    expect(
      err(createPlace(contact: 'own er@example.com')),
      isA<ContactEmailInvalidFailure>(),
    );
  });
}
