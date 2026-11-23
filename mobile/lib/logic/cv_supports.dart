// Les supports publics du CV : texte du profil GitHub, page CV du portfolio, modèles par secteur,
// et contrôle que ce qui est publié dit la même chose que le parcours. Rien d'inventé : tout
// vient du parcours ; le téléphone et le courriel ne sortent jamais dans les textes publics.

import 'cv_check.dart';
import 'cv_letter.dart';
import 'cv_profile.dart';
import 'cv_version.dart';

/// Phrase courte du profil GitHub : poste visé et premières compétences, coupée à [pMax].
String githubBio(CvProfile pProfile, CvVersion pVersion, {int pMax = 160}) {
  final vSkills = [for (final vGroup in pProfile.skills) ...vGroup.items].take(4).join(', ');
  final vParts = [
    if (pVersion.headline.trim().isNotEmpty) pVersion.headline.trim(),
    if (vSkills.isNotEmpty) vSkills,
  ];
  final vText = vParts.join(' · ');

  if (vText.length <= pMax) {
    return vText;
  }
  final vCut = vText.substring(0, pMax - 1);
  final vSpace = vCut.lastIndexOf(' ');

  return '${vSpace > pMax ~/ 2 ? vCut.substring(0, vSpace) : vCut}…';
}

/// Page CV du portfolio en Markdown : sans téléphone ni courriel, projets avec leur lien public.
String portfolioPage(CvProfile pProfile, CvVersion pVersion) {
  final rPage = StringBuffer('# ${pProfile.contact.name}\n');

  if (pVersion.headline.trim().isNotEmpty) {
    rPage.writeln('\n${pVersion.headline.trim()}');
  }
  if (pVersion.summary.trim().isNotEmpty) {
    rPage.writeln('\n${pVersion.summary.trim()}');
  }
  if (pProfile.experiences.isNotEmpty) {
    rPage.writeln('\n## Expériences');
    for (final vItem in pProfile.experiences) {
      rPage.writeln('\n### ${[vItem.title, vItem.company].where((pPart) => pPart.isNotEmpty).join(', ')}');
      if (vItem.dates.isNotEmpty) {
        rPage.writeln(vItem.dates);
      }
      for (final vLine in vItem.lines) {
        rPage.writeln('- $vLine');
      }
    }
  }
  if (pProfile.projects.isNotEmpty) {
    rPage.writeln('\n## Projets');
    for (final vItem in pProfile.projects) {
      rPage.writeln('\n- ${vItem.url.isEmpty ? vItem.name : '[${vItem.name}](${vItem.url})'}');
      for (final vLine in vItem.lines) {
        rPage.writeln('  - $vLine');
      }
    }
  }
  if (pProfile.skills.isNotEmpty) {
    rPage.writeln('\n## Compétences');
    for (final vGroup in pProfile.skills) {
      rPage.writeln('- ${vGroup.title} : ${vGroup.items.join(', ')}');
    }
  }
  if (pProfile.education.isNotEmpty) {
    rPage.writeln('\n## Formation');
    for (final vItem in pProfile.education) {
      rPage.writeln(
          '- ${[vItem.title, vItem.place, vItem.dates].where((pPart) => pPart.isNotEmpty).join(', ')}');
    }
  }

  return rPage.toString();
}

/// Secteurs proposés pour les modèles de lettre, dans l'ordre d'affichage.
const cvSectors = ['industrie', 'numerique', 'banque', 'public'];

/// Modèles de départ d'un secteur : le ton change, les mots entre accolades restent les mêmes.
LetterKit sectorKit(String pSector) => switch (pSector) {
      'industrie' => const LetterKit(
          hook: 'Je souhaite rejoindre {entreprise} comme {poste}, après des années à faire '
              'tourner des lignes de production.',
          proof: 'Un exemple concret : {projet}. {projet_detail}',
          closing: '{disponibilite} {preavis} Je reste joignable au {telephone}.',
          message: 'Bonjour, je candidate au poste de {poste} chez {entreprise}. '
              'Mon CV est en pièce jointe.',
        ),
      'banque' => const LetterKit(
          hook: 'Je vous écris pour le poste de {poste} chez {entreprise}.',
          proof: 'Je peux le montrer par un travail précis : {projet}. {projet_detail}',
          closing: '{disponibilite} {preavis} Je me tiens à votre disposition au {telephone}.',
          message: 'Bonjour, vous trouverez ci-joint ma candidature au poste de {poste} '
              'chez {entreprise}.',
        ),
      'public' => const LetterKit(
          hook: 'Je présente ma candidature au poste de {poste} au sein de {entreprise}.',
          proof: 'Mon parcours se voit dans un projet : {projet}. {projet_detail}',
          closing: '{disponibilite} {preavis} Je suis joignable au {telephone}.',
          message: 'Bonjour, je présente ma candidature au poste de {poste}. '
              'Mon CV est joint à ce message.',
        ),
      _ => const LetterKit(
          hook: 'Le poste de {poste} chez {entreprise} correspond à ce que je construis depuis '
              'plusieurs années.',
          proof: 'Un projet que vous pouvez lire : {projet}. {projet_detail}',
          closing: '{disponibilite} {preavis} Mon numéro : {telephone}.',
          message: 'Bonjour, je candidate au poste de {poste} chez {entreprise}. '
              'Mon CV et mon GitHub sont en lien ci-dessous.',
        ),
    };

enum CvDriftKind { headlineMissing, projectMissing, unknownFigure }

class CvDrift {
  const CvDrift(this.kind, this.text);

  final CvDriftKind kind;

  /// Le poste, le nom du projet ou le chiffre concerné.
  final String text;
}

final _figure = RegExp(r'\d+(?:[.,]\d+)?\s?(?:%|ans|an|projets|utilisateurs|k|m)\b');

/// Ce qui différencie un texte publié (portfolio, LinkedIn, profil GitHub) du parcours :
/// poste absent, projets du parcours non cités, chiffres qui ne sont pas dans le parcours.
List<CvDrift> supportDrift(CvProfile pProfile, CvVersion pVersion, String pPublished) {
  final vPublished = cvPlain(pPublished);
  final vKnown = cvPlain([
    pVersion.summary,
    for (final vItem in pProfile.experiences) ...[vItem.title, vItem.dates, ...vItem.lines],
    for (final vItem in pProfile.projects) ...[vItem.name, ...vItem.lines],
    for (final vItem in pProfile.education) ...[vItem.title, vItem.dates],
    ...pProfile.strengths,
  ].join('\n'));

  if (vPublished.trim().isEmpty) {
    return const [];
  }

  return [
    if (pVersion.headline.trim().isNotEmpty && !vPublished.contains(cvPlain(pVersion.headline.trim())))
      CvDrift(CvDriftKind.headlineMissing, pVersion.headline.trim()),
    for (final vItem in pProfile.projects)
      if (!vPublished.contains(cvPlain(vItem.name))) CvDrift(CvDriftKind.projectMissing, vItem.name),
    for (final vFigure in {for (final vMatch in _figure.allMatches(vPublished)) vMatch.group(0)!})
      if (!vKnown.contains(vFigure)) CvDrift(CvDriftKind.unknownFigure, vFigure),
  ];
}
