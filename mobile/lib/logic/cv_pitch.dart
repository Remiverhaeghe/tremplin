// Présentation orale de trente secondes, pour le téléphone ou le début d'un entretien : environ
// quatre-vingts mots tirés du parcours, sans rien inventer.

import 'cv_profile.dart';
import 'cv_version.dart';

/// Nombre de mots visé : une trentaine de secondes à voix posée.
const cvPitchWords = 80;

int _words(String pText) => pText.split(RegExp(r'\s+')).where((pWord) => pWord.isNotEmpty).length;

/// Première phrase d'un texte, sans le point final.
String _firstSentence(String pText) {
  final vText = pText.trim();
  final vEnd = vText.indexOf(RegExp(r'[.!?](\s|$)'));

  return (vEnd < 0 ? vText : vText.substring(0, vEnd)).trim();
}

String buildPitch(CvProfile pProfile, CvVersion pVersion, {String pCompany = '', String pJob = ''}) {
  final vName = pProfile.contact.name.trim();
  final vParts = <String>[
    'Bonjour, je m’appelle $vName.',
    if (pVersion.headline.trim().isNotEmpty) 'Je suis ${_lower(pVersion.headline.trim())}.',
    if (pVersion.pivot.trim().isNotEmpty)
      '${_firstSentence(pVersion.pivot)}.'
    else if (pVersion.summary.trim().isNotEmpty)
      '${_firstSentence(pVersion.summary)}.',
    if (pProfile.projects.isNotEmpty && pProfile.projects.first.lines.isNotEmpty)
      'Récemment, j’ai réalisé ${pProfile.projects.first.name} : '
          '${_firstSentence(pProfile.projects.first.lines.first)}.',
    if (pCompany.trim().isNotEmpty && pJob.trim().isNotEmpty)
      'Le poste de ${pJob.trim()} chez ${pCompany.trim()} m’intéresse.'
    else if (pCompany.trim().isNotEmpty)
      'Votre entreprise, ${pCompany.trim()}, m’intéresse.',
    if (pProfile.contact.availability.trim().isNotEmpty) '${pProfile.contact.availability.trim()}.',
  ];
  final rPitch = <String>[];
  var vCount = 0;

  for (final vPart in vParts) {
    if (rPitch.isNotEmpty && vCount + _words(vPart) > cvPitchWords) {
      continue;
    }
    rPitch.add(vPart);
    vCount += _words(vPart);
  }

  return rPitch.join(' ');
}

String _lower(String pText) => pText.isEmpty ? pText : pText[0].toLowerCase() + pText.substring(1);

/// Durée de lecture à voix posée, en secondes (environ 150 mots par minute).
int pitchSeconds(String pPitch) => (_words(pPitch) * 60 / 150).round();
