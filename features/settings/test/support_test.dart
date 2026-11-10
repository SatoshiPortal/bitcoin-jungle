import 'package:settings/testing.dart';
import 'package:settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// No plugin is registered under `flutter test`, so url_launcher falls back to
// its method-channel implementation; record the URLs it is asked to open.
const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

// The app adds Flutter's own translations; a package test adds them itself.
final _delegates = [
  SettingsLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

class _SupportTrigger extends StatelessWidget {
  const _SupportTrigger({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Support.contactSupport(context, message: message),
      child: const Text('help'),
    );
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  String? message,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: _delegates,
      supportedLocales: SettingsLocalizations.supportedLocales,
      home: Scaffold(body: _SupportTrigger(message: message)),
    ),
  );
}

void main() {
  late List<Object?> launched;

  setUp(() {
    launched = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
          if (call.method == 'launch') {
            launched.add((call.arguments as Map<Object?, Object?>)['url']);
          }
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_urlLauncherChannel, null);
  });

  group('Support.contactSupport', () {
    testWidgets('opens WhatsApp pre-filled with the given message', (
      tester,
    ) async {
      await _pumpApp(tester, message: 'Order 42 & more');

      await tester.tap(find.text('help'));
      await tester.pumpAndSettle();

      expect(launched, [
        '${SupportLinks.webSupportLink}?text=Order%2042%20%26%20more',
      ]);
    });

    testWidgets('pre-fills the English greeting when no message', (
      tester,
    ) async {
      await _pumpApp(tester);

      await tester.tap(find.text('help'));
      await tester.pumpAndSettle();

      final text = Uri.parse(launched.single.toString())
          .queryParameters['text'];
      expect(text, 'Hey there! I need some help with Bitcoin Jungle Wallet');
    });

    testWidgets('pre-fills the Spanish greeting in Spanish', (tester) async {
      await _pumpApp(tester, locale: const Locale('es'));

      await tester.tap(find.text('help'));
      await tester.pumpAndSettle();

      final text = Uri.parse(launched.single.toString())
          .queryParameters['text'];
      expect(text, '¡Hola! Necesito ayuda con Bitcoin Jungle Wallet');
    });

    testWidgets('opens WhatsApp, not a route, inside the router', (
      tester,
    ) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: _SupportTrigger(message: 'hi')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: _delegates,
          supportedLocales: SettingsLocalizations.supportedLocales,
        ),
      );

      await tester.tap(find.text('help'));
      await tester.pumpAndSettle();

      expect(launched, ['${SupportLinks.webSupportLink}?text=hi']);
      expect(router.canPop(), isFalse);
    });
  });
}
