// Parcours de Rémi tel qu'il l'écrit une seule fois : contact, expériences, formations,
// compétences, projets. Les versions du CV (cv_version.dart) n'en choisissent que des morceaux.
// Tout reste sur le téléphone : aucune donnée réelle n'est versionnée dans le dépôt.

import 'dart:convert';

/// Coordonnées et mentions qui ouvrent le CV.
class CvContact {
  const CvContact({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.licence = '',
    this.notice = '',
    this.availability = '',
  });

  final String name;
  final String email;
  final String phone;
  final String city;
  final String licence;

  /// Préavis, par exemple « Préavis : 3 mois ».
  final String notice;

  /// Disponibilité, par exemple « Disponible pour CDI ».
  final String availability;

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'city': city,
    'licence': licence,
    'notice': notice,
    'availability': availability,
  };

  static CvContact fromJson(Map<String, Object?> pJson) => CvContact(
    name: pJson['name'] as String? ?? '',
    email: pJson['email'] as String? ?? '',
    phone: pJson['phone'] as String? ?? '',
    city: pJson['city'] as String? ?? '',
    licence: pJson['licence'] as String? ?? '',
    notice: pJson['notice'] as String? ?? '',
    availability: pJson['availability'] as String? ?? '',
  );
}

/// Un poste : titre, employeur, dates en clair (« 2022 à aujourd'hui ») et lignes de détail.
class CvExperience {
  const CvExperience({
    required this.id,
    required this.title,
    this.company = '',
    this.dates = '',
    this.lines = const [],
  });

  final String id;
  final String title;
  final String company;
  final String dates;
  final List<String> lines;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'company': company,
    'dates': dates,
    'lines': lines,
  };

  static CvExperience fromJson(Map<String, Object?> pJson) => CvExperience(
    id: pJson['id']! as String,
    title: pJson['title']! as String,
    company: pJson['company'] as String? ?? '',
    dates: pJson['dates'] as String? ?? '',
    lines: _strings(pJson['lines']),
  );
}

/// Un diplôme ou une formation.
class CvEducation {
  const CvEducation({required this.id, required this.title, this.place = '', this.dates = ''});

  final String id;
  final String title;
  final String place;
  final String dates;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'place': place, 'dates': dates};

  static CvEducation fromJson(Map<String, Object?> pJson) => CvEducation(
    id: pJson['id']! as String,
    title: pJson['title']! as String,
    place: pJson['place'] as String? ?? '',
    dates: pJson['dates'] as String? ?? '',
  );
}

/// Un projet réel, public, que Rémi peut défendre en entretien.
class CvProject {
  const CvProject({required this.id, required this.name, this.url = '', this.lines = const []});

  final String id;
  final String name;
  final String url;
  final List<String> lines;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'url': url, 'lines': lines};

  static CvProject fromJson(Map<String, Object?> pJson) => CvProject(
    id: pJson['id']! as String,
    name: pJson['name']! as String,
    url: pJson['url'] as String? ?? '',
    lines: _strings(pJson['lines']),
  );
}

/// Un groupe de compétences : « Développement », avec ses mots-clés.
class CvSkillGroup {
  const CvSkillGroup({required this.id, required this.title, this.items = const []});

  final String id;
  final String title;
  final List<String> items;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'items': items};

  static CvSkillGroup fromJson(Map<String, Object?> pJson) => CvSkillGroup(
    id: pJson['id']! as String,
    title: pJson['title']! as String,
    items: _strings(pJson['items']),
  );
}

/// Une langue et son niveau.
class CvLanguage {
  const CvLanguage({required this.name, required this.level});

  final String name;
  final String level;

  Map<String, Object?> toJson() => {'name': name, 'level': level};

  static CvLanguage fromJson(Map<String, Object?> pJson) =>
      CvLanguage(name: pJson['name']! as String, level: pJson['level'] as String? ?? '');
}

/// Tout le parcours.
class CvProfile {
  const CvProfile({
    this.contact = const CvContact(),
    this.experiences = const [],
    this.education = const [],
    this.projects = const [],
    this.skills = const [],
    this.languages = const [],
    this.strengths = const [],
    this.interests = const [],
  });

  final CvContact contact;
  final List<CvExperience> experiences;
  final List<CvEducation> education;
  final List<CvProject> projects;
  final List<CvSkillGroup> skills;
  final List<CvLanguage> languages;

  /// Atouts et qualités, une ligne chacun.
  final List<String> strengths;
  final List<String> interests;

  bool get isEmpty => contact.name.isEmpty && experiences.isEmpty && education.isEmpty;

  Map<String, Object?> toJson() => {
    'contact': contact.toJson(),
    'experiences': [for (final vItem in experiences) vItem.toJson()],
    'education': [for (final vItem in education) vItem.toJson()],
    'projects': [for (final vItem in projects) vItem.toJson()],
    'skills': [for (final vItem in skills) vItem.toJson()],
    'languages': [for (final vItem in languages) vItem.toJson()],
    'strengths': strengths,
    'interests': interests,
  };

  static CvProfile fromJson(Map<String, Object?> pJson) {
    List<T> list<T>(String pKey, T Function(Map<String, Object?>) pRead) => [
      for (final vItem in (pJson[pKey] as List<Object?>?) ?? const [])
        pRead(vItem! as Map<String, Object?>),
    ];

    return CvProfile(
      contact: CvContact.fromJson((pJson['contact'] as Map<String, Object?>?) ?? const {}),
      experiences: list('experiences', CvExperience.fromJson),
      education: list('education', CvEducation.fromJson),
      projects: list('projects', CvProject.fromJson),
      skills: list('skills', CvSkillGroup.fromJson),
      languages: list('languages', CvLanguage.fromJson),
      strengths: _strings(pJson['strengths']),
      interests: _strings(pJson['interests']),
    );
  }

  /// Parcours lu depuis un fichier JSON ; null si le fichier n'est pas un parcours.
  static CvProfile? tryParse(String pText) {
    try {
      final vJson = jsonDecode(pText);
      final rProfile = vJson is Map<String, Object?> ? fromJson(vJson) : null;

      return rProfile;
    } on Object {
      return null;
    }
  }
}

List<String> _strings(Object? pValue) => [
  for (final vItem in (pValue as List<Object?>?) ?? const []) vItem! as String,
];
