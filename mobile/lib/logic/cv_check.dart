// Contrôles avant l'export : ce qu'un logiciel de tri des candidatures lit mal, et les mots de
// l'offre que le CV ne contient pas. Rien n'est ajouté tout seul : l'écran montre les manques,
// Rémi ajoute un mot seulement s'il est vrai.

import 'cv_document.dart';
import 'cv_version.dart';

/// Un point de contrôle : son code, et s'il passe.
typedef CvCheck = ({CvCheckCode code, bool ok});

enum CvCheckCode { name, email, phone, headline, summary, experience, education, dates }

/// Contrôles du document : coordonnées en clair, sections reconnues, dates lisibles.
List<CvCheck> checkCv(CvDocument pDocument) {
  CvSectionText? find(CvSection pSection) {
    for (final vSection in pDocument.sections) {
      if (vSection.section == pSection) {
        return vSection;
      }
    }

    return null;
  }

  final vText = pDocument.contactLines.join('\n');
  final vExperience = find(CvSection.experience);
  final vYear = RegExp(r'(19|20)\d{2}');
  final rChecks = <CvCheck>[
    (code: CvCheckCode.name, ok: pDocument.name.trim().isNotEmpty),
    (
      code: CvCheckCode.email,
      ok: RegExp(r'[^\s@]+@[^\s@]+\.[a-z]{2,}', caseSensitive: false).hasMatch(vText)
    ),
    (code: CvCheckCode.phone, ok: RegExp(r'\d[\d .]{7,}\d').hasMatch(vText)),
    (code: CvCheckCode.headline, ok: pDocument.headline.trim().isNotEmpty),
    (code: CvCheckCode.summary, ok: find(CvSection.summary) != null),
    (code: CvCheckCode.experience, ok: vExperience != null),
    (code: CvCheckCode.education, ok: find(CvSection.education) != null),
    (
      code: CvCheckCode.dates,
      ok: vExperience != null && vExperience.blocks.every((pBlock) => vYear.hasMatch(pBlock.dates)),
    ),
  ];

  return rChecks;
}

/// Mots trop courants pour compter comme mots-clés d'une offre.
const _commonWords = {
  'avec',
  'dans',
  'pour',
  'vous',
  'nous',
  'votre',
  'notre',
  'vos',
  'nos',
  'les',
  'des',
  'une',
  'sur',
  'par',
  'plus',
  'aussi',
  'sont',
  'être',
  'etre',
  'avoir',
  'cette',
  'ces',
  'ses',
  'leur',
  'leurs',
  'entre',
  'sans',
  'sous',
  'tout',
  'tous',
  'toute',
  'toutes',
  'bien',
  'mais',
  'comme',
  'ainsi',
  'chez',
  'dont',
  'afin',
  'poste',
  'offre',
  'recherche',
  'rejoindre',
  'mission',
  'missions',
  'profil',
  'candidat',
  'entreprise',
  'société',
  'societe',
  'h/f',
  'cdi',
  'cdd',
  'stage',
  'alternance',
  'expérience',
  'experience',
  'ans',
  'année',
  'années',
  'annee',
  'annees',
  'équipe',
  'equipe',
  'sera',
  'serez',
  'peut',
  'doit',
  'faire',
  'travail',
};

/// Même mot avec ou sans accent, en minuscules.
String _plain(String pText) {
  const vFrom = 'àâäçéèêëîïôöùûüÿœ';
  const vTo = 'aaaceeeeiioouuuyo';
  final rText = StringBuffer();
  for (final vRune in pText.toLowerCase().runes) {
    final vChar = String.fromCharCode(vRune);
    final vAt = vFrom.indexOf(vChar);
    rText.write(vAt >= 0 ? vTo[vAt] : vChar);
  }

  return rText.toString();
}

/// Mots de l'offre rangés du plus fréquent au moins fréquent, sans les mots courants.
List<String> offerKeywords(String pOffer, {int pLimit = 20}) {
  final vCommon = {for (final vWord in _commonWords) _plain(vWord)};
  final vCount = <String, int>{};
  for (final vMatch in RegExp(r"[a-z0-9+#./]{3,}").allMatches(_plain(pOffer))) {
    final vWord = vMatch.group(0)!.replaceAll(RegExp(r'^[./]+|[./]+$'), '');
    if (vWord.length >= 3 && !vCommon.contains(vWord) && !RegExp(r'^\d+$').hasMatch(vWord)) {
      vCount[vWord] = (vCount[vWord] ?? 0) + 1;
    }
  }
  final vSorted = vCount.entries.toList()
    ..sort((pA, pB) {
      final vByCount = pB.value.compareTo(pA.value);
      return vByCount != 0 ? vByCount : pA.key.compareTo(pB.key);
    });
  final rWords = [for (final vEntry in vSorted.take(pLimit)) vEntry.key];

  return rWords;
}

/// Mots de l'offre présents et absents du CV.
({List<String> found, List<String> missing}) keywordReport(String pOffer, CvDocument pDocument) {
  final vCv = _plain(pDocument.plainText);
  final vWords = offerKeywords(pOffer);
  final rReport = (
    found: [
      for (final vWord in vWords)
        if (vCv.contains(vWord)) vWord
    ],
    missing: [
      for (final vWord in vWords)
        if (!vCv.contains(vWord)) vWord
    ],
  );

  return rReport;
}
