// Suivi des candidatures : statistiques par version, relances à faire, réponses reçues, et le CV
// tel qu'il est parti.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/texts.dart';
import '../logic/cv_followup.dart';
import '../logic/cv_stats.dart';
import '../revision_state.dart';

class CvTrackScreen extends StatelessWidget {
  const CvTrackScreen({super.key, required this.state, this.now});

  final RevisionState state;

  /// Date du jour, fixée par les tests.
  final DateTime? now;

  Future<void> copyFollowUp(BuildContext pContext, Map<String, dynamic> pItem) async {
    final vMessenger = ScaffoldMessenger.of(pContext);
    final vDone = pContext.texts.cvSuiviRelanceCopiee;

    await Clipboard.setData(
      ClipboardData(
        text: followUpMessage(
          pName: state.cvProfile.contact.name,
          pCompany: '${pItem['company']}',
          pTitle: '${pItem['title'] ?? ''}',
        ),
      ),
    );
    vMessenger.showSnackBar(SnackBar(content: Text(vDone)));
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vTheme = Theme.of(context);

    final rScreen = ListenableBuilder(
      listenable: state,
      builder: (pContext, _) {
        final vSent = state.cvSent;
        final vStats = cvStats(vSent);
        final vDue = followUpsDue(vSent, now ?? DateTime.now());
        final vOutcomes = {
          '': vTexts.cvSuiviPasDeReponse,
          'reponse': vTexts.cvSuiviReponse,
          'entretien': vTexts.cvSuiviEntretien,
          'refus': vTexts.cvSuiviRefus,
        };

        return Scaffold(
          appBar: AppBar(title: Text(vTexts.cvSuivi)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(vTexts.cvSuiviStats, style: vTheme.textTheme.titleMedium),
              Text(
                vTexts.cvSuiviTotal(
                  '${vStats.total}',
                  '${vStats.answered}',
                  '${vStats.interviews}',
                ),
              ),
              for (final vItem in vStats.byVersion)
                Text(
                  vTexts.cvSuiviParVersion(
                    vItem.version,
                    '${vItem.sent}',
                    '${vItem.answered}',
                  ),
                ),
              const SizedBox(height: 16),
              Text(vTexts.cvSuiviRelances, style: vTheme.textTheme.titleMedium),
              Text(vTexts.cvSuiviRelancesAide),
              if (vDue.isEmpty) Text(vTexts.cvSuiviRelancesVide),
              for (final vItem in vDue)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${vItem['company']} · ${vItem['title']}'),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => copyFollowUp(pContext, vItem),
                        child: Text(vTexts.cvSuiviCopierRelance),
                      ),
                      TextButton(
                        onPressed: () => state.updateCvSent(
                          '${vItem['id']}',
                          {'followed_up': (now ?? DateTime.now()).toIso8601String()},
                        ),
                        child: Text(vTexts.cvSuiviRelanceFaite),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(vTexts.cvSuiviHistorique, style: vTheme.textTheme.titleMedium),
              if (vSent.isEmpty) Text(vTexts.cvEnvoyesVide),
              for (final vItem in vSent)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    [vItem['company'], vItem['title']]
                        .where((pPart) => '${pPart ?? ''}'.isNotEmpty)
                        .join(' · '),
                  ),
                  subtitle: Text(
                    vTexts.cvEnvoyeSur('${vItem['version']}', '${vItem['at']}'.split('T').first),
                  ),
                  children: [
                    DropdownButton<String>(
                      value: vOutcomes.containsKey('${vItem['outcome'] ?? ''}')
                          ? '${vItem['outcome'] ?? ''}'
                          : '',
                      items: [
                        for (final vEntry in vOutcomes.entries)
                          DropdownMenuItem(value: vEntry.key, child: Text(vEntry.value)),
                      ],
                      onChanged: (pValue) =>
                          state.updateCvSent('${vItem['id']}', {'outcome': pValue ?? ''}),
                    ),
                    if ((vItem['files'] as List? ?? const []).isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          vTexts.cvSuiviFichiers((vItem['files'] as List).join(', ')),
                        ),
                      ),
                    if ('${vItem['snapshot'] ?? ''}'.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(vTexts.cvSuiviTexteFige, style: vTheme.textTheme.titleSmall),
                      ),
                      SelectableText('${vItem['snapshot']}'),
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );

    return rScreen;
  }
}
