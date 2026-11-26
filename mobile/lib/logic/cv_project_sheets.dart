// Fiches de projets publics de Rémi, à reprendre dans le CV. Chaque ligne vient du CLAUDE.md du
// dépôt concerné : rien n'est ajouté qui ne s'y trouve pas, Rémi relit et corrige avant de garder.

import 'cv_profile.dart';

/// Brouillon de projet : même contenu qu'un [CvProject], sans identifiant.
typedef CvProjectSheet = ({String name, String url, List<String> lines});

const cvProjectSheets = <CvProjectSheet>[
  (
    name: 'Atelier',
    url: 'https://github.com/Remiverhaeghe/atelier',
    lines: [
      'Application Android en Flutter pour préparer des travaux : parquet, plinthes et carrelage.',
      'Règles de calcul en Dart pur, testées unitairement, avec une couverture de 95 % au moins '
          'contrôlée par la CI.',
      'Données gardées sur le téléphone, aucune permission réseau.',
      'Version web utilisable hors ligne.',
    ],
  ),
  (
    name: 'Kalkul',
    url: 'https://github.com/Remiverhaeghe/kalkul',
    lines: [
      'Calculatrice de bureau en Java 17 avec Swing, construite avec Maven.',
      'Un onglet par famille de calculs : base, scientifique, financier, graphique, programmeur, '
          'chantier, outils et historique.',
      'Logique séparée de l\'interface pour rester testable ; chaque correction de bug '
          's\'accompagne d\'un test.',
      'Taux de change hors ligne, saisis ou importés d\'un fichier.',
    ],
  ),
];

/// Projet du profil créé depuis une fiche, avec l'identifiant donné.
CvProject projectFromSheet(CvProjectSheet pSheet, String pId) {
  final rProject = CvProject(id: pId, name: pSheet.name, url: pSheet.url, lines: pSheet.lines);

  return rProject;
}
