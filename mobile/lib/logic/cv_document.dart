// Le CV prêt à écrire : une version appliquée au parcours donne un document de texte simple,
// que le Word, le PDF et le contrôle lisent tous de la même façon.

import 'dart:convert';

import 'cv_profile.dart';
import 'cv_version.dart';

/// Un bloc d'une section : un poste, un diplôme, un projet, un groupe de compétences.
class CvBlock {
  const CvBlock({
    this.title = '',
    this.detail = '',
    this.dates = '',
    this.lines = const [],
    this.level = 0,
  });

  final String title;

  /// Employeur, lieu ou adresse.
  final String detail;
  final String dates;
  final List<String> lines;

  /// Niveau de 0 à 5 pour les étoiles du PDF visuel.
  final int level;
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
    this.photo = const [],
  });

  /// Photo JPEG pour le PDF visuel ; vide sans photo.
  final List<int> photo;

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
String cvHeading(CvSection pSection, {String pLanguage = 'fr'}) => pLanguage == 'en'
    ? switch (pSection) {
        CvSection.summary => 'Profile',
        CvSection.experience => 'Professional experience',
        CvSection.projects => 'Projects',
        CvSection.skills => 'Skills',
        CvSection.education => 'Education',
        CvSection.certifications => 'Certifications and licences',
        CvSection.languages => 'Languages',
        CvSection.strengths => 'Strengths',
        CvSection.interests => 'Interests',
      }
    : switch (pSection) {
      CvSection.summary => 'Profil',
      CvSection.experience => 'Expériences professionnelles',
      CvSection.projects => 'Projets',
      CvSection.skills => 'Compétences',
      CvSection.education => 'Formation',
      CvSection.certifications => 'Habilitations et permis',
      CvSection.languages => 'Langues',
      CvSection.strengths => 'Atouts',
      CvSection.interests => "Centres d'intérêt",
    };

/// Remplace, sans tenir compte de la casse, chaque ancien mot par le mot choisi pour la version.
String applyWording(String pText, Map<String, String> pWording) {
  var rText = pText;
  for (final vEntry in pWording.entries) {
    if (vEntry.key.trim().isNotEmpty) {
      rText =
          rText.replaceAll(RegExp(RegExp.escape(vEntry.key), caseSensitive: false), vEntry.value);
    }
  }

  return rText;
}

CvDocument buildCvDocument(CvProfile pProfile, CvVersion pVersion) {
  final vContact = pProfile.contact;
  String word(String pText) => applyWording(pText, pVersion.wording);
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
            if (pVersion.summary.trim().isNotEmpty) CvBlock(lines: [word(pVersion.summary.trim())]),
          ],
        CvSection.experience => [
            for (final vId in pVersion.experienceIds)
              if (byId(pProfile.experiences, vId, (pItem) => pItem.id) case final vItem?)
                CvBlock(
                    title: vItem.title,
                    detail: vItem.company,
                    dates: vItem.dates,
                    lines: [for (final vLine in vItem.lines) word(vLine)]),
          ],
        CvSection.projects => [
            for (final vId in pVersion.projectIds)
              if (byId(pProfile.projects, vId, (pItem) => pItem.id) case final vItem?)
                CvBlock(
                    title: vItem.name,
                    detail: vItem.url,
                    lines: [for (final vLine in vItem.lines) word(vLine)]),
          ],
        CvSection.skills => [
            for (final vId in pVersion.skillIds)
              if (byId(pProfile.skills, vId, (pItem) => pItem.id) case final vItem?)
                CvBlock(title: vItem.title, lines: [vItem.items.join(', ')], level: vItem.level),
          ],
        CvSection.education => [
            for (final vItem in pProfile.education)
              CvBlock(title: vItem.title, detail: vItem.place, dates: vItem.dates),
          ],
        CvSection.certifications => [
            for (final vItem in pProfile.certifications)
              CvBlock(title: vItem.title, detail: vItem.detail, dates: vItem.dates),
          ],
        CvSection.languages => [
            for (final vItem in pProfile.languages)
              CvBlock(title: vItem.name, lines: [if (vItem.level.isNotEmpty) vItem.level]),
          ],
        CvSection.strengths => [
            if (pProfile.strengths.isNotEmpty) CvBlock(lines: pProfile.strengths)
          ],
        CvSection.interests => [
            if (pProfile.interests.isNotEmpty) CvBlock(lines: pProfile.interests)
          ],
      };

  final rDocument = CvDocument(
    photo: pVersion.withPhoto ? photoBytes(pProfile.photo) : const [],
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
          CvSectionText(section: vSection, heading: cvHeading(vSection, pLanguage: pVersion.language), blocks: vBlocks),
    ],
  );

  return rDocument;
}

/// Octets d'une photo JPEG codée en base 64 ; vide si le texte n'est pas une photo JPEG.
List<int> photoBytes(String pBase64) {
  try {
    final vBytes = base64Decode(pBase64.trim());

    return vBytes.length > 4 && vBytes[0] == 0xFF && vBytes[1] == 0xD8 ? vBytes : const [];
  } on FormatException {
    return const [];
  }
}
