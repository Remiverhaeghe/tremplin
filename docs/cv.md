# CV et lettres dans Tremplin

Le CV vit dans l'appli mobile, onglet Entretien. Le parcours (coordonnées, expériences, projets) est importé une fois, reste sur le téléphone et n'est jamais envoyé au PC. Aucune donnée réelle n'est versionnée : les tests utilisent un parcours fictif.

## Principes

- Une base de données de parcours, plusieurs versions (développeur, industrie et méthodes, etc.).
- Rien n'est inventé : l'adaptation à une offre réordonne ce qui existe, les mots absents sont montrés, jamais ajoutés.
- Le texte reste du vrai texte, en une colonne, avec des titres de section standards, pour passer les logiciels de tri.
- Les projets cités existent en public sur GitHub.

## Lots

| Lot | Évolutions | Contenu | État |
| --- | --- | --- | --- |
| A | 1, 2, 3, 18 | Postuler depuis une offre, PDF sobre et visuel, contrôle avant export, nom de fichier | fait |
| B | 4, 6, 11, 15 | Garde-fou de vérité des projets et des chiffres, mémoire des envois, plusieurs offres d'un coup, une page par version | fait |
| C | 5, 26, 27 | Lettre liée à l'offre en trois longueurs, relecture, réponses aux formulaires | fait |
| D | 7, 9, 13, 22 | Ajout d'un projet au parcours (la proposition automatique depuis le PC viendra avec la synchronisation, lot G), bloc « pourquoi ce virage », traduction des métiers, habilitations | fait, sauf la proposition automatique |
| E | 12, 14, 24, 28 | Écart de compétences, éditeur avant/après, test de lecture ATS, offres au-delà du profil | fait |
| F | 8, 20, 21, 25 | Page portfolio et texte brut, texte du profil GitHub, modèles par secteur, cohérence des supports | fait |
| G | 10, 16, 17, 23, 29, 30 | Relance, historique figé, préparation d'entretien, pièces jointes, statistiques, sauvegarde chiffrée | fait |
| H | 19 | Tout consultable et exportable hors ligne | fait |

Numéros : les 30 évolutions validées le 23 novembre 2026.

## Export

- PDF sobre : noir sur blanc, pour les formulaires et les logiciels de tri.
- PDF visuel : bandeau et titres de section en couleur, même texte, pour l'envoi par courriel.
- Word (`.docx`) et texte brut.
- Le fichier part par la feuille de partage du système (courriel, Drive, enregistrer).

## PDF visuel

Dessiné en vecteurs autour du texte (`lib/logic/cv_pdf_visual.dart`) : photo ronde, pastilles de contact, bandeaux de section, frise du parcours, étoiles de niveau. Champs facultatifs du parcours : `photo` (JPEG en base 64) et `level` (1 à 5) sur chaque famille de compétences. Le PDF sobre, fait pour les logiciels de tri, n'a ni photo ni décor.
