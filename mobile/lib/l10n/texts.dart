import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Textes de l'application, pris dans app_fr.arb.
/// Langue de l'application : l'anglais si le téléphone est en anglais, le français sinon.
Locale appLocale(Locale? pLocale) =>
    pLocale?.languageCode == 'en' ? const Locale('en') : const Locale('fr');

/// Textes dans la langue du téléphone, pour ce qui s'affiche hors des écrans : notifications,
/// widget d'accueil. La tâche d'arrière-plan n'a pas toujours de liaison Flutter : on lit
/// alors la langue directement.
AppLocalizations deviceTexts() {
  Locale vLocale;

  try {
    vLocale = WidgetsBinding.instance.platformDispatcher.locale;
  } on Object {
    vLocale = ui.PlatformDispatcher.instance.locale;
  }

  return lookupAppLocalizations(appLocale(vLocale));
}

extension Texts on BuildContext {
  /// Textes de la langue de l'application ; le français quand aucune n'est fournie, comme dans un
  /// test qui monte un écran seul.
  AppLocalizations get texts =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('fr'));
}
