// Modèles de lettre et réponses de formulaire : Rémi les écrit une fois, l'appli remplit
// l'entreprise et le poste à chaque offre et copie la réponse.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/texts.dart';
import '../logic/cv_answers.dart';
import '../logic/cv_letter.dart';
import '../revision_state.dart';

const _fillWords = '{poste} {entreprise} {nom} {telephone} {disponibilite} {preavis} '
    '{accroche} {projet} {projet_detail}';

class CvTemplatesScreen extends StatefulWidget {
  const CvTemplatesScreen({super.key, required this.state, this.offer});

  final RevisionState state;

  /// Offre visée : les réponses copiées ont alors son entreprise et son poste.
  final Map<String, dynamic>? offer;

  @override
  State<CvTemplatesScreen> createState() => _CvTemplatesScreenState();
}

class _CvTemplatesScreenState extends State<CvTemplatesScreen> {
  late final Map<String, TextEditingController> aKit;
  late final List<CvAnswer> aAnswers;
  late final Map<String, TextEditingController> aAnswerText;

  String get company => '${widget.offer?['company'] ?? ''}';
  String get job => '${widget.offer?['title'] ?? ''}';

  @override
  void initState() {
    super.initState();
    final vKit = widget.state.cvLetterKit;
    aKit = {
      'hook': TextEditingController(text: vKit.hook),
      'proof': TextEditingController(text: vKit.proof),
      'closing': TextEditingController(text: vKit.closing),
      'message': TextEditingController(text: vKit.message),
    };
    aAnswers = widget.state.cvAnswers;
    aAnswerText = {
      for (final vAnswer in aAnswers) vAnswer.id: TextEditingController(text: vAnswer.text),
    };
  }

  @override
  void dispose() {
    for (final vController in [...aKit.values, ...aAnswerText.values]) {
      vController.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    final vMessenger = ScaffoldMessenger.of(context);
    final vDone = context.texts.cvModelesEnregistres;

    await widget.state.saveCvLetterKit(
      LetterKit(
        hook: aKit['hook']!.text,
        proof: aKit['proof']!.text,
        closing: aKit['closing']!.text,
        message: aKit['message']!.text,
      ),
    );
    await widget.state.saveCvAnswers([
      for (final vAnswer in aAnswers) vAnswer.copyWith(text: aAnswerText[vAnswer.id]!.text),
    ]);
    vMessenger.showSnackBar(SnackBar(content: Text(vDone)));
  }

  Future<void> copyAnswer(CvAnswer pAnswer) async {
    final vMessenger = ScaffoldMessenger.of(context);
    final vDone = context.texts.cvReponseCopiee;
    final vFilled = answerFor(
      pAnswer.copyWith(text: aAnswerText[pAnswer.id]!.text),
      pCompany: company,
      pJob: job,
    );

    await Clipboard.setData(ClipboardData(text: vFilled));
    vMessenger.showSnackBar(SnackBar(content: Text(vDone)));
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    Widget field(String pKey, String pLabel) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: aKit[pKey],
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(labelText: pLabel),
          ),
        );

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvModeles)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vTexts.cvModelesAide(_fillWords)),
          const SizedBox(height: 12),
          field('hook', vTexts.cvModelesDebut),
          field('proof', vTexts.cvModelesPreuve),
          field('closing', vTexts.cvModelesFin),
          field('message', vTexts.cvModelesMessage),
          Text(vTexts.cvReponses, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final vAnswer in aAnswers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: aAnswerText[vAnswer.id],
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: questionFor(vAnswer, pCompany: company, pJob: job),
                  suffixIcon: IconButton(
                    tooltip: vTexts.cvLettreCopier,
                    onPressed: () => copyAnswer(vAnswer),
                    icon: const Icon(Icons.copy),
                  ),
                ),
              ),
            ),
          FilledButton(onPressed: save, child: Text(vTexts.offerDetailGarder)),
        ],
      ),
    );

    return rScreen;
  }
}
