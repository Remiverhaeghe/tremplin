// Une version du CV : poste visé, accroche, sections, aperçu et export.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_document.dart';
import '../logic/cv_version.dart';
import '../revision_state.dart';
import '../services/file_sender.dart';
import '../widgets/cv_export_panel.dart';

class CvVersionScreen extends StatefulWidget {
  const CvVersionScreen({
    super.key,
    required this.state,
    required this.versionId,
    this.send = shareFile,
  });

  final RevisionState state;
  final String versionId;
  final FileSender send;

  @override
  State<CvVersionScreen> createState() => _CvVersionScreenState();
}

class _CvVersionScreenState extends State<CvVersionScreen> {
  late CvVersion aVersion;
  late final TextEditingController aLabel;
  late final TextEditingController aHeadline;
  late final TextEditingController aSummary;
  late final TextEditingController aPivot;
  late final TextEditingController aYears;

  @override
  void initState() {
    super.initState();
    aVersion = widget.state.cvVersions.firstWhere((pItem) => pItem.id == widget.versionId);
    aLabel = TextEditingController(text: aVersion.label);
    aHeadline = TextEditingController(text: aVersion.headline);
    aSummary = TextEditingController(text: aVersion.summary);
    aPivot = TextEditingController(text: aVersion.pivot);
    aYears = TextEditingController(text: aVersion.years > 0 ? '${aVersion.years}' : '');
  }

  @override
  void dispose() {
    aLabel.dispose();
    aHeadline.dispose();
    aSummary.dispose();
    aPivot.dispose();
    aYears.dispose();
    super.dispose();
  }

  /// La version telle qu'elle est à l'écran, avant d'être enregistrée.
  CvVersion get edited => aVersion.copyWith(
        label: aLabel.text.trim().isEmpty ? aVersion.label : aLabel.text.trim(),
        headline: aHeadline.text.trim(),
        summary: aSummary.text.trim(),
        pivot: aPivot.text.trim(),
        years: int.tryParse(aYears.text.trim()) ?? 0,
      );

  Future<void> save() async {
    final vMessenger = ScaffoldMessenger.of(context);
    final vSaved = context.texts.cvVersionEnregistree;

    await widget.state.saveCvVersion(edited);
    vMessenger.showSnackBar(SnackBar(content: Text(vSaved)));
  }

  Future<void> remove() async {
    final vNavigator = Navigator.of(context);

    await widget.state.removeCvVersion(widget.versionId);
    vNavigator.pop();
  }

  void toggle(CvSection pSection, bool pOn) {
    final vOn = {...aVersion.sections};
    if (pOn) {
      vOn.add(pSection);
    } else {
      vOn.remove(pSection);
    }
    setState(() {
      aVersion = aVersion.copyWith(
        sections: [
          for (final vItem in CvSection.values)
            if (vOn.contains(vItem)) vItem,
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vProfile = widget.state.cvProfile;
    final vCurrent = edited;
    final vPreview = buildCvDocument(vProfile, vCurrent).plainText;

    final rScreen = Scaffold(
      appBar: AppBar(
        title: Text(vCurrent.label),
        actions: [
          IconButton(
            tooltip: vTexts.cvVersionSupprimer,
            onPressed: remove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: aLabel,
            decoration: InputDecoration(labelText: vTexts.cvVersionNom),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aHeadline,
            decoration: InputDecoration(labelText: vTexts.cvVersionPoste),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aSummary,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: vTexts.cvVersionAccroche,
              helperText: vTexts.cvVersionAccrocheAide,
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aPivot,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: vTexts.cvVersionVirage,
              helperText: vTexts.cvVersionVirageAide,
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aYears,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: vTexts.cvVersionAnnees,
              helperText: vTexts.cvVersionAnneesAide,
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Text(vTexts.cvVersionSections, style: Theme.of(context).textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final vSection in CvSection.values)
                FilterChip(
                  label: Text(cvSectionLabel(vTexts, vSection)),
                  selected: aVersion.sections.contains(vSection),
                  onSelected: (pOn) => toggle(vSection, pOn),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vTexts.cvVersionAnglais),
            subtitle: Text(vTexts.cvVersionAnglaisAide),
            value: aVersion.language == 'en',
            onChanged: (pOn) =>
                setState(() => aVersion = aVersion.copyWith(language: pOn ? 'en' : 'fr')),
          ),
          Text(vTexts.cvVersionCouleur, style: Theme.of(context).textTheme.titleSmall),
          Wrap(
            spacing: 8,
            children: [
              for (final vColor in cvAccents)
                ChoiceChip(
                  label: const SizedBox(width: 14, height: 14),
                  avatar: CircleAvatar(backgroundColor: Color(0xFF000000 | vColor)),
                  selected: (aVersion.accent == 0 ? cvAccents.first : aVersion.accent) == vColor,
                  onSelected: (_) => setState(() => aVersion = aVersion.copyWith(accent: vColor)),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vTexts.cvVersionPhoto),
            subtitle: Text(vTexts.cvVersionPhotoAide),
            value: aVersion.withPhoto,
            onChanged: vProfile.photo.isEmpty
                ? null
                : (pOn) => setState(() => aVersion = aVersion.copyWith(withPhoto: pOn)),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: save, child: Text(vTexts.offerDetailGarder)),
          const SizedBox(height: 20),
          CvExportPanel(profile: vProfile, version: vCurrent, send: widget.send),
          const SizedBox(height: 20),
          Text(vTexts.cvApercu, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SelectableText(vPreview),
        ],
      ),
    );

    return rScreen;
  }
}
