// Préparation d'entretien liée à une offre : questions probables et ligne du parcours à reprendre.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_prep.dart';
import '../revision_state.dart';
import 'cv_apply_screen.dart';

class CvPrepScreen extends StatelessWidget {
  const CvPrepScreen({super.key, required this.state, required this.offer, this.versionId});

  final RevisionState state;
  final Map<String, dynamic> offer;

  /// Version du CV envoyée ; la première si elle n'est pas connue.
  final String? versionId;

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vVersions = state.cvVersions;

    if (state.cvProfile.isEmpty || vVersions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(vTexts.cvPrep)),
        body: Padding(padding: const EdgeInsets.all(16), child: Text(vTexts.cvAucunParcours)),
      );
    }

    final vVersion = vVersions.firstWhere(
      (pItem) => pItem.id == versionId,
      orElse: () => vVersions.first,
    );
    final vQuestions = prepQuestions(
      offerText(offer),
      state.cvProfile,
      vVersion,
      pCompany: '${offer['company'] ?? ''}',
    );

    String question(CvPrepQuestion pItem) => switch (pItem.kind) {
          'why-company' => vTexts.cvPrepPourquoi(pItem.subject),
          'pivot' => vTexts.cvPrepVirage,
          'project' => vTexts.cvPrepProjet(pItem.subject),
          'used' => vTexts.cvPrepUtilise(pItem.subject),
          _ => vTexts.cvPrepApprendre(pItem.subject),
        };

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvPrep)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vTexts.cvPrepAide),
          const SizedBox(height: 8),
          for (final vItem in vQuestions)
            Card(
              child: ListTile(
                title: Text(question(vItem)),
                subtitle: Text(
                  vItem.hint.isEmpty
                      ? (vItem.kind == 'learn' ? vTexts.cvPrepIndiceVrai : '')
                      : vTexts.cvPrepIndice(vItem.hint),
                ),
              ),
            ),
        ],
      ),
    );

    return rScreen;
  }
}
