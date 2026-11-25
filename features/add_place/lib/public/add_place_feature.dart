import 'package:btc_map/btc_map.dart' show MapAddPlaceAction;
import 'package:bull_ui/bull_ui.dart' show LocalizationsDelegate;
import 'package:go_router/go_router.dart';

import '../generated/l10n/add_place_localizations.dart';
import '../src/data/address_lookup_repository_impl.dart';
import '../src/data/datasources/add_place_datasource.dart';
import '../src/data/datasources/address_lookup_datasource.dart';
import '../src/data/place_submission_repository_impl.dart';
import '../src/domain/usecases/submit_place_usecase.dart';
import '../src/domain/usecases/suggest_address_usecase.dart';
import '../src/presentation/add_place_localizations_x.dart';
import '../src/ui/add_place_router.dart';

/// The "add a place" form, mounted by the application shell.
final class AddPlaceFeature {
  final List<GoRoute> routes;

  const AddPlaceFeature._(this.routes);

  /// [submitUrl] is the proxy to BTC Map; while it is null, sending reports that adding places is not available yet. [addressLookupUrl] answers like Nominatim's reverse geocoding, and defaults to OpenStreetMap's own service.
  factory AddPlaceFeature.mount({Uri? submitUrl, Uri? addressLookupUrl}) {
    // The request can carry the user's email, so it never goes over plain HTTP.
    if (submitUrl != null && submitUrl.scheme != 'https') {
      throw ArgumentError.value(submitUrl, 'submitUrl', 'must use https');
    }
    final submit = SubmitPlaceUsecase(
      PlaceSubmissionRepositoryImpl(AddPlaceDatasource(), submitUrl),
    );
    final suggest = SuggestAddressUsecase(
      AddressLookupRepositoryImpl(
        AddressLookupDatasource(url: addressLookupUrl),
      ),
    );
    return AddPlaceFeature._([
      AddPlaceRouter.route(submit: submit, suggest: suggest),
    ]);
  }

  /// The map's "add a place" button, for `BtcMapFeature.setup(addPlace:)`.
  static MapAddPlaceAction get addPlaceAction => MapAddPlaceAction(
    label: (context) => context.addPlaceLoc.addPlaceTitle,
    open: (context, area) =>
        context.pushNamed(AddPlaceRouter.name, extra: area),
  );

  static LocalizationsDelegate<AddPlaceLocalizations>
  get localizationsDelegate => AddPlaceLocalizations.delegate;
}
