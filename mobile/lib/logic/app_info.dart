// Identité de l'application, affichée dans l'écran « À propos ».

/// Version publiée ; un test vérifie qu'elle suit celle de pubspec.yaml.
const appVersion = '1.9.0';

/// Dépôt public du projet.
const sourceUrl = 'https://github.com/Remiverhaeghe/tremplin';

/// Adresse d'un signalement prérempli : le titre et le corps portent la version de l'appli et
/// la question concernée, sans aucune donnée personnelle.
Uri reportIssueUri({String? pQuestion}) {
  final vQuestion = pQuestion?.trim() ?? '';
  final vBody = StringBuffer('Version : $appVersion\n');
  if (vQuestion.isNotEmpty) {
    vBody.write('Question : $vQuestion\n');
  }
  vBody.write('\nCe qui est faux, et la bonne réponse :\n');
  final rUri = Uri.parse('$sourceUrl/issues/new').replace(
    queryParameters: {
      'title': vQuestion.isEmpty ? 'Question fausse' : 'Question fausse : $vQuestion',
      'body': vBody.toString(),
    },
  );

  return rUri;
}
