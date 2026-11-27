// Hors ligne de bout en bout : réponses sans réseau, redémarrage de l'appli, puis envoi au retour.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jobboard_revision/logic/review.dart';
import 'package:jobboard_revision/revision_state.dart';
import 'package:jobboard_revision/services/api_client.dart';
import 'package:jobboard_revision/services/revision_store.dart';

import 'support/sample_data.dart';

const settings = ServerSettings(address: 'http://pc/api/v1', token: 'secret');

void main() {
  test('sans réseau : réponses gardées, reprises au redémarrage, envoyées au retour', () async {
    final vStore = MemoryRevisionStore()
      ..settings = settings
      ..package = jsonEncode(buildPackageJson())
      ..progress = buildProgressJson();
    var vOnline = false;
    final vUploaded = <Map<String, dynamic>>[];
    final vClient = MockClient((pRequest) async {
      if (!vOnline) {
        throw const SocketException('Réseau coupé');
      }
      if (pRequest.url.path.endsWith('/answers')) {
        final vBody = jsonDecode(pRequest.body) as Map<String, dynamic>;
        final vAnswers = (vBody['answers'] as List).cast<Map<String, dynamic>>();
        vUploaded.addAll(vAnswers);

        return http.Response(
          jsonEncode({
            'received': vAnswers.length,
            'added': vAnswers.length,
            'duplicates': 0,
            'rejected': [],
            'progress': buildProgressJson(),
          }),
          200,
        );
      }
      if (pRequest.url.path.endsWith('/progress')) {
        return http.Response(jsonEncode(buildProgressJson()), 200);
      }

      return http.Response('', 304);
    });
    RevisionState newState() => RevisionState(
          vStore,
          pClientFactory: (pSettings) => ApiClient(pSettings, pClient: vClient),
        );

    // Le paquet livré est lisible et on répond sans aucun réseau
    final vFirst = newState();
    await vFirst.load();
    final vQuestion = vFirst.package!.questions.first;
    final vGrade = await vFirst.answer(vQuestion, 0);

    expect(vGrade.correct, isFalse);
    expect(vStore.pending, hasLength(1));
    await expectLater(vFirst.synchronize(), throwsA(anything));
    expect(vStore.pending, hasLength(1));

    // L'appli est relancée toujours sans réseau : réponse et calendrier sont toujours là
    final vSecond = newState();
    await vSecond.load();

    expect(vSecond.pending, hasLength(1));
    expect(vSecond.schedule[vQuestion.id]!.lastCorrect, isFalse);
    final vTomorrow = DateTime.now().add(const Duration(days: 1));

    expect(isMissedDue(vSecond.schedule[vQuestion.id]!, vTomorrow), isTrue);
    expect(vSecond.package!.questions, isNotEmpty);

    // Le réseau revient : la réponse part une fois, sans la correction locale
    vOnline = true;
    final vReport = await vSecond.synchronize();

    expect(vReport.sent, 1);
    expect(vUploaded, hasLength(1));
    expect(vUploaded.single.containsKey('correct'), isFalse);
    expect(vStore.pending, isEmpty);
  });
}
