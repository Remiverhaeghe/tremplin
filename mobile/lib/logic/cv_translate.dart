// Passer d'un métier à un autre sans changer les faits : l'offre parle de « maintenance
// préventive », le CV dit « contrôles périodiques ». L'appli propose le mot du secteur quand
// l'offre l'emploie et que le CV contient l'ancien ; Rémi accepte un mot seulement s'il décrit
// bien ce qu'il a fait.

import 'cv_check.dart';
import 'cv_profile.dart';

/// Un ancien mot du parcours et le mot du secteur visé qui dit la même chose.
typedef CvWording = ({String from, String to});

/// Équivalences de départ entre vocabulaire d'exploitation, de maintenance et de transport.
const defaultWordings = <CvWording>[
  (from: 'planification des interventions', to: 'ordonnancement de la maintenance'),
  (from: 'contrôles périodiques', to: 'maintenance préventive'),
  (from: 'dépannage', to: 'maintenance corrective'),
  (from: 'consignes de sécurité', to: 'règles HSE'),
  (from: 'suivi des stocks', to: 'gestion des approvisionnements'),
  (from: 'tenue des registres', to: 'traçabilité'),
  (from: 'remontée des pannes', to: 'gestion des incidents'),
  (from: 'visite des installations', to: 'ronde de surveillance'),
];

/// Les équivalences utiles pour une offre : le mot du secteur est dans l'offre, l'ancien mot est
/// dans une ligne d'expérience ou de projet, et il n'est pas déjà remplacé.
List<CvWording> suggestWordings(
  String pOffer,
  CvProfile pProfile, {
  Map<String, String> pApplied = const {},
  List<CvWording> pTable = defaultWordings,
}) {
  final vOffer = cvPlain(pOffer);
  final vLines = cvPlain([
    for (final vExperience in pProfile.experiences) ...vExperience.lines,
    for (final vProject in pProfile.projects) ...vProject.lines,
  ].join('\n'));

  return [
    for (final vWording in pTable)
      if (vOffer.contains(cvPlain(vWording.to)) &&
          vLines.contains(cvPlain(vWording.from)) &&
          !pApplied.containsKey(vWording.from))
        vWording,
  ];
}
