// Lettre de motivation à modèles, sans IA : Rémi écrit ses modèles une fois, l'appli remplit
// l'entreprise, le poste et les projets les plus proches de l'offre. Trois longueurs :
// complète, courte (formulaire en ligne) et message (courriel ou LinkedIn). Une relecture
// repère les formules toutes faites, qui sonnent faux à voix haute.

import 'cv_check.dart';
import 'cv_profile.dart';
import 'cv_tailor.dart';
import 'cv_truth.dart';
import 'cv_version.dart';

enum LetterLength { full, short, message }

/// Les modèles de Rémi. Les mots entre accolades sont remplis : `{poste}`, `{entreprise}`,
/// `{nom}`, `{telephone}`, `{disponibilite}`, `{preavis}`, `{accroche}`, `{virage}`, `{projet}`,
/// `{projet_detail}`.
class LetterKit {
  const LetterKit({
    this.hook = 'Je candidate au poste de {poste} chez {entreprise}.',
    this.proof = 'Un exemple concret : {projet}. {projet_detail}',
    this.closing = '{disponibilite} {preavis} Vous pouvez me joindre au {telephone}.',
    this.message = 'Bonjour, je candidate au poste de {poste} chez {entreprise}. '
        'Mon CV est en pièce jointe.',
  });

  final String hook;
  final String proof;
  final String closing;
  final String message;

  LetterKit copyWith({String? hook, String? proof, String? closing, String? message}) => LetterKit(
        hook: hook ?? this.hook,
        proof: proof ?? this.proof,
        closing: closing ?? this.closing,
        message: message ?? this.message,
      );

  Map<String, Object?> toJson() =>
      {'hook': hook, 'proof': proof, 'closing': closing, 'message': message};

  static LetterKit fromJson(Map<String, Object?> pJson) {
    const vDefault = LetterKit();

    return LetterKit(
      hook: pJson['hook'] as String? ?? vDefault.hook,
      proof: pJson['proof'] as String? ?? vDefault.proof,
      closing: pJson['closing'] as String? ?? vDefault.closing,
      message: pJson['message'] as String? ?? vDefault.message,
    );
  }
}

/// Remplace les `{mots}` connus ; un mot vide ou inconnu disparaît, les espaces sont recollés.
String fillTemplate(String pTemplate, Map<String, String> pValues) {
  final vFilled = pTemplate.replaceAllMapped(
    RegExp(r'\{(\w+)\}'),
    (pMatch) => pValues[pMatch.group(1)!] ?? '',
  );

  return vFilled
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAllMapped(RegExp(r' ([.,;])'), (pMatch) => pMatch.group(1)!)
      .trim();
}

/// Longueur maximale conseillée, en caractères.
int letterLimit(LetterLength pLength) => switch (pLength) {
      LetterLength.full => 2200,
      LetterLength.short => 900,
      LetterLength.message => 450,
    };

/// Les projets de la version les plus proches de l'offre, avec leur première ligne.
List<({String name, String detail})> _proofs(
  CvProfile pProfile,
  CvVersion pVersion,
  String pOffer,
  int pCount,
) {
  final vTailored = tailorVersion(pProfile, pVersion, pOffer);
  final rProofs = <({String name, String detail})>[];

  for (final vId in vTailored.projectIds) {
    for (final vProject in pProfile.projects) {
      if (vProject.id == vId && rProofs.length < pCount) {
        rProofs.add((
          name: vProject.name,
          detail: vProject.lines.isEmpty ? '' : vProject.lines.first,
        ));
      }
    }
  }

  return rProofs;
}

String _sentence(String pText) {
  final vText = pText.trim();
  final rText = vText.isEmpty || RegExp(r'[.!?…]$').hasMatch(vText) ? vText : '$vText.';

  return rText;
}

/// La lettre, un paragraphe par élément.
List<String> buildLetter({
  required CvProfile pProfile,
  required CvVersion pVersion,
  required LetterKit pKit,
  required LetterLength pLength,
  String pOffer = '',
  String pCompany = '',
  String pJob = '',
}) {
  final vContact = pProfile.contact;
  final vProofs = _proofs(pProfile, pVersion, pOffer, pLength == LetterLength.full ? 2 : 1);
  final vBase = {
    'poste': pJob.trim(),
    'entreprise': pCompany.trim(),
    'nom': vContact.name,
    'telephone': vContact.phone,
    'disponibilite': _sentence(vContact.availability),
    'preavis': _sentence(vContact.notice),
    'accroche': pVersion.summary.trim(),
    'virage': pVersion.pivot.trim(),
  };

  String proof(({String name, String detail}) pProof) => fillTemplate(
        pKit.proof,
        {...vBase, 'projet': pProof.name, 'projet_detail': _sentence(pProof.detail)},
      );

  final rParagraphs = <String>[];
  if (pLength == LetterLength.message) {
    rParagraphs.add(
      fillTemplate(pKit.message, {...vBase, 'projet': vProofs.isEmpty ? '' : vProofs.first.name}),
    );
  } else {
    rParagraphs.add(fillTemplate(pKit.hook, vBase));
    if (pLength == LetterLength.full && vBase['accroche']!.isNotEmpty) {
      rParagraphs.add(vBase['accroche']!);
    }
    if (pLength == LetterLength.full && vBase['virage']!.isNotEmpty) {
      rParagraphs.add(vBase['virage']!);
    }
    rParagraphs.addAll(vProofs.map(proof));
    rParagraphs.add(fillTemplate(pKit.closing, vBase));
  }

  return [
    for (final vParagraph in rParagraphs)
      if (vParagraph.isNotEmpty) vParagraph,
  ];
}

enum LetterFindingKind {
  stockPhrase,
  repeatedI,
  tooLong,
  placeholder,
  figure,
  missingCompany,
  inflatedWord,
  symmetry,
  dashes,
}

class LetterFinding {
  const LetterFinding(this.kind, [this.text = '']);

  final LetterFindingKind kind;

  /// La formule, la phrase ou le mot concerné.
  final String text;
}

/// Formules de lettre type, comparées sans accent ni casse.
const stockPhrases = [
  'je me permets',
  'motive et dynamique',
  'dynamique et motive',
  "n'hesitez pas",
  "dans l'attente de",
  'fort de mon experience',
  'veritable atout',
  'passionne par',
  'je suis convaincu',
  'au sein de votre',
  'mettre a profit',
  'force de proposition',
  'relever de nouveaux defis',
  'je serais ravi',
  'serait un plaisir',
  "a l'ecoute",
];

/// Mots gonflés qui sonnent « texte généré » : on dit ce que fait la chose à la place.
const inflatedWords = [
  'robuste',
  'puissant',
  'fluide',
  'essentiel',
  'crucial',
  'elegant',
  'revolutionnaire',
  'plonger dans',
  'paysage actuel',
];

/// Symétries toutes faites, repérées sur le texte sans accent ni casse.
final symmetryPatterns = [
  RegExp(r'non seulement\b.*\bmais aussi'),
  RegExp(r"d'un cote\b.*\bde l'autre"),
  RegExp(r"ce n'est pas\b[^.]{1,60},\s*c'est\b"),
];

/// Tirets longs au-delà desquels le texte se lit comme écrit par une machine.
const dashLimit = 1;

/// Relecture : ce qui sonne comme une lettre type, ce qui est trop long, ce qui manque.
List<LetterFinding> reviewLetter(String pText, LetterLength pLength, {String pCompany = ''}) {
  final vPlain = cvPlain(pText).replaceAll('’', "'");
  final rFindings = <LetterFinding>[];

  for (final vPhrase in stockPhrases) {
    if (vPlain.contains(vPhrase)) {
      rFindings.add(LetterFinding(LetterFindingKind.stockPhrase, vPhrase));
    }
  }

  for (final vWord in inflatedWords) {
    if (RegExp('\\b${RegExp.escape(vWord)}').hasMatch(vPlain)) {
      rFindings.add(LetterFinding(LetterFindingKind.inflatedWord, vWord));
    }
  }
  for (final vPattern in symmetryPatterns) {
    final vMatch = vPattern.firstMatch(vPlain);
    if (vMatch != null) {
      rFindings.add(LetterFinding(LetterFindingKind.symmetry, vMatch.group(0)!));
    }
  }
  final vDashes = RegExp('[—–]').allMatches(pText).length;
  if (vDashes > dashLimit) {
    rFindings.add(LetterFinding(LetterFindingKind.dashes, '$vDashes'));
  }

  final vSentences = pText
      .split(RegExp(r'(?<=[.!?])\s+|\n+'))
      .map((pSentence) => pSentence.trim())
      .where((pSentence) => pSentence.isNotEmpty)
      .toList();
  var vRun = 0;
  for (final vSentence in vSentences) {
    vRun = RegExp(r"^(je\b|j')", caseSensitive: false).hasMatch(vSentence) ? vRun + 1 : 0;
    if (vRun == 3) {
      rFindings.add(LetterFinding(LetterFindingKind.repeatedI, vSentence));
    }
    if (hasFigure(vSentence)) {
      rFindings.add(LetterFinding(LetterFindingKind.figure, vSentence));
    }
  }

  if (pText.length > letterLimit(pLength)) {
    rFindings.add(LetterFinding(LetterFindingKind.tooLong, '${pText.length}'));
  }
  for (final vMatch in RegExp(r'\{\w+\}').allMatches(pText)) {
    rFindings.add(LetterFinding(LetterFindingKind.placeholder, vMatch.group(0)!));
  }
  if (pCompany.trim().isEmpty) {
    rFindings.add(const LetterFinding(LetterFindingKind.missingCompany));
  }

  return rFindings;
}
