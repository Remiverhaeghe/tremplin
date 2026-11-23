// Une version du CV : ce qu'on garde du parcours, dans quel ordre, avec une accroche écrite
// à la main. Une seule base de données, plusieurs versions selon le poste visé.

import 'cv_profile.dart';

/// Sections possibles, dans l'ordre où une version les range.
enum CvSection { summary, experience, projects, skills, education, languages, strengths, interests }

class CvVersion {
  const CvVersion({
    required this.id,
    required this.label,
    this.headline = '',
    this.summary = '',
    this.sections = const [],
    this.experienceIds = const [],
    this.projectIds = const [],
    this.skillIds = const [],
    this.withPhoto = false,
  });

  final String id;

  /// Nom court, pour choisir la version : « Développeur ».
  final String label;

  /// Ligne sous le nom : le poste visé.
  final String headline;

  /// Accroche écrite par Rémi, quelques phrases.
  final String summary;

  /// Sections affichées, dans cet ordre.
  final List<CvSection> sections;

  /// Éléments gardés, dans l'ordre du CV ; un identifiant inconnu est ignoré.
  final List<String> experienceIds;
  final List<String> projectIds;
  final List<String> skillIds;
  final bool withPhoto;

  CvVersion copyWith({
    String? label,
    String? headline,
    String? summary,
    List<CvSection>? sections,
    List<String>? experienceIds,
    List<String>? projectIds,
    List<String>? skillIds,
    bool? withPhoto,
  }) =>
      CvVersion(
        id: id,
        label: label ?? this.label,
        headline: headline ?? this.headline,
        summary: summary ?? this.summary,
        sections: sections ?? this.sections,
        experienceIds: experienceIds ?? this.experienceIds,
        projectIds: projectIds ?? this.projectIds,
        skillIds: skillIds ?? this.skillIds,
        withPhoto: withPhoto ?? this.withPhoto,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'headline': headline,
        'summary': summary,
        'sections': [for (final vSection in sections) vSection.name],
        'experienceIds': experienceIds,
        'projectIds': projectIds,
        'skillIds': skillIds,
        'withPhoto': withPhoto,
      };

  static CvVersion fromJson(Map<String, Object?> pJson) {
    List<String> strings(String pKey) => [
          for (final vItem in (pJson[pKey] as List<Object?>?) ?? const []) vItem! as String,
        ];
    final vNames = {for (final vSection in CvSection.values) vSection.name: vSection};

    return CvVersion(
      id: pJson['id']! as String,
      label: pJson['label']! as String,
      headline: pJson['headline'] as String? ?? '',
      summary: pJson['summary'] as String? ?? '',
      sections: [
        for (final vName in strings('sections'))
          if (vNames[vName] case final CvSection vSection?) vSection,
      ],
      experienceIds: strings('experienceIds'),
      projectIds: strings('projectIds'),
      skillIds: strings('skillIds'),
      withPhoto: pJson['withPhoto'] as bool? ?? false,
    );
  }
}

/// Versions proposées au départ : tout le parcours, sans phrase écrite à la place de Rémi.
/// « Développeur » met les projets en avant, « Industrie et méthodes » l'expérience de terrain.
List<CvVersion> startingVersions(CvProfile pProfile) {
  List<String> ids(Iterable<String> pIds) => pIds.toList();
  final vExperiences = ids(pProfile.experiences.map((pItem) => pItem.id));
  final vProjects = ids(pProfile.projects.map((pItem) => pItem.id));
  final vSkills = ids(pProfile.skills.map((pItem) => pItem.id));

  final rVersions = [
    CvVersion(
      id: 'developpeur',
      label: 'Développeur',
      sections: const [
        CvSection.summary,
        CvSection.experience,
        CvSection.projects,
        CvSection.skills,
        CvSection.education,
        CvSection.languages,
      ],
      experienceIds: vExperiences,
      projectIds: vProjects,
      skillIds: vSkills,
    ),
    CvVersion(
      id: 'industrie',
      label: 'Industrie et méthodes',
      sections: const [
        CvSection.summary,
        CvSection.experience,
        CvSection.skills,
        CvSection.education,
        CvSection.languages,
        CvSection.strengths,
      ],
      experienceIds: vExperiences.reversed.toList(),
      skillIds: vSkills,
    ),
  ];

  return rVersions;
}
