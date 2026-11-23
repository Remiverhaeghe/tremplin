// Réponses prêtes aux questions qui reviennent dans les formulaires de candidature : prétentions,
// mobilité, préavis, pourquoi nous. Rémi les écrit une fois ; l'entreprise et le poste sont
// remplis à chaque offre. Les faits déjà connus (préavis, permis, langues) sont proposés.

import 'cv_letter.dart';
import 'cv_profile.dart';

class CvAnswer {
  const CvAnswer({required this.id, required this.label, this.text = ''});

  final String id;

  /// La question, telle qu'un formulaire la pose.
  final String label;

  /// La réponse, avec les mêmes `{mots}` que la lettre.
  final String text;

  CvAnswer copyWith({String? text}) => CvAnswer(id: id, label: label, text: text ?? this.text);

  Map<String, Object?> toJson() => {'id': id, 'label': label, 'text': text};

  static CvAnswer fromJson(Map<String, Object?> pJson) => CvAnswer(
        id: pJson['id']! as String,
        label: pJson['label']! as String,
        text: pJson['text'] as String? ?? '',
      );
}

/// Questions de départ ; seules celles dont le parcours donne la réponse sont préremplies.
List<CvAnswer> startingAnswers(CvProfile pProfile) {
  final vContact = pProfile.contact;
  final vLanguages = [
    for (final vLanguage in pProfile.languages)
      vLanguage.level.isEmpty ? vLanguage.name : '${vLanguage.name} (${vLanguage.level})',
  ];

  return [
    const CvAnswer(id: 'salary', label: 'Prétentions salariales'),
    const CvAnswer(id: 'mobility', label: 'Mobilité géographique'),
    CvAnswer(id: 'notice', label: 'Préavis', text: vContact.notice),
    CvAnswer(id: 'availability', label: 'Disponibilité', text: vContact.availability),
    const CvAnswer(id: 'why-company', label: 'Pourquoi {entreprise} ?'),
    const CvAnswer(id: 'why-job', label: 'Pourquoi le poste de {poste} ?'),
    CvAnswer(id: 'licence', label: 'Permis', text: vContact.licence),
    CvAnswer(id: 'languages', label: 'Langues', text: vLanguages.join(', ')),
    const CvAnswer(id: 'remote', label: 'Télétravail'),
  ];
}

/// La réponse pour une offre : entreprise et poste remplis.
String answerFor(CvAnswer pAnswer, {String pCompany = '', String pJob = ''}) =>
    fillTemplate(pAnswer.text, {'entreprise': pCompany.trim(), 'poste': pJob.trim()});

/// La question pour une offre, avec l'entreprise et le poste.
String questionFor(CvAnswer pAnswer, {String pCompany = '', String pJob = ''}) =>
    fillTemplate(pAnswer.label, {'entreprise': pCompany.trim(), 'poste': pJob.trim()});
