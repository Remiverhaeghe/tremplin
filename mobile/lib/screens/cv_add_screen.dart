// Ajouter au parcours un projet ou une habilitation, sans repasser par le fichier JSON.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_profile.dart';
import '../logic/cv_project_sheets.dart';
import '../revision_state.dart';

class CvAddScreen extends StatefulWidget {
  const CvAddScreen({super.key, required this.state});

  final RevisionState state;

  @override
  State<CvAddScreen> createState() => _CvAddScreenState();
}

class _CvAddScreenState extends State<CvAddScreen> {
  final aName = TextEditingController();
  final aLink = TextEditingController();
  final aLines = TextEditingController();
  final aDetail = TextEditingController();
  final aDates = TextEditingController();
  bool aProject = true;
  bool aToVersions = true;
  bool aMissingName = false;

  /// Préremplit le formulaire avec une fiche : Rémi relit et corrige avant de garder.
  void useSheet(CvProjectSheet pSheet) {
    setState(() {
      aName.text = pSheet.name;
      aLink.text = pSheet.url;
      aLines.text = pSheet.lines.join('\n');
      aMissingName = false;
    });
  }

  @override
  void dispose() {
    for (final vController in [aName, aLink, aLines, aDetail, aDates]) {
      vController.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final vNavigator = Navigator.of(context);
    final vMessenger = ScaffoldMessenger.of(context);
    final vDone = context.texts.cvAjouterOk;
    final vName = aName.text.trim();

    if (vName.isEmpty) {
      setState(() => aMissingName = true);

      return;
    }
    final vId = widget.state.newCvId();

    if (aProject) {
      await widget.state.addCvProject(
        CvProject(
          id: vId,
          name: vName,
          url: aLink.text.trim(),
          lines: [
            for (final vLine in aLines.text.split('\n'))
              if (vLine.trim().isNotEmpty) vLine.trim(),
          ],
        ),
        pToProjectVersions: aToVersions,
      );
    } else {
      await widget.state.addCvCertification(
        CvCertification(
          id: vId,
          title: vName,
          detail: aDetail.text.trim(),
          dates: aDates.text.trim(),
        ),
      );
    }
    vMessenger.showSnackBar(SnackBar(content: Text(vDone)));
    await vNavigator.maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvAjouter)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(vTexts.cvAjouterProjet)),
              ButtonSegment(value: false, label: Text(vTexts.cvAjouterHabilitation)),
            ],
            selected: {aProject},
            onSelectionChanged: (pValue) => setState(() => aProject = pValue.first),
          ),
          if (aProject)
            Wrap(
              spacing: 8,
              children: [
                for (final vSheet in cvProjectSheets)
                  ActionChip(
                    label: Text(vTexts.cvAjouterReprendre(vSheet.name)),
                    onPressed: () => useSheet(vSheet),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: aName,
            decoration: InputDecoration(
              labelText: vTexts.cvAjouterNom,
              errorText: aMissingName ? vTexts.cvAjouterVide : null,
            ),
          ),
          const SizedBox(height: 12),
          if (aProject) ...[
            TextField(
              controller: aLink,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: vTexts.cvAjouterLien),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aLines,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: vTexts.cvAjouterLignes),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(vTexts.cvAjouterDansVersions),
              value: aToVersions,
              onChanged: (pOn) => setState(() => aToVersions = pOn ?? true),
            ),
          ] else ...[
            TextField(
              controller: aDetail,
              decoration: InputDecoration(labelText: vTexts.cvAjouterDetail),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: aDates,
              decoration: InputDecoration(labelText: vTexts.cvAjouterDates),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: save, child: Text(vTexts.offerDetailGarder)),
        ],
      ),
    );

    return rScreen;
  }
}
