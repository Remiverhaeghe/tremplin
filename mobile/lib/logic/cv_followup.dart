// Relances : une candidature sans réponse après quelques jours mérite un message court.

import 'interview_alerts.dart';

/// Candidatures sans réponse ni relance depuis au moins [pDays] jours, les plus anciennes d'abord.
List<Map<String, dynamic>> followUpsDue(
  List<Map<String, dynamic>> pSent,
  DateTime pNow, {
  int pDays = 7,
}) {
  final vLimit = pNow.subtract(Duration(days: pDays));
  final rDue = [
    for (final vItem in pSent)
      if ('${vItem['outcome'] ?? ''}'.isEmpty &&
          '${vItem['followed_up'] ?? ''}'.isEmpty &&
          '${vItem['company'] ?? ''}'.isNotEmpty &&
          (DateTime.tryParse('${vItem['at']}')?.isBefore(vLimit) ?? false))
        vItem,
  ]..sort((pA, pB) => '${pA['at']}'.compareTo('${pB['at']}'));

  return rDue;
}

/// Message de relance, court et poli ; vide si l'entreprise est inconnue.
String followUpMessage({required String pName, required String pCompany, String pTitle = ''}) {
  final vJob = pTitle.trim().isEmpty ? 'le poste' : 'le poste de ${pTitle.trim()}';

  return 'Bonjour, je me permets de revenir vers vous au sujet de ma candidature pour $vJob '
      'chez $pCompany. Je reste très intéressé et disponible pour échanger. '
      'Bien cordialement, $pName';
}

/// Le dernier envoi à la même entreprise et pour le même poste dans les [pDays] derniers jours ;
/// null s'il n'y en a pas. Sert à ne pas postuler deux fois sans le vouloir.
Map<String, dynamic>? recentDuplicate(
  List<Map<String, dynamic>> pSent,
  String pCompany,
  String pTitle,
  DateTime pNow, {
  int pDays = 30,
}) {
  final vLimit = pNow.subtract(Duration(days: pDays));
  final vCompany = pCompany.trim().toLowerCase();

  if (vCompany.isEmpty) {
    return null;
  }
  for (final vItem in pSent) {
    final vAt = DateTime.tryParse('${vItem['at']}');

    if ('${vItem['company']}'.toLowerCase() == vCompany &&
        '${vItem['title']}'.toLowerCase() == pTitle.trim().toLowerCase() &&
        vAt != null &&
        vAt.isAfter(vLimit)) {
      return vItem;
    }
  }

  return null;
}

/// Rappels de relance : un par candidature sans réponse, le jour où elle atteint [pDays] jours à
/// 9 h, ou le lendemain à 9 h si ce jour est passé. Au plus [pMax], les plus proches d'abord.
List<InterviewAlert> followUpAlerts(
  List<Map<String, dynamic>> pSent,
  DateTime pNow, {
  int pDays = 7,
  int pMax = 20,
}) {
  final vTomorrow = DateTime(pNow.year, pNow.month, pNow.day + 1, 9);
  final rAlerts = <InterviewAlert>[];

  for (final vItem in pSent) {
    final vSentAt = DateTime.tryParse('${vItem['at']}');

    if (vSentAt == null ||
        '${vItem['outcome'] ?? ''}'.isNotEmpty ||
        '${vItem['followed_up'] ?? ''}'.isNotEmpty ||
        '${vItem['company'] ?? ''}'.isEmpty) {
      continue;
    }
    final vDue = DateTime(vSentAt.year, vSentAt.month, vSentAt.day + pDays, 9);

    rAlerts.add(
      InterviewAlert(
        vDue.isAfter(pNow) ? vDue : vTomorrow,
        'Relance à faire',
        '${vItem['company']} · ${vItem['title'] ?? ''}',
      ),
    );
  }
  rAlerts.sort((pA, pB) => pA.at.compareTo(pB.at));

  return rAlerts.take(pMax).toList();
}

/// Délais de réponse en jours entre l'envoi et la réponse notée, par entreprise.
typedef CvDelay = ({String company, double days});

List<CvDelay> responseDelays(List<Map<String, dynamic>> pSent) {
  final vByCompany = <String, List<int>>{};

  for (final vItem in pSent) {
    final vSentAt = DateTime.tryParse('${vItem['at']}');
    final vAnsweredAt = DateTime.tryParse('${vItem['answered_at'] ?? ''}');

    if (vSentAt != null && vAnsweredAt != null) {
      vByCompany
          .putIfAbsent('${vItem['company'] ?? ''}', () => [])
          .add(vAnsweredAt.difference(vSentAt).inDays.clamp(0, 10000));
    }
  }

  return [
    for (final vEntry in vByCompany.entries)
      (
        company: vEntry.key,
        days: vEntry.value.reduce((pA, pB) => pA + pB) / vEntry.value.length,
      ),
  ]..sort((pA, pB) => pA.days.compareTo(pB.days));
}
