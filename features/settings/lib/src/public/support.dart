import 'dart:async';

import 'support_links.dart';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n.dart';

/// What "contact support" means in this app.
///
/// This is the one place a fork changes to point support somewhere else: the
/// shell registers [contactSupport] in a `BullSupportScope`, and every
/// `BullSupportButton` calls it.
class Support {
  const Support._();

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
          '${SupportLinks.webSupportLink}'
          '?text=${Uri.encodeComponent(text)}',
        ),
        mode: LaunchMode.externalApplication,
      ),
    );
  }
}
