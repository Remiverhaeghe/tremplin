// Statistiques des candidatures : combien, par version, avec quelles réponses.

const cvOutcomes = ['reponse', 'entretien', 'offre', 'refus'];

typedef CvVersionStat = ({String version, int sent, int answered, int interviews});

class CvStats {
  const CvStats({
    this.total = 0,
    this.answered = 0,
    this.interviews = 0,
    this.byVersion = const [],
    this.byMonth = const {},
  });

  final int total;

  /// Réponses de toute nature : réponse, entretien ou refus.
  final int answered;
  final int interviews;

  /// Versions du CV, celle qui obtient le plus de réponses d'abord.
  final List<CvVersionStat> byVersion;

  /// Nombre d'envois par mois (`2026-11`), du plus ancien au plus récent.
  final Map<String, int> byMonth;
}

CvStats cvStats(List<Map<String, dynamic>> pSent) {
  final vVersions = <String, List<int>>{};
  final vMonths = <String, int>{};
  var vAnswered = 0;
  var vInterviews = 0;

  for (final vItem in pSent) {
    final vOutcome = '${vItem['outcome'] ?? ''}';
    final vCounts = vVersions.putIfAbsent('${vItem['version'] ?? ''}', () => [0, 0, 0]);
    final vMonth = '${vItem['at'] ?? ''}'.split('-').take(2).join('-');

    vCounts[0]++;
    if (vMonth.length == 7) {
      vMonths[vMonth] = (vMonths[vMonth] ?? 0) + 1;
    }
    if (vOutcome.isNotEmpty) {
      vAnswered++;
      vCounts[1]++;
    }
    if (vOutcome == 'entretien' || vOutcome == 'offre') {
      vInterviews++;
      vCounts[2]++;
    }
  }

  final vList = [
    for (final vEntry in vVersions.entries)
      (
        version: vEntry.key,
        sent: vEntry.value[0],
        answered: vEntry.value[1],
        interviews: vEntry.value[2]
      ),
  ]..sort((pA, pB) {
      final vByAnswers = pB.answered.compareTo(pA.answered);
      return vByAnswers != 0 ? vByAnswers : pB.sent.compareTo(pA.sent);
    });
  final vSortedMonths =
      Map.fromEntries(vMonths.entries.toList()..sort((pA, pB) => pA.key.compareTo(pB.key)));

  return CvStats(
    total: pSent.length,
    answered: vAnswered,
    interviews: vInterviews,
    byVersion: vList,
    byMonth: vSortedMonths,
  );
}
