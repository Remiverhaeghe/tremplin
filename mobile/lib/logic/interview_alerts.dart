// Rappels d'entretien calculés à partir des entretiens reçus du PC : la veille
// au soir, puis une heure avant.

/// Heure du rappel de la veille
const eveningReminderHour = 18;

/// Délai du dernier rappel avant l'entretien
const lastReminderDelay = Duration(hours: 1);

/// Un rappel à afficher : quand, et avec quel texte.
class InterviewAlert {
  const InterviewAlert(this.at, this.title, this.body);

  final DateTime at;
  final String title;
  final String body;
}

/// Textes des rappels dans la langue de l'application ; le français par défaut.
class InterviewAlertTexts {
  const InterviewAlertTexts({
    this.tomorrowAt = _frenchTomorrow,
    this.soon = 'Entretien dans une heure',
    this.untitled = 'Entretien',
    this.where = _frenchWhere,
    this.when = _frenchWhen,
  });

  final String Function(String pTime) tomorrowAt;
  final String soon;
  final String untitled;
  final String Function(String pTitle, String pCompany) where;
  final String Function(String pWhat, String pTime) when;
}

String _frenchTomorrow(String pTime) => 'Entretien demain à $pTime';

String _frenchWhere(String pTitle, String pCompany) => '$pTitle chez $pCompany';

String _frenchWhen(String pWhat, String pTime) => '$pWhat, à $pTime';

String twoDigits(int pValue) => pValue.toString().padLeft(2, '0');

/// Retourne les rappels encore à venir des entretiens donnés, les plus proches d'abord.
List<InterviewAlert> buildInterviewAlerts(
  List<Map<String, dynamic>> pInterviews,
  DateTime pNow, [
  InterviewAlertTexts pTexts = const InterviewAlertTexts(),
]) {
  final rAlerts = <InterviewAlert>[];

  for (final vInterview in pInterviews) {
    final vAt = DateTime.tryParse('${vInterview['interview_at'] ?? ''}');

    if (vAt == null || !vAt.isAfter(pNow)) {
      continue;
    }

    final vTitle = '${vInterview['title'] ?? pTexts.untitled}';
    final vWhat =
        vInterview['company'] == null ? vTitle : pTexts.where(vTitle, '${vInterview['company']}');
    final vTime = '${twoDigits(vAt.hour)}:${twoDigits(vAt.minute)}';
    final vEvening = DateTime(vAt.year, vAt.month, vAt.day - 1, eveningReminderHour);
    final vLast = vAt.subtract(lastReminderDelay);

    if (vEvening.isAfter(pNow)) {
      rAlerts.add(InterviewAlert(
        vEvening,
        pTexts.tomorrowAt(vTime),
        vWhat,
      ));
    }

    if (vLast.isAfter(pNow)) {
      rAlerts.add(InterviewAlert(
        vLast,
        pTexts.soon,
        pTexts.when(vWhat, vTime),
      ));
    }
  }

  rAlerts.sort((pFirst, pSecond) => pFirst.at.compareTo(pSecond.at));

  return rAlerts;
}
