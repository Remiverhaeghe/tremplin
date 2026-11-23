// Carnet de contacts, suivi des formations et tableau de la semaine. Données fictives dans les
// tests ; sur le téléphone, rien ne part vers le PC.

import 'dart:math';

import 'cv_prep.dart';
import 'cv_profile.dart';
import 'cv_version.dart';

class CvPerson {
  const CvPerson({
    required this.id,
    required this.name,
    this.company = '',
    this.role = '',
    this.note = '',
    this.lastAt = '',
    this.nextAt = '',
  });

  final String id;
  final String name;
  final String company;
  final String role;
  final String note;

  /// Dernier échange et prochaine reprise de contact, au format `AAAA-MM-JJ` ; vides si inconnus.
  final String lastAt;
  final String nextAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'company': company,
        'role': role,
        'note': note,
        'lastAt': lastAt,
        'nextAt': nextAt,
      };

  static CvPerson fromJson(Map<String, Object?> pJson) => CvPerson(
        id: '${pJson['id']}',
        name: '${pJson['name'] ?? ''}',
        company: '${pJson['company'] ?? ''}',
        role: '${pJson['role'] ?? ''}',
        note: '${pJson['note'] ?? ''}',
        lastAt: '${pJson['lastAt'] ?? ''}',
        nextAt: '${pJson['nextAt'] ?? ''}',
      );
}

/// État d'une formation : `todo`, `doing` ou `done`.
const cvTrainingStates = ['todo', 'doing', 'done'];

class CvTraining {
  const CvTraining({
    required this.id,
    required this.title,
    this.state = 'todo',
    this.dueAt = '',
  });

  final String id;
  final String title;
  final String state;

  /// Date visée pour finir, `AAAA-MM-JJ` ; vide si aucune.
  final String dueAt;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'state': state, 'dueAt': dueAt};

  static CvTraining fromJson(Map<String, Object?> pJson) => CvTraining(
        id: '${pJson['id']}',
        title: '${pJson['title'] ?? ''}',
        state: cvTrainingStates.contains(pJson['state']) ? '${pJson['state']}' : 'todo',
        dueAt: '${pJson['dueAt'] ?? ''}',
      );

  CvTraining copyWith({String? state}) =>
      CvTraining(id: id, title: title, state: state ?? this.state, dueAt: dueAt);
}

/// Une ligne du tableau de la semaine : `followup`, `contact` ou `training`.
typedef CvWeekItem = ({DateTime day, String kind, String label});

DateTime? _day(String pValue) {
  final vDate = DateTime.tryParse(pValue);

  return vDate == null ? null : DateTime(vDate.year, vDate.month, vDate.day);
}

/// Ce qui est à faire dans les sept prochains jours, plus ce qui est en retard (ramené à
/// aujourd'hui), dans l'ordre des jours.
List<CvWeekItem> weekPlan({
  required List<Map<String, dynamic>> pSent,
  required List<CvPerson> pContacts,
  required List<CvTraining> pTrainings,
  required DateTime pNow,
}) {
  final vToday = DateTime(pNow.year, pNow.month, pNow.day);
  final vEnd = vToday.add(const Duration(days: 7));
  final rItems = <CvWeekItem>[];

  void add(DateTime? pDate, String pKind, String pLabel) {
    if (pDate != null && pDate.isBefore(vEnd)) {
      rItems.add((day: pDate.isBefore(vToday) ? vToday : pDate, kind: pKind, label: pLabel));
    }
  }

  for (final vItem in pSent) {
    final vSentAt = _day('${vItem['at']}');

    if (vSentAt != null &&
        '${vItem['outcome'] ?? ''}'.isEmpty &&
        '${vItem['followed_up'] ?? ''}'.isEmpty &&
        '${vItem['company'] ?? ''}'.isNotEmpty) {
      add(
        DateTime(vSentAt.year, vSentAt.month, vSentAt.day + 7),
        'followup',
        '${vItem['company']} · ${vItem['title'] ?? ''}',
      );
    }
  }
  for (final vContact in pContacts) {
    add(_day(vContact.nextAt), 'contact', vContact.name);
  }
  for (final vTraining in pTrainings) {
    if (vTraining.state != 'done') {
      add(_day(vTraining.dueAt), 'training', vTraining.title);
    }
  }
  rItems.sort((pA, pB) => pA.day.compareTo(pB.day));

  return rItems;
}

/// Questions d'une simulation : un tirage mélangé des questions de préparation, que la graine
/// rend reproductible, et toujours la présentation en premier.
List<String> simulationQuestions(
  String pOffer,
  CvProfile pProfile,
  CvVersion pVersion, {
  required int pSeed,
  String pCompany = '',
  int pCount = 5,
}) {
  final vPool = [
    for (final vItem in prepQuestions(pOffer, pProfile, pVersion, pCompany: pCompany, pMax: 30))
      _wording(vItem),
  ]..shuffle(Random(pSeed));

  return ['Présentez-vous en une minute.', ...vPool.take(pCount - 1)];
}

String _wording(CvPrepQuestion pItem) => switch (pItem.kind) {
      'why-company' => 'Pourquoi ${pItem.subject} ?',
      'pivot' => 'Pourquoi changer de métier maintenant ?',
      'project' => 'Parlez-moi de votre projet ${pItem.subject}.',
      'used' => 'Racontez une situation où vous avez utilisé ${pItem.subject}.',
      _ => 'Comment apprendriez-vous ${pItem.subject} ?',
    };
