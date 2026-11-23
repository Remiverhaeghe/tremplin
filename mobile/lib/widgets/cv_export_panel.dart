// Contrôles avant l'envoi et boutons d'export d'un CV : le même bloc sert à l'écran d'une
// version et à l'écran « postuler à une offre ».

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_check.dart';
import '../logic/cv_docx.dart';
import '../logic/cv_document.dart';
import '../logic/cv_export.dart';
import '../logic/cv_fit.dart';
import '../logic/cv_pdf.dart';
import '../logic/cv_profile.dart';
import '../logic/cv_version.dart';
import '../services/file_sender.dart';
import '../theme.dart';

/// Formats proposés, dans l'ordre des boutons.
const cvFormats = ['pdf-sobre', 'pdf-visuel', 'docx', 'txt'];

String cvCheckLabel(AppLocalizations pTexts, CvCheckCode pCode) => switch (pCode) {
      CvCheckCode.name => pTexts.cvCheckName,
      CvCheckCode.email => pTexts.cvCheckEmail,
      CvCheckCode.phone => pTexts.cvCheckPhone,
      CvCheckCode.headline => pTexts.cvCheckHeadline,
      CvCheckCode.summary => pTexts.cvCheckSummary,
      CvCheckCode.experience => pTexts.cvCheckExperience,
      CvCheckCode.education => pTexts.cvCheckEducation,
      CvCheckCode.dates => pTexts.cvCheckDates,
    };

String cvSectionLabel(AppLocalizations pTexts, CvSection pSection) => switch (pSection) {
      CvSection.summary => pTexts.cvSectionSummary,
      CvSection.experience => pTexts.cvSectionExperience,
      CvSection.projects => pTexts.cvSectionProjects,
      CvSection.skills => pTexts.cvSectionSkills,
      CvSection.education => pTexts.cvSectionEducation,
      CvSection.certifications => pTexts.cvSectionCertifications,
      CvSection.languages => pTexts.cvSectionLanguages,
      CvSection.strengths => pTexts.cvSectionStrengths,
      CvSection.interests => pTexts.cvSectionInterests,
    };

/// Octets, extension et type de contenu d'un export.
({List<int> bytes, String extension, String mime}) renderCv(CvDocument pDocument, String pFormat) =>
    switch (pFormat) {
      'pdf-visuel' => (
          bytes: buildCvPdf(pDocument, pStyle: CvPdfStyle.visual),
          extension: 'pdf',
          mime: mimePdf,
        ),
      'docx' => (bytes: buildCvDocx(pDocument), extension: 'docx', mime: mimeDocx),
      'txt' => (bytes: utf8.encode(pDocument.plainText), extension: 'txt', mime: mimeText),
      _ => (bytes: buildCvPdf(pDocument), extension: 'pdf', mime: mimePdf),
    };

String cvFitLabel(AppLocalizations pTexts, String pCode) => switch (pCode.split(':').first) {
      'interests' => pTexts.cvFitInterests,
      'strengths' => pTexts.cvFitStrengths,
      'projects' => pTexts.cvFitProjects,
      _ => pTexts.cvFitOldLines,
    };

class CvExportPanel extends StatefulWidget {
  const CvExportPanel({
    super.key,
    required this.profile,
    required this.version,
    required this.send,
    this.company = '',
    this.onExported,
  });

  final CvProfile profile;
  final CvVersion version;
  final FileSender send;

  /// Entreprise visée, ajoutée au nom du fichier.
  final String company;

  /// Appelé après l'envoi, avec le format choisi.
  final void Function(String format)? onExported;

  @override
  State<CvExportPanel> createState() => _CvExportPanelState();
}

class _CvExportPanelState extends State<CvExportPanel> {
  /// Longueur voulue : 0 pour libre, sinon le nombre de pages au plus.
  int aMaxPages = 0;

  CvDocument documentFor(String pFormat) {
    final vBase = buildCvDocument(widget.profile, widget.version);
    final vStyle = pFormat == 'pdf-visuel' ? CvPdfStyle.visual : CvPdfStyle.plain;

    return aMaxPages > 0 ? fitDocument(vBase, aMaxPages, pStyle: vStyle).document : vBase;
  }

  Future<void> export(String pFormat) async {
    final vOut = renderCv(documentFor(pFormat), pFormat);
    final vName =
        cvFileName(widget.profile, widget.version, vOut.extension, pCompany: widget.company);

    await widget.send(Uint8List.fromList(vOut.bytes), vName, vOut.mime);
    widget.onExported?.call(pFormat);
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vBase = buildCvDocument(widget.profile, widget.version);
    final vReady = cvReadiness(vBase);
    final vFit = aMaxPages > 0 ? fitDocument(vBase, aMaxPages) : null;
    final vRemoved = {for (final vCode in vFit?.removed ?? <String>[]) cvFitLabel(vTexts, vCode)};
    final vLabels = {
      'pdf-sobre': vTexts.cvExportPdfSobre,
      'pdf-visuel': vTexts.cvExportPdfVisuel,
      'docx': vTexts.cvExportWord,
      'txt': vTexts.cvExportTexte,
    };

    Widget row(CvCheckCode pCode) {
      final vBlocking = vReady.blocking.contains(pCode);
      final vWarning = vReady.warnings.contains(pCode);
      final vColor = vBlocking
          ? dangerColorOf(context)
          : vWarning
              ? Colors.orange.shade800
              : successColorOf(context);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(vBlocking || vWarning ? Icons.close : Icons.check, size: 18, color: vColor),
            const SizedBox(width: 8),
            Expanded(child: Text(cvCheckLabel(vTexts, pCode))),
          ],
        ),
      );
    }

    final rPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vTexts.cvControles, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final vCode in CvCheckCode.values) row(vCode),
        const SizedBox(height: 6),
        Text(
          vReady.canExport ? vTexts.cvControlesPret : vTexts.cvControlesBloque,
          style: TextStyle(
            color: vReady.canExport ? successColorOf(context) : dangerColorOf(context),
          ),
        ),
        const SizedBox(height: 10),
        Text(vTexts.cvPages, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(vTexts.cvPagesLibre)),
            ButtonSegment(value: 1, label: Text(vTexts.cvPagesUne)),
            ButtonSegment(value: 2, label: Text(vTexts.cvPagesDeux)),
          ],
          selected: {aMaxPages},
          onSelectionChanged: (pValue) => setState(() => aMaxPages = pValue.first),
        ),
        if (vRemoved.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(vTexts.cvFitRetire(vRemoved.join(', '))),
        ],
        if (vFit != null && !vFit.fits) ...[
          const SizedBox(height: 6),
          Text(vTexts.cvFitTrop, style: TextStyle(color: dangerColorOf(context))),
        ],
        const SizedBox(height: 10),
        for (final vFormat in cvFormats)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              onPressed: vReady.canExport ? () => export(vFormat) : null,
              child: Text(vLabels[vFormat]!),
            ),
          ),
      ],
    );

    return rPanel;
  }
}
