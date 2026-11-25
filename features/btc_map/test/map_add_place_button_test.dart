import 'package:btc_map/generated/l10n/btc_map_localizations.dart';
import 'package:btc_map/src/domain/usecases/load_cached_merchants_usecase.dart';
import 'package:btc_map/src/domain/usecases/sync_merchants_usecase.dart';
import 'package:btc_map/src/map_types.dart';
import 'package:btc_map/src/presentation/map_cubit.dart';
import 'package:btc_map/src/ui/map_add_place_action.dart';
import 'package:btc_map/src/ui/map_screen.dart';
import 'package:bull_ui/testing.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show OneSequenceGestureRecognizer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:primitives/primitives.dart';

/// Just enough native map for the screen to build.
class _MapPlatform extends MapLibrePlatform {
  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) => const SizedBox.expand();

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

void main() {
  final area = GeoBounds(
    south: 9.165,
    west: -83.74,
    north: 9.169,
    east: -83.738,
  );

  setUp(() {
    final previous = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = _MapPlatform.new;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
  });

  Future<MapCubit> pump(WidgetTester tester, MapAddPlaceAction? action) async {
    Future<Result<List<Merchant>, BullMapFailure>> none() async => const Ok([]);
    final cubit = MapCubit(
      LoadCachedMerchantsUsecase(none),
      SyncMerchantsUsecase(none),
    );
    await cubit.start();
    cubit.viewportChanged(area);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: testBullExtensions),
        locale: const Locale('en'),
        localizationsDelegates: BtcMapLocalizations.localizationsDelegates,
        supportedLocales: BtcMapLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit,
          child: MapScreen(addPlace: action),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  testWidgets('without an app action there is no button', (tester) async {
    final cubit = await pump(tester, null);
    addTearDown(cubit.close);

    expect(find.byIcon(Icons.add_location_alt_outlined), findsNothing);
  });

  testWidgets('the button is named and hands over the area the map shows', (
    tester,
  ) async {
    final opened = <GeoBounds?>[];
    final cubit = await pump(
      tester,
      MapAddPlaceAction(
        label: (_) => 'Add a place',
        open: (_, shown) => opened.add(shown),
      ),
    );
    addTearDown(cubit.close);

    await tester.tap(find.byTooltip('Add a place'));

    expect(opened, [area]);
  });
}
