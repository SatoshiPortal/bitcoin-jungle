import 'dart:async';

import 'package:add_place/add_place.dart';
import 'package:add_place/src/domain/entities/payment_method.dart';
import 'package:add_place/src/domain/add_place_failure.dart';
import 'package:add_place/src/domain/entities/pin_area.dart';
import 'package:add_place/src/domain/repositories/address_lookup_repository.dart';
import 'package:add_place/src/domain/usecases/suggest_address_usecase.dart';
import 'package:add_place/src/presentation/address_suggestion_cubit.dart';
import 'package:add_place/src/domain/usecases/submit_place_usecase.dart';
import 'package:add_place/src/presentation/add_place_cubit.dart';
import 'package:add_place/src/ui/add_place_screen.dart';
import 'package:btc_map/btc_map.dart' show GeoBounds, GeoPoint;
import 'package:bull_ui/bull_ui.dart' show BullButton;
import 'package:bull_ui/testing.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show OneSequenceGestureRecognizer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:primitives/primitives.dart';

import 'helpers.dart';

/// A native map whose visible area the test sets.
class _MapPlatform extends MapLibrePlatform {
  OnPlatformViewCreatedCallback? created;
  bool started = false;
  late LatLngBounds visible;

  @override
  Future<void> initPlatform(int id) async {}

  @override
  Widget buildView(
    Map<String, dynamic> creationParams,
    OnPlatformViewCreatedCallback onPlatformViewCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  ) {
    created = onPlatformViewCreated;
    return const SizedBox.expand();
  }

  @override
  Future<CameraPosition?> updateMapOptions(
    Map<String, dynamic> optionsUpdate,
  ) async => null;

  @override
  Future<LatLngBounds> getVisibleRegion() async => visible;

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

/// Answers every lookup with [address], recording the language asked for.
class _FixedLookup implements AddressLookupRepository {
  String? address = 'Calle 5, 60504 Uvita';
  final List<String> languages = [];

  @override
  Future<Result<String?, AddPlaceFailure>> addressAt(
    GeoPoint location, {
    required String languageCode,
  }) async {
    languages.add(languageCode);
    return Ok(address);
  }
}

LatLngBounds _latLng(GeoBounds bounds) => LatLngBounds(
  southwest: LatLng(bounds.south, bounds.west),
  northeast: LatLng(bounds.north, bounds.east),
);

void main() {
  final street = GeoBounds(
    south: 9.165,
    west: -83.74,
    north: 9.169,
    east: -83.738,
  );
  final city = GeoBounds(south: 9.10, west: -83.80, north: 9.25, east: -83.70);
  late _MapPlatform platform;
  late FakeRepository repository;
  late _FixedLookup lookup;

  setUp(() {
    platform = _MapPlatform();
    repository = FakeRepository();
    lookup = _FixedLookup();
    final previous = MapLibrePlatform.createInstance;
    MapLibrePlatform.createInstance = () => platform;
    addTearDown(() => MapLibrePlatform.createInstance = previous);
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Text('map'),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) =>
                        AddPlaceCubit(SubmitPlaceUsecase(repository)),
                  ),
                  BlocProvider(
                    create: (_) =>
                        AddressSuggestionCubit(SuggestAddressUsecase(lookup)),
                  ),
                ],
                child: const AddPlaceScreen(),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(extensions: testBullExtensions),
        locale: const Locale('en'),
        localizationsDelegates: AddPlaceLocalizations.localizationsDelegates,
        supportedLocales: AddPlaceLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();
  }

  /// The map comes to rest showing [bounds].
  Future<void> show(WidgetTester tester, GeoBounds bounds) async {
    platform.visible = _latLng(bounds);
    if (!platform.started) {
      platform.started = true;
      platform.created?.call(0);
      await tester.pump();
    }
    tester.widget<MapLibreMap>(find.byType(MapLibreMap)).onCameraIdle?.call();
    // The map reads its visible region asynchronously before reporting it.
    await tester.pump();
    await tester.pump();
  }

  bool useLocationEnabled(WidgetTester tester) => !tester
      .widget<BullButton>(find.widgetWithText(BullButton, 'Use this location'))
      .disabled;

  Finder field(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );

  testWidgets('the location can only be used once zoomed in to street level', (
    tester,
  ) async {
    await pump(tester);

    await show(tester, city);
    expect(find.text('Zoom in until you can see the street'), findsOne);
    expect(useLocationEnabled(tester), isFalse);

    await show(tester, street);
    expect(find.text('Move the map so the pin is on the place'), findsOne);
    expect(useLocationEnabled(tester), isTrue);
  });

  testWidgets('a filled form sends the pinned place and closes', (
    tester,
  ) async {
    await pump(tester);
    await show(tester, street);
    await tester.tap(find.text('Use this location'));
    await tester.pump();

    await tester.enterText(field('name'), 'Soda Tica');
    await tester.tap(find.text('Coffee'));
    await tester.tap(find.text('Lightning'));
    await tester.pump();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    final sent = repository.submitted.single;
    expect(sent.name, 'Soda Tica');
    expect(sent.category, 'coffee');
    expect(sent.paymentMethods, {PaymentMethod.lightning});
    expect(sent.location, PinArea(street).pin);
    expect(find.text('map'), findsOne);
    // Let the confirmation toast dismiss itself.
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('going back from "Change" returns to the form, keeping it', (
    tester,
  ) async {
    await pump(tester);
    await show(tester, street);
    await tester.tap(find.text('Use this location'));
    await tester.pump();
    await tester.enterText(field('name'), 'Soda Tica');
    await tester.pump();

    await tester.tap(find.text('Change'));
    await tester.pump();
    expect(find.text('Use this location'), findsOne);

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Soda Tica'), findsOne);
    expect(find.text('map'), findsNothing);
  });

  testWidgets('every text field has a screen reader name', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await show(tester, street);
    await tester.tap(find.text('Use this location'));
    await tester.pump();

    for (final label in [
      'Business name',
      'Your email (optional)',
      'Address (optional)',
      'Website (optional)',
    ]) {
      expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
    }
    semantics.dispose();
  });

  testWidgets('the address is filled in from the pin, as a suggestion', (
    tester,
  ) async {
    await pump(tester);
    await show(tester, street);
    await tester.tap(find.text('Use this location'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Calle 5, 60504 Uvita'), findsOne);
    expect(
      find.text("Suggested from the pin. Change it if it's not right."),
      findsOne,
    );
    expect(lookup.languages, ['en']);
  });

  testWidgets('an address the user typed is never replaced by a suggestion', (
    tester,
  ) async {
    await pump(tester);
    await show(tester, street);
    await tester.tap(find.text('Use this location'));
    await tester.pump();
    await tester.pump();
    await tester.enterText(field('address'), 'Next to the bakery');
    await tester.pump();

    await tester.tap(find.text('Change'));
    await tester.pump();
    lookup.address = 'Calle 7, 60504 Uvita';
    await show(tester, street);
    await tester.tap(find.text('Use this location'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Next to the bakery'), findsOne);
    expect(find.text('Calle 7, 60504 Uvita'), findsNothing);
  });

  testWidgets('the route opens the picker on the area the map showed', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const Text('map')),
        ...AddPlaceFeature.mount().routes,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: ThemeData(extensions: testBullExtensions),
        locale: const Locale('en'),
        localizationsDelegates: AddPlaceLocalizations.localizationsDelegates,
        supportedLocales: AddPlaceLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );

    unawaited(router.pushNamed('addPlace', extra: street));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AddPlaceScreen>(find.byType(AddPlaceScreen)).initialArea,
      same(street),
    );
  });
}
