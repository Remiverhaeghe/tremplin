// Textes de l'application : l'anglais suit le français clé par clé.

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/l10n/texts.dart';
import 'package:jobboard_revision/services/home_widget_service.dart';
import 'package:jobboard_revision/services/reminders.dart';

Map<String, dynamic> readArb(String pName) =>
    jsonDecode(File('lib/l10n/$pName').readAsStringSync()) as Map<String, dynamic>;

/// Noms des valeurs à insérer dans un texte, pluriels compris.
Set<String> placeholdersOf(String pText) =>
    RegExp(r'\{(\w+)(?=[},])').allMatches(pText).map((pMatch) => pMatch.group(1)!).toSet();

void main() {
  test('Chaque texte français a sa traduction anglaise, avec les mêmes valeurs', () {
    final vFrench = readArb('app_fr.arb');
    final vEnglish = readArb('app_en.arb');
    final vKeys = vFrench.keys.where((pKey) => !pKey.startsWith('@'));

    expect(vKeys.where((pKey) => !vEnglish.containsKey(pKey)), isEmpty);
    expect(
      vEnglish.keys.where((pKey) => !pKey.startsWith('@') && !vFrench.containsKey(pKey)),
      isEmpty,
    );
    for (final vKey in vKeys) {
      expect(
        placeholdersOf(vEnglish[vKey] as String),
        placeholdersOf(vFrench[vKey] as String),
        reason: vKey,
      );
    }
  });

  test('Anglais pour un téléphone en anglais, français sinon', () {
    expect(appLocale(const Locale('en', 'GB')), const Locale('en'));
    expect(appLocale(const Locale('de')), const Locale('fr'));
    expect(appLocale(null), const Locale('fr'));
  });

  test('Le réglage de langue impose sa langue, ou laisse celle du téléphone', () {
    expect(chosenLocale('en'), const Locale('en'));
    expect(chosenLocale('fr'), const Locale('fr'));
    expect(chosenLocale('system'), isNull);

    final vAlerts = interviewAlertTexts(lookupAppLocalizations(const Locale('en')));

    expect(vAlerts.tomorrowAt('14:00'), 'Interview tomorrow at 14:00');
    expect(vAlerts.where('Developer', 'Acme'), 'Developer at Acme');
  });

  test('Widget et notifications suivent la langue donnée', () {
    final vEnglish = lookupAppLocalizations(const Locale('en'));
    final vNow = DateTime(2026, 11, 20, 9);

    expect(buildWidgetLines(2, const [], vNow, vEnglish).$1, '2 questions to review');
    expect(buildWidgetLines(0, const [], vNow).$1, "Rien à revoir aujourd'hui");
    expect(
      describeReply({'company': 'Exemple', 'status': 'REJECTED'}, vEnglish),
      'Rejection from Exemple',
    );
    expect(deviceTexts().localeName, 'fr');
  });
}
