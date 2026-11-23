// Lettre à modèles, relecture et réponses de formulaire.

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_answers.dart';
import 'package:jobboard_revision/logic/cv_export.dart';
import 'package:jobboard_revision/logic/cv_letter.dart';
import 'package:jobboard_revision/logic/cv_pdf.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_version.dart';
import 'package:jobboard_revision/revision_state.dart';

import 'cv_pdf_test.dart' show pdfTexts;
import 'support/fake_reminders.dart';
import 'support/sample_data.dart';

const profile = CvProfile(
  contact: CvContact(
    name: 'Camille Durand',
    email: 'camille.durand@example.org',
    phone: '+33 6 00 00 00 00',
    notice: 'Préavis : 1 mois',
    availability: 'Disponible pour un CDI',
    licence: 'Permis B',
  ),
  projects: [
    CvProject(id: 'java', name: 'Calculatrice', lines: ['Une calculatrice en Java Swing']),
    CvProject(id: 'vue', name: 'Portfolio', lines: ['Un site en Vue 3 et Vite', 'Publié en ligne']),
    CvProject(id: 'nolines', name: 'Maquette'),
  ],
  languages: [CvLanguage(name: 'Anglais', level: 'B2')],
);

const version = CvVersion(
  id: 'dev',
  label: 'Développeur',
  summary: 'Dix ans d\'industrie, cinq ans d\'informatique.',
  projectIds: ['java', 'vue', 'nolines'],
);

List<String> letter(LetterLength pLength, {String pOffer = '', String pCompany = 'Exemple SA'}) =>
    buildLetter(
      pProfile: profile,
      pVersion: version,
      pKit: const LetterKit(),
      pLength: pLength,
      pOffer: pOffer,
      pCompany: pCompany,
      pJob: 'Développeur web',
    );

void main() {
  group('modèles', () {
    test('les mots connus sont remplis, les autres disparaissent proprement', () {
      expect(
        fillTemplate('Chez {entreprise}. {inconnu} Fin', {'entreprise': 'Exemple'}),
        'Chez Exemple. Fin',
      );
      expect(fillTemplate('A {vide} , b {vide}.', {'vide': ''}), 'A, b.');
    });

    test('la lettre complète : début, accroche, deux projets proches de l\'offre, fin', () {
      final vParagraphs = letter(LetterLength.full, pOffer: 'Développeur Vue Vite web');

      expect(vParagraphs, hasLength(5));
      expect(vParagraphs.first, 'Je candidate au poste de Développeur web chez Exemple SA.');
      expect(vParagraphs[1], version.summary);
      expect(vParagraphs[2], startsWith('Un exemple concret : Portfolio.'));
      expect(vParagraphs[2], contains('Un site en Vue 3 et Vite.'));
      expect(vParagraphs[3], startsWith('Un exemple concret : Calculatrice.'));
      expect(vParagraphs.last, contains('Disponible pour un CDI.'));
      expect(vParagraphs.last, contains('Préavis : 1 mois.'));
      expect(vParagraphs.last, contains('+33 6 00 00 00 00'));
      expect(vParagraphs.join(), isNot(contains('{')));
    });

    test('la lettre courte garde un seul projet et pas d\'accroche', () {
      final vParagraphs = letter(LetterLength.short, pOffer: 'Java Swing');

      expect(vParagraphs, hasLength(3));
      expect(vParagraphs[1], contains('Calculatrice'));
      expect(vParagraphs.join(), isNot(contains(version.summary)));
    });

    test('le message tient en un paragraphe', () {
      final vParagraphs = letter(LetterLength.message);

      expect(vParagraphs, [
        'Bonjour, je candidate au poste de Développeur web chez Exemple SA. '
            'Mon CV est en pièce jointe.',
      ]);
    });

    test('sans projet, la lettre garde le début, l\'accroche et la fin', () {
      final vParagraphs = buildLetter(
        pProfile: const CvProfile(contact: CvContact(name: 'Camille Durand')),
        pVersion: version.copyWith(projectIds: []),
        pKit: const LetterKit(),
        pLength: LetterLength.full,
        pCompany: 'Exemple SA',
        pJob: 'Technicien',
      );

      expect(vParagraphs, hasLength(3));
    });

    test('les modèles de Rémi servent à la place de ceux de départ', () {
      final vParagraphs = buildLetter(
        pProfile: profile,
        pVersion: version,
        pKit: const LetterKit(
            hook: 'Bonjour {entreprise}, parlons de {poste}.', closing: 'À bientôt, {nom}.'),
        pLength: LetterLength.short,
        pCompany: 'Exemple SA',
        pJob: 'Technicien',
      );

      expect(vParagraphs.first, 'Bonjour Exemple SA, parlons de Technicien.');
      expect(vParagraphs.last, 'À bientôt, Camille Durand.');
    });

    test('les modèles survivent à un redémarrage', () async {
      final vStore = MemoryRevisionStore();
      final vState = RevisionState(vStore, reminders: FakeReminders());
      await vState.load();
      expect(vState.cvLetterKit.hook, const LetterKit().hook);

      await vState.saveCvLetterKit(const LetterKit(hook: 'Mon début'));
      await vState.saveCvAnswers([const CvAnswer(id: 'x', label: 'Question', text: 'Réponse')]);
      final vAgain = RevisionState(vStore, reminders: FakeReminders());
      await vAgain.load();

      expect(vAgain.cvLetterKit.hook, 'Mon début');
      expect(vAgain.cvLetterKit.closing, const LetterKit().closing);
      expect(vAgain.cvAnswers.single.text, 'Réponse');
    });
  });

  group('relecture', () {
    List<LetterFindingKind> kinds(String pText,
            {LetterLength pLength = LetterLength.full, String pCompany = 'Exemple SA'}) =>
        [for (final vFinding in reviewLetter(pText, pLength, pCompany: pCompany)) vFinding.kind];

    test('une lettre sobre n\'a rien à signaler', () {
      expect(kinds('Je candidate au poste de technicien. Mon CV est joint.'), isEmpty);
    });

    test(
        'les formules toutes faites sont repérées, sans accent ni casse, apostrophe courbe comprise',
        () {
      expect(
        kinds('Je me permets de vous écrire. N’hésitez pas à me contacter. MOTIVÉ ET DYNAMIQUE.'),
        [
          LetterFindingKind.stockPhrase,
          LetterFindingKind.stockPhrase,
          LetterFindingKind.stockPhrase
        ],
      );
    });

    test('trois phrases de suite en « je » sont signalées une fois', () {
      expect(kinds('Je code. Je teste. J\'écris. Voilà.'), [LetterFindingKind.repeatedI]);
      expect(kinds('Je code. Je teste. Voilà. J\'écris.'), isEmpty);
    });

    test('trop long, mot à remplir, chiffre et entreprise manquante', () {
      expect(kinds('mot ' * 300, pLength: LetterLength.short), [LetterFindingKind.tooLong]);
      expect(kinds('Poste de {poste}.'), [LetterFindingKind.placeholder]);
      expect(kinds('J\'ai réduit les arrêts de 30 % en un an.'), [LetterFindingKind.figure]);
      expect(kinds('Bonjour.', pCompany: '  '), [LetterFindingKind.missingCompany]);
    });
  });

  group('réponses de formulaire', () {
    test('les faits du parcours sont préremplis, le reste est à écrire', () {
      final vAnswers = {for (final vItem in startingAnswers(profile)) vItem.id: vItem.text};

      expect(vAnswers['notice'], 'Préavis : 1 mois');
      expect(vAnswers['availability'], 'Disponible pour un CDI');
      expect(vAnswers['licence'], 'Permis B');
      expect(vAnswers['languages'], 'Anglais (B2)');
      expect(vAnswers['salary'], '');
    });

    test('l\'entreprise et le poste sont remplis dans la question et dans la réponse', () {
      const vAnswer = CvAnswer(
        id: 'why',
        label: 'Pourquoi {entreprise} ?',
        text: 'Le poste de {poste} chez {entreprise} correspond à mon parcours.',
      );

      expect(questionFor(vAnswer, pCompany: 'Exemple SA', pJob: 'Technicien'),
          'Pourquoi Exemple SA ?');
      expect(
        answerFor(vAnswer, pCompany: 'Exemple SA', pJob: 'Technicien'),
        'Le poste de Technicien chez Exemple SA correspond à mon parcours.',
      );
    });
  });

  group('lettre en PDF', () {
    test('les paragraphes sont du vrai texte et le fichier est bien nommé', () {
      final vPdf = buildLetterPdf(
        pName: 'Camille Durand',
        pContactLines: ['camille.durand@example.org'],
        pParagraphs: letter(LetterLength.full),
      );
      final vText = pdfTexts(String.fromCharCodes(vPdf)).join('\n');

      expect(vText, contains('Camille Durand'));
      expect(vText, contains('Je candidate au poste de Développeur web chez Exemple SA.'));
      expect(cvLetterFileName('Camille Durand', 'Société Générale'),
          'Camille-Durand-Lettre-Societe-Generale.pdf');
    });
  });
}
