import 'dart:async';

import 'package:bb_mobile/core/utils/build_context_x.dart';
import 'package:bb_mobile/core/utils/constants.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// What "contact support" means in this app.
///
/// This is the one place a fork changes to point support somewhere else: the
/// shell registers [contactSupport] in a `BullSupportScope`, and every
/// `BullSupportButton` calls it.
class SupportFacade {
  const SupportFacade._();

  /// Opens Bitcoin Jungle support on WhatsApp from [context].
  ///
  /// The chat is pre-filled with [message] when one is given, otherwise with a
  /// default greeting in the user's language. Works the same inside and outside
  /// the router, so the startup and init-error screens behave like the rest.
  static void contactSupport(BuildContext context, {String? message}) {
    final text = message ?? context.loc.supportWhatsAppDefaultMessage;
    unawaited(
      launchUrl(
        Uri.parse(
          '${SettingsConstants.webSupportLink}'
          '?text=${Uri.encodeComponent(text)}',
        ),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}
