import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../logic/interview_alerts.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Textes de l'application, pris dans app_fr.arb.
/// Langue de l'application : l'anglais si le téléphone est en anglais, le français sinon.
Locale appLocale(Locale? pLocale) =>
    pLocale?.languageCode == 'en' ? const Locale('en') : const Locale('fr');

/// Langue choisie dans les réglages : 'system', 'fr' ou 'en'. L'état la met à jour au chargement,
/// y compris dans la tâche d'arrière-plan, pour que les notifications suivent ce choix.
String aChosenLanguage = 'system';

/// Langue imposée par le réglage, ou null pour suivre le téléphone.
Locale? chosenLocale(String pLanguage) => switch (pLanguage) {
      'fr' => const Locale('fr'),
      'en' => const Locale('en'),
      _ => null,
    };

/// Textes dans la langue choisie, ou à défaut celle du téléphone, pour ce qui s'affiche hors des écrans : notifications,
/// widget d'accueil. La tâche d'arrière-plan n'a pas toujours de liaison Flutter : on lit
/// alors la langue directement.
AppLocalizations deviceTexts() {
  if (chosenLocale(aChosenLanguage) case final vChosen?) {
    return lookupAppLocalizations(vChosen);
  }

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

/// Textes des rappels d'entretien, pour la logique qui ne connaît pas Flutter.
InterviewAlertTexts interviewAlertTexts(AppLocalizations pText) => InterviewAlertTexts(
      tomorrowAt: pText.interviewAlertTomorrow,
      soon: pText.interviewAlertSoon,
      untitled: pText.interviewAlertUntitled,
      where: pText.interviewAlertWhere,
      when: pText.interviewAlertWhen,
    );
