// Tableau de la semaine, carnet de contacts et formations suivies : tout reste sur le téléphone.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../l10n/texts.dart';
import '../logic/cv_agenda.dart';
import '../revision_state.dart';

class CvAgendaScreen extends StatelessWidget {
  const CvAgendaScreen({super.key, required this.state, this.now});

  final RevisionState state;

  /// Date du jour, fixée par les tests.
  final DateTime? now;

  Future<void> addContact(BuildContext pContext) async {
    final vTexts = pContext.texts;
    final vValues = await showDialog<List<String>>(
      context: pContext,
      builder: (_) => _FieldsDialog(
        title: vTexts.cvContactAjouter,
        labels: [
          vTexts.cvContactNom,
          vTexts.cvContactEntreprise,
          vTexts.cvContactNote,
          vTexts.cvContactReprise,
        ],
      ),
    );

    if (vValues != null && vValues.first.trim().isNotEmpty) {
      await state.saveCvContacts([
        ...state.cvContacts,
        CvContact(
          id: const Uuid().v4(),
          name: vValues[0].trim(),
          company: vValues[1].trim(),
          note: vValues[2].trim(),
          nextAt: vValues[3].trim(),
        ),
      ]);
    }
  }

  Future<void> addTraining(BuildContext pContext) async {
    final vTexts = pContext.texts;
    final vValues = await showDialog<List<String>>(
      context: pContext,
      builder: (_) => _FieldsDialog(
        title: vTexts.cvFormationAjouter,
        labels: [vTexts.cvFormationTitre, vTexts.cvFormationEcheance],
      ),
    );

    if (vValues != null && vValues.first.trim().isNotEmpty) {
      await state.saveCvTrainings([
        ...state.cvTrainings,
        CvTraining(id: const Uuid().v4(), title: vValues[0].trim(), dueAt: vValues[1].trim()),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;
    final vTheme = Theme.of(context);

    final rScreen = ListenableBuilder(
      listenable: state,
      builder: (pContext, _) {
        final vToday = now ?? DateTime.now();
        final vPlan = weekPlan(
          pSent: state.cvSent,
          pContacts: state.cvContacts,
          pTrainings: state.cvTrainings,
          pNow: vToday,
        );
        final vTrainingLabels = {
          'todo': vTexts.cvFormationTodo,
          'doing': vTexts.cvFormationDoing,
          'done': vTexts.cvFormationDone,
        };

        String line(CvWeekItem pItem) => switch (pItem.kind) {
              'followup' => vTexts.cvAgendaRelance(pItem.label),
              'contact' => vTexts.cvAgendaContact(pItem.label),
              _ => vTexts.cvAgendaFormation(pItem.label),
            };

        return Scaffold(
          appBar: AppBar(title: Text(vTexts.cvAgenda)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(vTexts.cvAgendaSemaine, style: vTheme.textTheme.titleMedium),
              if (vPlan.isEmpty) Text(vTexts.cvAgendaSemaineVide),
              for (final vItem in vPlan)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line(vItem)),
                  subtitle: Text(vItem.day.toIso8601String().split('T').first),
                ),
              const SizedBox(height: 16),
              Text(vTexts.cvContacts, style: vTheme.textTheme.titleMedium),
              if (state.cvContacts.isEmpty) Text(vTexts.cvContactsVide),
              for (final vContact in state.cvContacts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text([vContact.name, vContact.company].where((p) => p.isNotEmpty).join(' · ')),
                  subtitle: Text([vContact.note, vContact.nextAt].where((p) => p.isNotEmpty).join(' · ')),
                  trailing: TextButton(
                    onPressed: () => state.saveCvContacts([
                      for (final vOther in state.cvContacts)
                        if (vOther.id == vContact.id)
                          CvContact(
                            id: vOther.id,
                            name: vOther.name,
                            company: vOther.company,
                            role: vOther.role,
                            note: vOther.note,
                            lastAt: vToday.toIso8601String().split('T').first,
                          )
                        else
                          vOther,
                    ]),
                    child: Text(vTexts.cvContactFait),
                  ),
                ),
              OutlinedButton(
                onPressed: () => addContact(pContext),
                child: Text(vTexts.cvContactAjouter),
              ),
              const SizedBox(height: 16),
              Text(vTexts.cvFormations, style: vTheme.textTheme.titleMedium),
              if (state.cvTrainings.isEmpty) Text(vTexts.cvFormationsVide),
              for (final vTraining in state.cvTrainings)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(vTraining.title),
                  subtitle: Text(vTraining.dueAt),
                  trailing: DropdownButton<String>(
                    value: vTraining.state,
                    items: [
                      for (final vEntry in vTrainingLabels.entries)
                        DropdownMenuItem(value: vEntry.key, child: Text(vEntry.value)),
                    ],
                    onChanged: (pValue) => state.saveCvTrainings([
                      for (final vOther in state.cvTrainings)
                        if (vOther.id == vTraining.id)
                          vOther.copyWith(state: pValue ?? vOther.state)
                        else
                          vOther,
                    ]),
                  ),
                ),
              OutlinedButton(
                onPressed: () => addTraining(pContext),
                child: Text(vTexts.cvFormationAjouter),
              ),
            ],
          ),
        );
      },
    );

    return rScreen;
  }
}

/// Dialogue à champs texte libres ; renvoie les valeurs dans l'ordre des libellés.
class _FieldsDialog extends StatefulWidget {
  const _FieldsDialog({required this.title, required this.labels});

  final String title;
  final List<String> labels;

  @override
  State<_FieldsDialog> createState() => _FieldsDialogState();
}

class _FieldsDialogState extends State<_FieldsDialog> {
  late final List<TextEditingController> aControllers = [
    for (final _ in widget.labels) TextEditingController(),
  ];

  @override
  void dispose() {
    for (final vController in aControllers) {
      vController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var vIndex = 0; vIndex < widget.labels.length; vIndex++)
              TextField(
                controller: aControllers[vIndex],
                decoration: InputDecoration(labelText: widget.labels[vIndex]),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(vTexts.commonAnnuler)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop([
            for (final vController in aControllers) vController.text,
          ]),
          child: Text(vTexts.cvEnregistrer),
        ),
      ],
    );
  }
}
