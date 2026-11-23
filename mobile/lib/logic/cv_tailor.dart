// Adapter une version du CV à une offre sans rien inventer : on réordonne ce qui est déjà dans
// la version (projets, groupes de compétences) selon les mots de l'offre. Les expériences
// gardent l'ordre chronologique, que les recruteurs et les logiciels de tri attendent.

import 'cv_check.dart';
import 'cv_profile.dart';
import 'cv_version.dart';

/// Nombre de mots-clés de l'offre présents dans un texte.
int _hits(String pText, List<String> pKeywords) {
  final vText = cvPlain(pText);
  var rHits = 0;
  for (final vWord in pKeywords) {
    if (vText.contains(vWord)) {
      rHits++;
    }
  }

  return rHits;
}

/// Même ordre si deux éléments valent autant : le tri ne bouscule pas ce que Rémi a rangé.
List<String> _rank(List<String> pIds, Map<String, int> pScores) {
  final vIndexed = [for (var vIndex = 0; vIndex < pIds.length; vIndex++) (vIndex, pIds[vIndex])];
  vIndexed.sort((pA, pB) {
    final vByScore = (pScores[pB.$2] ?? 0).compareTo(pScores[pA.$2] ?? 0);
    return vByScore != 0 ? vByScore : pA.$1.compareTo(pB.$1);
  });

  return [for (final vItem in vIndexed) vItem.$2];
}

/// La version, projets et compétences mis dans l'ordre de l'offre. `pMaxProjects` garde
/// seulement les projets les plus proches ; 0 ou moins les garde tous.
CvVersion tailorVersion(
  CvProfile pProfile,
  CvVersion pVersion,
  String pOffer, {
  int pMaxProjects = 0,
}) {
  final vKeywords = offerKeywords(pOffer);
  if (vKeywords.isEmpty) {
    return pVersion;
  }

  final vProjectScores = {
    for (final vProject in pProfile.projects)
      vProject.id: _hits([vProject.name, ...vProject.lines].join(' '), vKeywords),
  };
  final vSkillScores = {
    for (final vGroup in pProfile.skills)
      vGroup.id: _hits([vGroup.title, ...vGroup.items].join(' '), vKeywords),
  };
  final vProjects = _rank(pVersion.projectIds, vProjectScores);
  final rVersion = pVersion.copyWith(
    projectIds: pMaxProjects > 0 ? vProjects.take(pMaxProjects).toList() : vProjects,
    skillIds: _rank(pVersion.skillIds, vSkillScores),
  );

  return rVersion;
}

/// Proximité d'une version avec une offre : part des mots-clés de l'offre que son texte contient.
double offerCoverage(String pOffer, String pCvText) {
  final vKeywords = offerKeywords(pOffer);
  final rCoverage = vKeywords.isEmpty ? 0.0 : _hits(pCvText, vKeywords) / vKeywords.length;

  return rCoverage;
}

/// La version qui couvre le mieux l'offre, avec sa couverture ; null s'il n'y a aucune version.
({CvVersion version, double coverage})? bestVersionFor(
  String pOffer,
  List<CvVersion> pVersions,
  String Function(CvVersion) pTextOf,
) {
  ({CvVersion version, double coverage})? rBest;
  for (final vVersion in pVersions) {
    final vCoverage = offerCoverage(pOffer, pTextOf(vVersion));
    if (rBest == null || vCoverage > rBest.coverage) {
      rBest = (version: vVersion, coverage: vCoverage);
    }
  }

  return rBest;
}
