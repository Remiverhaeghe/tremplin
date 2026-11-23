// Le CV prêt à écrire : une version appliquée au parcours donne un document de texte simple,
// que le Word, le PDF et le contrôle lisent tous de la même façon.

import 'cv_profile.dart';
import 'cv_version.dart';

/// Un bloc d'une section : un poste, un diplôme, un projet, un groupe de compétences.
class CvBlock {
  const CvBlock({this.title = '', this.detail = '', this.dates = '', this.lines = const []});

  final String title;

  /// Employeur, lieu ou adresse.
  final String detail;
  final String dates;
  final List<String> lines;
}

class CvSectionText {
  const CvSectionText({required this.section, required this.heading, required this.blocks});

  final CvSection section;
  final String heading;
  final List<CvBlock> blocks;
}

class CvDocument {
  const CvDocument({
    required this.name,
    required this.headline,
    required this.contactLines,
    required this.sections,
  });

  final String name;
  final String headline;

  /// Coordonnées en clair, une ligne chacune.
  final List<String> contactLines;
  final List<CvSectionText> sections;

  /// Tout le texte du CV, dans l'ordre de lecture, pour le contrôle des mots-clés.
  String get plainText {
    final vOut = StringBuffer()
      ..writeln(name)
      ..writeln(headline);
    for (final vLine in contactLines) {
      vOut.writeln(vLine);
    }
    for (final vSection in sections) {
      vOut.writeln(vSection.heading);
      for (final vBlock in vSection.blocks) {
        for (final vPart in [vBlock.title, vBlock.detail, vBlock.dates, ...vBlock.lines]) {
          if (vPart.isNotEmpty) {
            vOut.writeln(vPart);
          }
        }
      }
    }

    return vOut.toString();
  }
}

/// Titres de section : ceux que les logiciels de tri reconnaissent.
String cvHeading(CvSection pSection) => switch (pSection) {
  CvSection.summary => 'Profil',
  CvSection.experience => 'Expériences professionnelles',
  CvSection.projects => 'Projets',
  CvSection.skills => 'Compétences',
  CvSection.education => 'Formation',
  CvSection.languages => 'Langues',
  CvSection.strengths => 'Atouts',
  CvSection.interests => "Centres d'intérêt",
};

CvDocument buildCvDocument(CvProfile pProfile, CvVersion pVersion) {
  final vContact = pProfile.contact;
  T? byId<T>(Iterable<T> pItems, String pId, String Function(T) pIdOf) {
    for (final vItem in pItems) {
      if (pIdOf(vItem) == pId) {
        return vItem;
      }
    }

    return null;
  }

  List<CvBlock> blocksFor(CvSection pSection) => switch (pSection) {
    CvSection.summary => [
      if (pVersion.summary.trim().isNotEmpty) CvBlock(lines: [pVersion.summary.trim()]),
    ],
    CvSection.experience => [
      for (final vId in pVersion.experienceIds)
        if (byId(pProfile.experiences, vId, (pItem) => pItem.id) case final vItem?)
          CvBlock(title: vItem.title, detail: vItem.company, dates: vItem.dates, lines: vItem.lines),
    ],
    CvSection.projects => [
      for (final vId in pVersion.projectIds)
        if (byId(pProfile.projects, vId, (pItem) => pItem.id) case final vItem?)
          CvBlock(title: vItem.name, detail: vItem.url, lines: vItem.lines),
    ],
    CvSection.skills => [
      for (final vId in pVersion.skillIds)
        if (byId(pProfile.skills, vId, (pItem) => pItem.id) case final vItem?)
          CvBlock(title: vItem.title, lines: [vItem.items.join(', ')]),
    ],
    CvSection.education => [
      for (final vItem in pProfile.education)
        CvBlock(title: vItem.title, detail: vItem.place, dates: vItem.dates),
    ],
    CvSection.languages => [
      for (final vItem in pProfile.languages)
        CvBlock(title: vItem.name, lines: [if (vItem.level.isNotEmpty) vItem.level]),
    ],
    CvSection.strengths => [if (pProfile.strengths.isNotEmpty) CvBlock(lines: pProfile.strengths)],
    CvSection.interests => [if (pProfile.interests.isNotEmpty) CvBlock(lines: pProfile.interests)],
  };

  final rDocument = CvDocument(
    name: vContact.name,
    headline: pVersion.headline,
    contactLines: [
      for (final vLine in [
        vContact.email,
        vContact.phone,
        vContact.city,
        vContact.licence,
        vContact.notice,
        vContact.availability,
      ])
        if (vLine.trim().isNotEmpty) vLine.trim(),
    ],
    sections: [
      for (final vSection in pVersion.sections)
        if (blocksFor(vSection) case final vBlocks when vBlocks.isNotEmpty)
          CvSectionText(section: vSection, heading: cvHeading(vSection), blocks: vBlocks),
    ],
  );

  return rDocument;
}
