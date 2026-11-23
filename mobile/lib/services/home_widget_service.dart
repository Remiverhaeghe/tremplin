// Widget de l'écran d'accueil Android : questions à revoir et prochain entretien,
// mis à jour après chaque synchronisation.

import '../l10n/texts.dart';
import '../logic/interview_alerts.dart';

/// Nom de la classe Kotlin qui dessine le widget (android/app/src/main/kotlin).
const widgetProviderName = 'RevisionWidgetProvider';

/// Les deux lignes du widget : révision du jour, puis prochain entretien.
(String, String) buildWidgetLines(
  int pDueCount,
  List<Map<String, dynamic>> pApplications,
  DateTime pNow, [
  AppLocalizations? pText,
]) {
  final vText = pText ?? deviceTexts();
  DateTime? vNext;
  String? vCompany;

  for (final vApplication in pApplications) {
    final vAt = DateTime.tryParse('${vApplication['interview_at'] ?? ''}');

    if (vAt != null && vAt.isAfter(pNow) && (vNext == null || vAt.isBefore(vNext))) {
      vNext = vAt;
      vCompany = (vApplication['company'] ?? vApplication['title']) as String?;
    }
  }

  final vDue = pDueCount == 0 ? vText.widgetNothingDue : vText.widgetDue(pDueCount);
  final vInterview = vNext == null
      ? vText.widgetNoInterview
      : vText.widgetInterview(
          twoDigits(vNext.day),
          twoDigits(vNext.month),
          twoDigits(vNext.hour),
          twoDigits(vNext.minute),
          vCompany == null ? '' : ' · $vCompany',
        );

  final rLines = (vDue, vInterview);

  return rLines;
}

/// Adresse ouverte par le bouton « 5 min » du widget.
final sprintLaunch = Uri.parse('tremplin://sprint');

/// Vrai quand le widget a été touché sur son bouton « 5 min ».
bool isSprintLaunch(Uri? pUri) =>
    pUri != null && pUri.scheme == 'tremplin' && pUri.host == 'sprint';

/// Envoie les lignes au widget ; sans widget posé, Android les garde pour plus tard.
abstract class HomeWidgetUpdater {
  Future<void> show((String, String) pLines);

  /// Adresses par lesquelles le widget a ouvert l'application : celle du lancement, puis
  /// chaque toucher pendant qu'elle tourne.
  Stream<Uri?> launches();
}
