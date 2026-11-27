# Identité visuelle

Le bureau, le tableau de bord web et l'application mobile partagent la même palette : Tremplin,
c'est la piscine. Les valeurs vivent à un seul endroit par interface et un test
(`tests/gui/test_identity_parity.py`) échoue dès qu'elles s'écartent.

| Rôle | Clair | Sombre | Où |
|---|---|---|---|
| Fond | `#F2FAFB` | `#0A1F27` | `gui/theme.py`, `web/static/css/01-theme.css`, `mobile/lib/theme.dart` |
| Principal (bleu du bassin) | `#0E6F8C` | `#35C2CF` (eau) | idem |
| Grand bain (en-têtes, texte sur le jaune) | `#0B4F66` | `#0B4F66` | idem |
| Plongeoir (objectif, réussite) | `#8A5F00` en texte | `#FFC23D` | `warning` et accent « amber » |
| Danger | `#C81E1E` | `#F87171` | `danger` |
| Succès | `#15803D` | `#22C55E` | `success` |

Règles communes :

- Contrastes WCAG AA vérifiés pour le bureau (`tests/gui/test_theme_contrast.py`) et le web
  (audit axe-core).
- Thème Auto, Clair ou Sombre sur les trois interfaces.
- Le choix d'accent débloqué par niveau est partagé ; l'accent de départ s'appelle « Bleu bassin ».
- Pour changer une couleur : modifier `gui/theme.py`, reporter la valeur dans `01-theme.css` et
  `mobile/lib/theme.dart`, puis lancer les tests.
