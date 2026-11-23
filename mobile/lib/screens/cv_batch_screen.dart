// Plusieurs offres d'un coup : chaque offre reçoit la version du CV la plus proche et les mots
// qui lui manquent ; un appui ouvre l'écran pour postuler à celle-là.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_batch.dart';
import '../logic/cv_document.dart';
import '../logic/cv_gap.dart';
import '../revision_state.dart';
import '../services/file_sender.dart';
import 'cv_apply_screen.dart';

class CvBatchScreen extends StatefulWidget {
  const CvBatchScreen({super.key, required this.state, this.send = shareFile});

  final RevisionState state;
  final FileSender send;

  @override
  State<CvBatchScreen> createState() => _CvBatchScreenState();
}

class _CvBatchScreenState extends State<CvBatchScreen> {
  final aInput = TextEditingController();
  List<Map<String, dynamic>> aOffers = [];
  List<CvOfferMatch> aMatches = [];
  List<CvGapItem> aGap = [];
  bool aAnalysed = false;

  @override
  void dispose() {
    aInput.dispose();
    super.dispose();
  }

  void analyse(List<Map<String, dynamic>> pOffers) {
    final vProfile = widget.state.cvProfile;
    final vMatches = matchOffers(
      [for (final vOffer in pOffers) offerText(vOffer)],
      widget.state.cvVersions,
      (pVersion) => buildCvDocument(vProfile, pVersion).plainText,
    );

    final vCvText = [
      for (final vVersion in widget.state.cvVersions) buildCvDocument(vProfile, vVersion).plainText,
    ].join('\n');

    setState(() {
      aGap = skillGap([for (final vOffer in pOffers) offerText(vOffer)], vCvText);
      aOffers = pOffers;
      aMatches = vMatches;
      aAnalysed = true;
    });
  }

  void analysePasted() => analyse([
        for (final vText in splitOffers(aInput.text))
          {'title': vText.split('\n').first.trim(), 'description': vText},
      ]);

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvPlusieurs)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vTexts.cvPlusieursAide),
          const SizedBox(height: 8),
          TextField(controller: aInput, minLines: 4, maxLines: 10),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: analysePasted,
                  child: Text(vTexts.cvPlusieursAnalyser),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => analyse(widget.state.offers.take(30).toList()),
                  child: Text(vTexts.cvPlusieursMesOffres),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (aAnalysed && aMatches.isEmpty) Text(vTexts.cvPlusieursAucune),
          for (final vMatch in aMatches)
            Card(
              child: ListTile(
                title: Text(vMatch.title),
                subtitle: Text(
                  vTexts.cvPlusieursResume(
                    vMatch.version.label,
                    (vMatch.coverage * 100).round().toString(),
                    vMatch.missing.take(5).join(', '),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CvApplyScreen(
                      state: widget.state,
                      offer: aOffers[vMatch.index],
                      send: widget.send,
                    ),
                  ),
                ),
              ),
            ),
          if (aAnalysed && aMatches.length > 1) ...[
            const SizedBox(height: 16),
            Text(vTexts.cvEcart, style: Theme.of(context).textTheme.titleSmall),
            Text(vTexts.cvEcartAide),
            if (aGap.isEmpty) Text(vTexts.cvEcartVide),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final vItem in aGap)
                  Chip(
                    label: Text(vTexts.cvEcartMot(vItem.word, '${vItem.offers}')),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    return rScreen;
  }
}
