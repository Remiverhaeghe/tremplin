// Supports publics : texte du profil GitHub et page CV du portfolio tirés du parcours, puis
// contrôle d'un texte déjà publié contre ce même parcours.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/texts.dart';
import '../logic/cv_supports.dart';
import '../revision_state.dart';

class CvSupportsScreen extends StatefulWidget {
  const CvSupportsScreen({super.key, required this.state});

  final RevisionState state;

  @override
  State<CvSupportsScreen> createState() => _CvSupportsScreenState();
}

class _CvSupportsScreenState extends State<CvSupportsScreen> {
  static const aBioMax = 160;

  final aPublished = TextEditingController();
  String? aVersionId;

  @override
  void dispose() {
    aPublished.dispose();
    super.dispose();
  }

  Future<void> copy(String pText) async {
    final vMessenger = ScaffoldMessenger.of(context);
    final vDone = context.texts.cvSupportsCopie;

    await Clipboard.setData(ClipboardData(text: pText));
    vMessenger.showSnackBar(SnackBar(content: Text(vDone)));
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vTheme = Theme.of(context);
    final vProfile = widget.state.cvProfile;
    final vVersions = widget.state.cvVersions;

    if (vProfile.isEmpty || vVersions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(vTexts.cvSupports)),
        body: Padding(padding: const EdgeInsets.all(16), child: Text(vTexts.cvAucunParcours)),
      );
    }

    final vVersion = vVersions.firstWhere(
      (pItem) => pItem.id == aVersionId,
      orElse: () => vVersions.first,
    );
    final vBio = githubBio(vProfile, vVersion, pMax: aBioMax);
    final vPage = portfolioPage(vProfile, vVersion);
    final vDrift = supportDrift(vProfile, vVersion, aPublished.text);

    String driftLabel(CvDrift pDrift) => switch (pDrift.kind) {
          CvDriftKind.headlineMissing => vTexts.cvDriftPoste(pDrift.text),
          CvDriftKind.projectMissing => vTexts.cvDriftProjet(pDrift.text),
          CvDriftKind.unknownFigure => vTexts.cvDriftChiffre(pDrift.text),
        };

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvSupports)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vTexts.cvSupportsAide),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: vVersion.id,
            decoration: InputDecoration(labelText: vTexts.cvSupportsVersion),
            items: [
              for (final vItem in vVersions)
                DropdownMenuItem(value: vItem.id, child: Text(vItem.label)),
            ],
            onChanged: (pId) => setState(() => aVersionId = pId),
          ),
          const SizedBox(height: 16),
          Text(vTexts.cvSupportsBio, style: vTheme.textTheme.titleSmall),
          SelectableText(vBio),
          Text(vTexts.cvSupportsBioLongueur('${vBio.length}', '$aBioMax'),
              style: vTheme.textTheme.bodySmall),
          TextButton.icon(
            onPressed: () => copy(vBio),
            icon: const Icon(Icons.copy),
            label: Text(vTexts.cvLettreCopier),
          ),
          const SizedBox(height: 8),
          Text(vTexts.cvSupportsPage, style: vTheme.textTheme.titleSmall),
          SelectableText(vPage),
          TextButton.icon(
            onPressed: () => copy(vPage),
            icon: const Icon(Icons.copy),
            label: Text(vTexts.cvLettreCopier),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: aPublished,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: vTexts.cvSupportsComparer,
              helperText: vTexts.cvSupportsComparerAide,
              helperMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (aPublished.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            if (vDrift.isEmpty) Text(vTexts.cvSupportsCoherent),
            for (final vItem in vDrift)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(driftLabel(vItem)),
              ),
          ],
        ],
      ),
    );

    return rScreen;
  }
}
