// Lettre de motivation pour une offre : modèle rempli, trois longueurs, relecture des formules
// toutes faites, copie et PDF.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/texts.dart';
import '../logic/cv_document.dart';
import '../logic/cv_export.dart';
import '../logic/cv_letter.dart';
import '../logic/cv_pdf.dart';
import '../logic/cv_tailor.dart';
import '../logic/cv_version.dart';
import '../revision_state.dart';
import '../services/file_sender.dart';
import 'cv_apply_screen.dart';

String findingLabel(AppLocalizations pTexts, LetterFinding pFinding, LetterLength pLength) =>
    switch (pFinding.kind) {
      LetterFindingKind.stockPhrase => pTexts.cvRelectureFormule(pFinding.text),
      LetterFindingKind.repeatedI => pTexts.cvRelectureJe(pFinding.text),
      LetterFindingKind.tooLong =>
        pTexts.cvRelectureLong(pFinding.text, letterLimit(pLength).toString()),
      LetterFindingKind.placeholder => pTexts.cvRelectureAccolade(pFinding.text),
      LetterFindingKind.figure => pTexts.cvRelectureChiffre(pFinding.text),
      LetterFindingKind.missingCompany => pTexts.cvRelectureEntreprise,
      LetterFindingKind.inflatedWord => pTexts.cvRelectureGonfle(pFinding.text),
      LetterFindingKind.symmetry => pTexts.cvRelectureSymetrie(pFinding.text),
      LetterFindingKind.dashes => pTexts.cvRelectureTirets(pFinding.text),
    };

class CvLetterScreen extends StatefulWidget {
  const CvLetterScreen({
    super.key,
    required this.state,
    required this.offer,
    this.send = shareFile,
  });

  final RevisionState state;
  final Map<String, dynamic> offer;
  final FileSender send;

  @override
  State<CvLetterScreen> createState() => _CvLetterScreenState();
}

class _CvLetterScreenState extends State<CvLetterScreen> {
  final aText = TextEditingController();
  LetterLength aLength = LetterLength.full;
  String? aVersionId;

  String get company => '${widget.offer['company'] ?? ''}';
  String get job => '${widget.offer['title'] ?? ''}';

  @override
  void initState() {
    super.initState();
    aText.text = generate();
  }

  @override
  void dispose() {
    aText.dispose();
    super.dispose();
  }

  /// Version choisie, ou la plus proche de l'offre.
  CvVersion get version {
    final vProfile = widget.state.cvProfile;
    final vVersions = widget.state.cvVersions;
    final vOffer = offerText(widget.offer);
    final vBest = bestVersionFor(
      vOffer,
      vVersions,
      (pVersion) => buildCvDocument(vProfile, pVersion).plainText,
    );

    return vVersions.firstWhere(
      (pItem) => pItem.id == aVersionId,
      orElse: () => vBest!.version,
    );
  }

  String generate() {
    if (widget.state.cvVersions.isEmpty) {
      return '';
    }

    return buildLetter(
      pProfile: widget.state.cvProfile,
      pVersion: version,
      pKit: widget.state.cvLetterKit,
      pLength: aLength,
      pOffer: offerText(widget.offer),
      pCompany: company,
      pJob: job,
    ).join('\n\n');
  }

  void regenerate() => setState(() => aText.text = generate());

  Future<void> copy() async {
    final vMessenger = ScaffoldMessenger.of(context);
    final vDone = context.texts.cvLettreCopiee;

    await Clipboard.setData(ClipboardData(text: aText.text));
    vMessenger.showSnackBar(SnackBar(content: Text(vDone)));
  }

  Future<void> exportPdf() async {
    final vContact = widget.state.cvProfile.contact;
    final vBytes = buildLetterPdf(
      pName: vContact.name,
      pContactLines: [
        for (final vLine in [vContact.email, vContact.phone, vContact.city])
          if (vLine.trim().isNotEmpty) vLine.trim(),
      ],
      pParagraphs: [
        for (final vPart in aText.text.split(RegExp(r'\n\s*\n')))
          if (vPart.trim().isNotEmpty) vPart.trim(),
      ],
    );

    final vFile = cvLetterFileName(vContact.name, company);

    await widget.send(Uint8List.fromList(vBytes), vFile, mimePdf);
    await widget.state.addCvSentFile(company, '${widget.offer['title'] ?? ''}', vFile);
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vFindings = reviewLetter(aText.text, aLength, pCompany: company);
    final vVersions = widget.state.cvVersions;

    if (widget.state.cvProfile.isEmpty || vVersions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(vTexts.cvLettre)),
        body: Padding(padding: const EdgeInsets.all(16), child: Text(vTexts.cvAucunParcours)),
      );
    }

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvLettreTitre(job))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: version.id,
            decoration: InputDecoration(labelText: vTexts.cvChoisirVersion),
            items: [
              for (final vVersion in vVersions)
                DropdownMenuItem(value: vVersion.id, child: Text(vVersion.label)),
            ],
            onChanged: (pId) {
              aVersionId = pId;
              regenerate();
            },
          ),
          const SizedBox(height: 12),
          Text(vTexts.cvLettreLongueur, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          SegmentedButton<LetterLength>(
            segments: [
              ButtonSegment(value: LetterLength.full, label: Text(vTexts.cvLettreComplete)),
              ButtonSegment(value: LetterLength.short, label: Text(vTexts.cvLettreCourte)),
              ButtonSegment(value: LetterLength.message, label: Text(vTexts.cvLettreMessage)),
            ],
            selected: {aLength},
            onSelectionChanged: (pValue) {
              aLength = pValue.first;
              regenerate();
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aText,
            minLines: 8,
            maxLines: 24,
            onChanged: (_) => setState(() {}),
          ),
          TextButton(onPressed: regenerate, child: Text(vTexts.cvLettreRegenerer)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(onPressed: copy, child: Text(vTexts.cvLettreCopier)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: exportPdf, child: Text(vTexts.cvLettrePdf)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(vTexts.cvLettreRelecture, style: Theme.of(context).textTheme.titleMedium),
          if (vFindings.isEmpty) Text(vTexts.cvLettreRien),
          for (final vFinding in vFindings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit_note),
              title: Text(findingLabel(vTexts, vFinding, aLength)),
            ),
        ],
      ),
    );

    return rScreen;
  }
}
