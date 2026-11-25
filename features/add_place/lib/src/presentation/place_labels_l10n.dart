import 'package:bull_ui/bull_ui.dart' show BuildContext;

import '../domain/entities/payment_method.dart';
import '../domain/entities/place_category.dart';
import 'add_place_localizations_x.dart';

extension PlaceCategoryL10n on PlaceCategory {
  String label(BuildContext context) => switch (this) {
    PlaceCategory.restaurants => context.addPlaceLoc.categoryRestaurants,
    PlaceCategory.shopping => context.addPlaceLoc.categoryShopping,
    PlaceCategory.groceries => context.addPlaceLoc.categoryGroceries,
    PlaceCategory.coffee => context.addPlaceLoc.categoryCoffee,
    PlaceCategory.atms => context.addPlaceLoc.categoryAtms,
    PlaceCategory.hotels => context.addPlaceLoc.categoryHotels,
    PlaceCategory.beauty => context.addPlaceLoc.categoryBeauty,
  };
}

extension PaymentMethodL10n on PaymentMethod {
  String label(BuildContext context) => switch (this) {
    PaymentMethod.onchain => context.addPlaceLoc.paymentOnchain,
    PaymentMethod.lightning => context.addPlaceLoc.paymentLightning,
    PaymentMethod.nfc => context.addPlaceLoc.paymentNfc,
  };
}
