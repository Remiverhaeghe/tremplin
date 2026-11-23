// Rappels d'entretien : la veille au soir et une heure avant.

import 'package:flutter_test/flutter_test.dart';
import 'package:jobboard_revision/logic/interview_alerts.dart';

void main() {
  test('Un entretien donne deux rappels à venir, dans l\'ordre', () {
    final vAlerts = buildInterviewAlerts([
      {'title': 'Dev Java', 'company': 'Kiabi', 'interview_at': '2026-11-05T14:00'},
      {'title': 'Passé', 'company': null, 'interview_at': '2026-10-01T10:00'},
      {'title': 'Sans date'},
    ], DateTime(2026, 10, 24, 9));

    expect([
      for (final vAlert in vAlerts) vAlert.at
    ], [
      DateTime(2026, 11, 4, 18),
      DateTime(2026, 11, 5, 13),
    ]);
    expect(vAlerts.first.title, 'Entretien demain à 14:00');
    expect(vAlerts.first.body, 'Dev Java chez Kiabi');
    expect(vAlerts.last.body, 'Dev Java chez Kiabi, à 14:00');
  });

  test('Le rappel de la veille passé, seul celui d\'une heure avant reste', () {
    final vAlerts = buildInterviewAlerts([
      {'title': 'Dev', 'company': 'Acme', 'interview_at': '2026-10-24T15:00'},
    ], DateTime(2026, 10, 24, 9));

    expect(vAlerts.single.title, 'Entretien dans une heure');
  });

  test('Les rappels prennent les textes de la langue choisie', () {
    final vAlerts = buildInterviewAlerts(
      [
        {'title': 'Java developer', 'company': 'Acme', 'interview_at': '2026-11-05T14:00'},
        {'interview_at': '2026-11-06T09:30'},
      ],
      DateTime(2026, 10, 24, 9),
      InterviewAlertTexts(
        tomorrowAt: (pTime) => 'Interview tomorrow at $pTime',
        soon: 'Interview in one hour',
        untitled: 'Interview',
        where: (pTitle, pCompany) => '$pTitle at $pCompany',
        when: (pWhat, pTime) => '$pWhat, at $pTime',
      ),
    );

    expect(vAlerts.first.title, 'Interview tomorrow at 14:00');
    expect(vAlerts.first.body, 'Java developer at Acme');
    expect(vAlerts[1].body, 'Java developer at Acme, at 14:00');
    expect(vAlerts.last.title, 'Interview in one hour');
    expect(vAlerts.last.body, 'Interview, at 09:30');
  });
}
