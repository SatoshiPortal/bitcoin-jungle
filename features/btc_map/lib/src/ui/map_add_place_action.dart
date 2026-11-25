import 'package:bull_ui/bull_ui.dart' show BuildContext;

import 'package:btc_map/src/domain/entities/geo_bounds.dart';

/// An app-supplied "add a place" action shown on the map. The map hands it the area it shows, or null before the first viewport.
final class MapAddPlaceAction {
  final String Function(BuildContext context) label;
  final void Function(BuildContext context, GeoBounds? area) open;

  const MapAddPlaceAction({required this.label, required this.open});
}
