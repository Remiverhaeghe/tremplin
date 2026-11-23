// Les candidatures en tableur : un fichier CSV que Excel ou LibreOffice ouvrent directement
// (séparateur point-virgule, UTF-8 avec marque d'ordre des octets).

const _header = [
  'Date',
  'Entreprise',
  'Poste',
  'CV',
  'Format',
  'Réponse',
  'Relance',
  'Délai de réponse (jours)',
  'Lien',
];

String _cell(Object? pValue) {
  final vText = '${pValue ?? ''}'.replaceAll('\n', ' ');

  return vText.contains(';') || vText.contains('"') ? '"${vText.replaceAll('"', '""')}"' : vText;
}

String _day(Object? pValue) => '${pValue ?? ''}'.split('T').first;

String sentToCsv(List<Map<String, dynamic>> pSent) {
  final rLines = <String>[_header.join(';')];

  for (final vItem in pSent) {
    final vSentAt = DateTime.tryParse('${vItem['at']}');
    final vAnsweredAt = DateTime.tryParse('${vItem['answered_at'] ?? ''}');

    rLines.add([
      _day(vItem['at']),
      vItem['company'],
      vItem['title'],
      vItem['version'],
      vItem['format'],
      vItem['outcome'],
      _day(vItem['followed_up']),
      if (vSentAt != null && vAnsweredAt != null) vAnsweredAt.difference(vSentAt).inDays else '',
      vItem['url'],
    ].map(_cell).join(';'));
  }

  return '\u{FEFF}${rLines.join('\r\n')}\r\n';
}
