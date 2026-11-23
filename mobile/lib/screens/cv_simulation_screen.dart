// Simulation d'entretien : cinq questions tirées de l'offre et du parcours, une à la fois.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_agenda.dart';
import '../revision_state.dart';
import 'cv_apply_screen.dart';

class CvSimulationScreen extends StatefulWidget {
  const CvSimulationScreen({super.key, required this.state, required this.offer, this.seed});

  final RevisionState state;
  final Map<String, dynamic> offer;

  /// Graine du tirage, fixée par les tests.
  final int? seed;

  @override
  State<CvSimulationScreen> createState() => _CvSimulationScreenState();
}

class _CvSimulationScreenState extends State<CvSimulationScreen> {
  late int aSeed = widget.seed ?? DateTime.now().millisecondsSinceEpoch;
  int aIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vVersions = widget.state.cvVersions;

    if (widget.state.cvProfile.isEmpty || vVersions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(vTexts.cvSimulation)),
        body: Padding(padding: const EdgeInsets.all(16), child: Text(vTexts.cvAucunParcours)),
      );
    }

    final vQuestions = simulationQuestions(
      offerText(widget.offer),
      widget.state.cvProfile,
      vVersions.first,
      pSeed: aSeed,
      pCompany: '${widget.offer['company'] ?? ''}',
    );
    final vDone = aIndex >= vQuestions.length;

    return Scaffold(
      appBar: AppBar(title: Text(vTexts.cvSimulation)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vTexts.cvSimulationAide),
            const SizedBox(height: 16),
            if (vDone)
              Text(vTexts.cvSimulationFin)
            else ...[
              Text(vTexts.cvSimulationNumero('${aIndex + 1}', '${vQuestions.length}')),
              const SizedBox(height: 8),
              Text(vQuestions[aIndex], style: Theme.of(context).textTheme.titleLarge),
            ],
            const SizedBox(height: 16),
            if (vDone)
              OutlinedButton(
                onPressed: () => setState(() {
                  aSeed += 1;
                  aIndex = 0;
                }),
                child: Text(vTexts.cvSimulationRecommencer),
              )
            else
              FilledButton(
                onPressed: () => setState(() => aIndex += 1),
                child: Text(vTexts.cvSimulationSuivante),
              ),
          ],
        ),
      ),
    );
  }
}
