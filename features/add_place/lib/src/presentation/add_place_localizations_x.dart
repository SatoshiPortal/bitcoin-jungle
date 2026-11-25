import 'package:bull_ui/bull_ui.dart' show BuildContext;

import '../../generated/l10n/add_place_localizations.dart';

extension AddPlaceLocalizationsX on BuildContext {
  AddPlaceLocalizations get addPlaceLoc => AddPlaceLocalizations.of(this);
}
