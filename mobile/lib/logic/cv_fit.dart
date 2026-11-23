// Tenir en une ou deux pages sans toucher à la mise en page : on retire d'abord ce qui compte le
// moins, étape par étape, jusqu'à ce que le document tienne. Les expériences, la formation et
// les coordonnées ne sont jamais retirées. Le texte de Rémi n'est jamais coupé en plein milieu :
// on garde des lignes entières ou on n'en garde pas.

import 'cv_document.dart';
import 'cv_pdf.dart';
import 'cv_version.dart';

/// Document ramené à [pMaxPages] pages au plus, avec ce qui a été retiré.
typedef CvFit = ({CvDocument document, List<String> removed, bool fits});

CvSectionText _withBlocks(CvSectionText pSection, List<CvBlock> pBlocks) =>
    CvSectionText(section: pSection.section, heading: pSection.heading, blocks: pBlocks);

CvDocument _replace(CvDocument pDocument, List<CvSectionText> pSections) => CvDocument(
      name: pDocument.name,
      headline: pDocument.headline,
      contactLines: pDocument.contactLines,
      sections: pSections,
    );

CvDocument _without(CvDocument pDocument, CvSection pSection) => _replace(pDocument, [
      for (final vSection in pDocument.sections)
        if (vSection.section != pSection) vSection,
    ]);

/// Garde les [pKeep] premiers blocs d'une section ; la section disparaît à zéro.
CvDocument _limitBlocks(CvDocument pDocument, CvSection pSection, int pKeep) =>
    _replace(pDocument, [
      for (final vSection in pDocument.sections)
        if (vSection.section != pSection)
          vSection
        else if (pKeep > 0 && vSection.blocks.isNotEmpty)
          _withBlocks(vSection, vSection.blocks.take(pKeep).toList()),
    ]);

/// Les expériences au-delà des [pRecent] premières gardent au plus [pLines] lignes.
CvDocument _shortenOldExperiences(CvDocument pDocument, int pRecent, int pLines) =>
    _replace(pDocument, [
      for (final vSection in pDocument.sections)
        if (vSection.section != CvSection.experience)
          vSection
        else
          _withBlocks(vSection, [
            for (var vIndex = 0; vIndex < vSection.blocks.length; vIndex++)
              vIndex < pRecent
                  ? vSection.blocks[vIndex]
                  : CvBlock(
                      title: vSection.blocks[vIndex].title,
                      detail: vSection.blocks[vIndex].detail,
                      dates: vSection.blocks[vIndex].dates,
                      lines: vSection.blocks[vIndex].lines.take(pLines).toList(),
                    ),
          ]),
    ]);

CvFit fitDocument(CvDocument pDocument, int pMaxPages, {CvPdfStyle pStyle = CvPdfStyle.plain}) {
  bool fits(CvDocument pCandidate) => cvPageCount(pCandidate, pStyle: pStyle) <= pMaxPages;

  final vSteps = <(String, CvDocument Function(CvDocument))>[
    ('interests', (pDoc) => _without(pDoc, CvSection.interests)),
    ('strengths', (pDoc) => _without(pDoc, CvSection.strengths)),
    ('projects:3', (pDoc) => _limitBlocks(pDoc, CvSection.projects, 3)),
    ('old-lines:3', (pDoc) => _shortenOldExperiences(pDoc, 2, 3)),
    ('projects:2', (pDoc) => _limitBlocks(pDoc, CvSection.projects, 2)),
    ('old-lines:2', (pDoc) => _shortenOldExperiences(pDoc, 2, 2)),
    ('projects:1', (pDoc) => _limitBlocks(pDoc, CvSection.projects, 1)),
    ('old-lines:1', (pDoc) => _shortenOldExperiences(pDoc, 1, 1)),
    ('projects:0', (pDoc) => _limitBlocks(pDoc, CvSection.projects, 0)),
    ('old-lines:0', (pDoc) => _shortenOldExperiences(pDoc, 1, 0)),
  ];

  var vCurrent = pDocument;
  final rRemoved = <String>[];
  for (final vStep in vSteps) {
    if (fits(vCurrent)) {
      break;
    }
    final vNext = vStep.$2(vCurrent);
    if (vNext.plainText != vCurrent.plainText) {
      rRemoved.add(vStep.$1);
      vCurrent = vNext;
    }
  }

  return (document: vCurrent, removed: rRemoved, fits: fits(vCurrent));
}
