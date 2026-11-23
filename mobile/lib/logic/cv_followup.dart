// Relances : une candidature sans réponse après quelques jours mérite un message court.

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
