import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/cv_check.dart';
import 'package:jobboard_revision/logic/cv_docx.dart';
import 'package:jobboard_revision/logic/cv_document.dart';
import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_version.dart';

/// Parcours fictif : aucune donnée réelle dans les tests.
const _profile = CvProfile(
  contact: CvContact(
    name: 'Camille Durand',
    email: 'camille.durand@example.org',
    phone: '+33 6 00 00 00 00',
    city: 'Lille (59)',
    notice: 'Préavis : 1 mois',
  ),
  experiences: [
    CvExperience(
      id: 'dev',
      title: 'Développeuse Java',
      company: 'Atelier Exemple',
      dates: '2020 à aujourd’hui',
      lines: ['Maintenance d’une application métier', 'Interfaces avec un ERP en SFTP'],
    ),
    CvExperience(
      id: 'maint',
      title: 'Responsable de maintenance',
      company: 'Usine Exemple',
      dates: '2010 - 2019',
      lines: ['Planification des interventions'],
    ),
  ],
  education: [CvEducation(id: 'bts', title: 'BTS Maintenance', place: 'Lycée Exemple', dates: '2008')],
  projects: [
    CvProject(id: 'p1', name: 'Calculatrice', url: 'https://example.org/calc', lines: ['Java Swing']),
  ],
  skills: [
    CvSkillGroup(id: 's1', title: 'Développement', items: ['Java', 'SQL', 'API REST']),
  ],
  languages: [CvLanguage(name: 'Anglais', level: 'B2')],
  strengths: ['Rigueur', 'Esprit d’analyse'],
);

const _version = CvVersion(
  id: 'dev',
  label: 'Développeur',
  headline: 'Développeuse Java',
  summary: 'Dix ans d’industrie, cinq ans d’informatique.',
  sections: [
    CvSection.summary,
    CvSection.experience,
    CvSection.projects,
    CvSection.skills,
    CvSection.education,
    CvSection.languages,
  ],
  experienceIds: ['dev', 'maint', 'inconnu'],
  projectIds: ['p1'],
  skillIds: ['s1'],
);

void main() {
  test('le parcours survit à un aller-retour JSON', () {
    final vBack = CvProfile.tryParse(jsonEncode(_profile.toJson()))!;

    expect(vBack.contact.name, 'Camille Durand');
    expect(vBack.experiences.map((pItem) => pItem.id), ['dev', 'maint']);
    expect(vBack.experiences.first.lines, hasLength(2));
    expect(vBack.projects.single.url, 'https://example.org/calc');
    expect(vBack.languages.single.level, 'B2');
    expect(vBack.strengths, ['Rigueur', 'Esprit d’analyse']);
  });

  test('un fichier qui n\'est pas un parcours est refusé', () {
    expect(CvProfile.tryParse('pas du json'), isNull);
    expect(CvProfile.tryParse('[1, 2]'), isNull);
    expect(CvProfile.tryParse('{"experiences": [{"title": "sans id"}]}'), isNull);
    expect(const CvProfile().isEmpty, isTrue);
    expect(_profile.isEmpty, isFalse);
  });

  test('la version garde ses sections dans l\'ordre et ignore un identifiant inconnu', () {
    final vDocument = buildCvDocument(_profile, _version);

    expect(vDocument.sections.map((pItem) => pItem.heading), [
      'Profil',
      'Expériences professionnelles',
      'Projets',
      'Compétences',
      'Formation',
      'Langues',
    ]);
    final vExperience = vDocument.sections[1];
    expect(vExperience.blocks.map((pItem) => pItem.title), [
      'Développeuse Java',
      'Responsable de maintenance',
    ]);
    expect(vDocument.contactLines, contains('Préavis : 1 mois'));
    expect(vDocument.sections[3].blocks.single.lines.single, 'Java, SQL, API REST');
  });

  test('une section vide n\'apparaît pas', () {
    final vDocument = buildCvDocument(
      _profile,
      _version.copyWith(
        summary: '  ',
        sections: [CvSection.summary, CvSection.interests, CvSection.strengths],
      ),
    );

    expect(vDocument.sections.map((pItem) => pItem.heading), ['Atouts']);
  });

  test('la version se relit depuis son JSON, section inconnue ignorée', () {
    final vJson = _version.toJson()..['sections'] = ['experience', 'nimporte'];
    final vBack = CvVersion.fromJson(jsonDecode(jsonEncode(vJson)) as Map<String, Object?>);

    expect(vBack.sections, [CvSection.experience]);
    expect(vBack.label, 'Développeur');
    expect(vBack.withPhoto, isFalse);
  });

  test('les versions de départ reprennent tout le parcours, sans phrase écrite', () {
    final vVersions = startingVersions(_profile);

    expect(vVersions.map((pItem) => pItem.id), ['developpeur', 'industrie']);
    expect(vVersions.first.projectIds, ['p1']);
    expect(vVersions.last.experienceIds, ['maint', 'dev']);
    expect(vVersions.every((pItem) => pItem.summary.isEmpty && pItem.headline.isEmpty), isTrue);
  });

  test('contrôle : un CV complet passe, un CV sans dates ni accroche non', () {
    expect(checkCv(buildCvDocument(_profile, _version)).every((pCheck) => pCheck.ok), isTrue);

    final vWeak = buildCvDocument(
      const CvProfile(
        contact: CvContact(name: 'Camille Durand', email: 'pas-un-courriel'),
        experiences: [CvExperience(id: 'a', title: 'Poste', dates: 'récemment')],
      ),
      const CvVersion(
        id: 'x',
        label: 'x',
        sections: [CvSection.experience],
        experienceIds: ['a'],
      ),
    );
    final vFailed = {
      for (final vCheck in checkCv(vWeak))
        if (!vCheck.ok) vCheck.code,
    };

    expect(vFailed, {
      CvCheckCode.email,
      CvCheckCode.phone,
      CvCheckCode.headline,
      CvCheckCode.summary,
      CvCheckCode.education,
      CvCheckCode.dates,
    });
  });

  test('mots-clés d\'une offre : les plus fréquents, sans mots courants ni accents', () {
    const vOffer = 'Nous recherchons un développeur Java pour notre équipe. '
        'Java, SQL et API REST. Expérience en maintenance. Java 8, Hibernate.';
    final vWords = offerKeywords(vOffer);

    expect(vWords.first, 'java');
    expect(vWords, containsAll(['sql', 'hibernate', 'maintenance', 'developpeur']));
    expect(vWords, isNot(contains('nous')));
    expect(vWords, isNot(contains('equipe')));
    expect(vWords, isNot(contains('8')));
    expect(offerKeywords(vOffer, pLimit: 2), hasLength(2));
  });

  test('mots-clés : présents et absents du CV, accents ignorés', () {
    final vDocument = buildCvDocument(_profile, _version);
    final vReport = keywordReport('Java SQL Hibernate Développeuse robotique Kubernetes', vDocument);

    expect(vReport.found, containsAll(['java', 'sql', 'developpeuse']));
    expect(vReport.missing, containsAll(['hibernate', 'robotique', 'kubernetes']));
  });

  test('Word : un zip valide, du vrai texte, les caractères spéciaux protégés', () {
    final vDocument = buildCvDocument(
      _profile.toJson().isEmpty
          ? _profile
          : CvProfile(
              contact: _profile.contact,
              experiences: const [
                CvExperience(
                  id: 'a',
                  title: 'R&D <test>',
                  dates: '2020',
                  lines: ['Ligne une', 'Ligne deux'],
                ),
              ],
            ),
      const CvVersion(
        id: 'x',
        label: 'x',
        headline: 'Poste visé',
        sections: [CvSection.experience],
        experienceIds: ['a'],
      ),
    );
    final vBytes = buildCvDocx(vDocument);
    final vFiles = {for (final vFile in ZipDecoder().decodeBytes(vBytes)) vFile.name: vFile};

    expect(
      vFiles.keys,
      containsAll(['[Content_Types].xml', '_rels/.rels', 'word/document.xml', 'word/styles.xml']),
    );
    final vXml = utf8.decode(vFiles['word/document.xml']!.content as List<int>);
    expect(vXml, contains('Camille Durand'));
    expect(vXml, contains('Poste visé'));
    expect(vXml, contains('Expériences professionnelles'));
    expect(vXml, contains('R&amp;D &lt;test&gt;'));
    expect(vXml, contains('• Ligne une'));
    expect(vXml, contains('w:pStyle w:val="Heading1"'));
    expect(vXml, isNot(contains('<test>')));
  });
}
