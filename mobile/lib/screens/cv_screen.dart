// CV de Rémi : importer le parcours, choisir ou créer une version, voir les CV préparés.
// Le parcours reste sur le téléphone.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/texts.dart';
import '../logic/cv_truth.dart';
import '../logic/cv_version.dart';
import '../revision_state.dart';
import '../services/file_sender.dart';
import 'cv_add_screen.dart';
import 'cv_batch_screen.dart';
import 'cv_templates_screen.dart';
import 'cv_version_screen.dart';

String truthLabel(AppLocalizations pTexts, CvTruthIssue pIssue) => switch (pIssue.kind) {
      CvTruthKind.projectWithoutUrl => pTexts.cvVeriteSansLien(pIssue.text),
      CvTruthKind.projectNotOnGithub => pTexts.cvVeriteNonGithub(pIssue.text),
      CvTruthKind.figure => pTexts.cvVeriteChiffre('« ${pIssue.text} »'),
    };

class CvScreen extends StatelessWidget {
  const CvScreen({super.key, required this.state, this.send = shareFile});

  final RevisionState state;
  final FileSender send;

  Future<void> importProfile(BuildContext pContext) async {
    final vMessenger = ScaffoldMessenger.of(pContext);
    final vOk = pContext.texts.cvImporterOk;

    final vImported = await showDialog<bool>(
      context: pContext,
      builder: (_) => _ImportDialog(state: state),
    );

    if (vImported == true) {
      vMessenger.showSnackBar(SnackBar(content: Text(vOk)));
    }
  }

  Future<void> newVersion(BuildContext pContext) async {
    final vTexts = pContext.texts;
    final vFirst = state.cvVersions.isEmpty ? null : state.cvVersions.first;
    final vVersion = (vFirst ?? const CvVersion(id: '', label: '')).copyWith(
      label: vTexts.cvVersionNouvelle,
    );
    final vCopy = CvVersion.fromJson({...vVersion.toJson(), 'id': const Uuid().v4()});

    await state.saveCvVersion(vCopy);

    if (pContext.mounted) {
      await Navigator.of(pContext).push(
        MaterialPageRoute<void>(
          builder: (_) => CvVersionScreen(state: state, versionId: vCopy.id, send: send),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    final rScreen = ListenableBuilder(
      listenable: state,
      builder: (pContext, _) {
        final vProfile = state.cvProfile;
        final vSent = state.cvSent;
        final vIssues = checkTruth(vProfile, pConfirmed: state.cvConfirmedClaims);

        return Scaffold(
          appBar: AppBar(title: Text(vTexts.cvTitre)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (vProfile.isEmpty) ...[
                Text(vTexts.cvAucunParcours),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => importProfile(pContext),
                  icon: const Icon(Icons.upload_file),
                  label: Text(vTexts.cvImporterTitre),
                ),
              ] else ...[
                Text(vProfile.contact.name, style: Theme.of(pContext).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(vTexts.cvVersions, style: Theme.of(pContext).textTheme.titleMedium),
                for (final vVersion in state.cvVersions)
                  Card(
                    child: ListTile(
                      title: Text(vVersion.label),
                      subtitle: vVersion.headline.isEmpty ? null : Text(vVersion.headline),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(pContext).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CvVersionScreen(
                            state: state,
                            versionId: vVersion.id,
                            send: send,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => newVersion(pContext),
                  icon: const Icon(Icons.add),
                  label: Text(vTexts.cvVersionNouvelle),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(pContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CvBatchScreen(state: state, send: send),
                    ),
                  ),
                  icon: const Icon(Icons.checklist),
                  label: Text(vTexts.cvPlusieurs),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(pContext).push(
                    MaterialPageRoute<void>(builder: (_) => CvAddScreen(state: state)),
                  ),
                  icon: const Icon(Icons.library_add_outlined),
                  label: Text(vTexts.cvAjouter),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(pContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CvTemplatesScreen(state: state),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note),
                  label: Text(vTexts.cvModeles),
                ),
                TextButton(
                  onPressed: () => importProfile(pContext),
                  child: Text(vTexts.cvImporterTitre),
                ),
                const SizedBox(height: 16),
                Text(vTexts.cvVerite, style: Theme.of(pContext).textTheme.titleMedium),
                if (vIssues.isEmpty) Text(vTexts.cvVeriteRien),
                for (final vIssue in vIssues)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(truthLabel(vTexts, vIssue)),
                    trailing: vIssue.kind == CvTruthKind.figure
                        ? TextButton(
                            onPressed: () => state.confirmCvClaim(vIssue.text),
                            child: Text(vTexts.cvVeriteConfirmer),
                          )
                        : null,
                  ),
                const SizedBox(height: 16),
                Text(vTexts.cvEnvoyes, style: Theme.of(pContext).textTheme.titleMedium),
                if (vSent.isEmpty) Text(vTexts.cvEnvoyesVide),
                for (final vItem in vSent.take(10))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      [vItem['company'], vItem['title']]
                          .where((pPart) => '${pPart ?? ''}'.isNotEmpty)
                          .join(' · '),
                    ),
                    subtitle: Text(
                      vTexts.cvEnvoyeSur('${vItem['version']}', '${vItem['at']}'.split('T').first),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );

    return rScreen;
  }
}

/// Fenêtre de collage du parcours : elle garde elle-même son champ, pour qu'il ne soit pas
/// libéré pendant l'animation de fermeture.
class _ImportDialog extends StatefulWidget {
  const _ImportDialog({required this.state});

  final RevisionState state;

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final aController = TextEditingController();
  String? aError;

  @override
  void dispose() {
    aController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final vInvalid = context.texts.cvImporterInvalide;
    final vNavigator = Navigator.of(context);
    final vOk = await widget.state.importCvProfile(aController.text);

    if (vOk) {
      vNavigator.pop(true);
    } else if (mounted) {
      setState(() => aError = vInvalid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    final rDialog = AlertDialog(
      title: Text(vTexts.cvImporterTitre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vTexts.cvImporterAide),
          const SizedBox(height: 8),
          TextField(
            controller: aController,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(errorText: aError),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(vTexts.commonAnnuler),
        ),
        FilledButton(onPressed: submit, child: Text(vTexts.cvImporterBouton)),
      ],
    );

    return rDialog;
  }
}
