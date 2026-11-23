// Postuler à une offre : la version du CV la plus proche est proposée, les mots de l'offre
// présents ou absents sont montrés, puis le CV part en PDF, Word ou texte.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_check.dart';
import '../logic/cv_document.dart';
import '../logic/cv_tailor.dart';
import '../revision_state.dart';
import '../services/file_sender.dart';
import '../theme.dart';
import '../widgets/cv_export_panel.dart';
import 'cv_letter_screen.dart';
import 'cv_templates_screen.dart';

/// Texte de l'offre lu pour les mots-clés : titre, description, compétences demandées.
String offerText(Map<String, dynamic> pOffer) => [
      pOffer['title'],
      pOffer['description'],
      ...List<String>.from(pOffer['covered'] as List? ?? const []),
      ...List<String>.from(pOffer['missing'] as List? ?? const []),
    ].where((pPart) => pPart != null && '$pPart'.isNotEmpty).join('\n');

class CvApplyScreen extends StatefulWidget {
  const CvApplyScreen({
    super.key,
    required this.state,
    required this.offer,
    this.send = shareFile,
  });

  final RevisionState state;
  final Map<String, dynamic> offer;
  final FileSender send;

  @override
  State<CvApplyScreen> createState() => _CvApplyScreenState();
}

class _CvApplyScreenState extends State<CvApplyScreen> {
  String? aVersionId;
  bool aTailored = true;

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vTheme = Theme.of(context);
    final vProfile = widget.state.cvProfile;
    final vVersions = widget.state.cvVersions;
    final vOffer = offerText(widget.offer);

    if (vProfile.isEmpty || vVersions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(vTexts.cvPostuler)),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(vTexts.cvAucunParcours),
        ),
      );
    }

    final vBest = bestVersionFor(
      vOffer,
      vVersions,
      (pVersion) => buildCvDocument(vProfile, pVersion).plainText,
    )!;
    final vChosen = vVersions.firstWhere(
      (pItem) => pItem.id == aVersionId,
      orElse: () => vBest.version,
    );
    final vFinal = aTailored ? tailorVersion(vProfile, vChosen, vOffer) : vChosen;
    final vReport = keywordReport(vOffer, buildCvDocument(vProfile, vFinal));
    final vCompany = '${widget.offer['company'] ?? ''}';

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvPostulerTitre('${widget.offer['title'] ?? ''}'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            vTexts.cvVersionProposee(
              vBest.version.label,
              (vBest.coverage * 100).round().toString(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vChosen.id,
            decoration: InputDecoration(labelText: vTexts.cvChoisirVersion),
            items: [
              for (final vVersion in vVersions)
                DropdownMenuItem(value: vVersion.id, child: Text(vVersion.label)),
            ],
            onChanged: (pId) => setState(() => aVersionId = pId),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vTexts.cvAdapter),
            subtitle: Text(vTexts.cvAdapterAide),
            value: aTailored,
            onChanged: (pOn) => setState(() => aTailored = pOn),
          ),
          const SizedBox(height: 8),
          Text(vTexts.cvMotsTrouves, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final vWord in vReport.found)
                Chip(
                  avatar: Icon(Icons.check, size: 16, color: successColorOf(context)),
                  label: Text(vWord),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(vTexts.cvMotsManquants, style: vTheme.textTheme.titleSmall),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final vWord in vReport.missing)
                Chip(
                  avatar: Icon(Icons.close, size: 16, color: vTheme.colorScheme.error),
                  label: Text(vWord),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    CvLetterScreen(state: widget.state, offer: widget.offer, send: widget.send),
              ),
            ),
            icon: const Icon(Icons.mail_outline),
            label: Text(vTexts.cvPostulerLettre),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CvTemplatesScreen(state: widget.state, offer: widget.offer),
              ),
            ),
            icon: const Icon(Icons.question_answer_outlined),
            label: Text(vTexts.cvReponses),
          ),
          const SizedBox(height: 20),
          CvExportPanel(
            profile: vProfile,
            version: vFinal,
            send: widget.send,
            company: vCompany,
            onExported: (pFormat) => widget.state.recordCvSent(
              pVersion: vChosen,
              pFormat: pFormat,
              pCompany: vCompany,
              pTitle: '${widget.offer['title'] ?? ''}',
              pUrl: '${widget.offer['url'] ?? ''}',
              pTailored: aTailored,
            ),
          ),
        ],
      ),
    );

    return rScreen;
  }
}
