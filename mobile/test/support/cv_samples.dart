// Parcours fictif partagé par les tests du CV : aucune donnée réelle.

import 'package:jobboard_revision/logic/cv_profile.dart';
import 'package:jobboard_revision/logic/cv_version.dart';

const sampleProfile = CvProfile(
  contact: CvContact(
    name: 'Camille Durand',
    email: 'camille.durand@example.org',
    phone: '+33 6 00 00 00 00',
    city: 'Lille (59)',
    notice: 'Préavis : 1 mois',
  ),
  experiences: [
    CvExperience(
      id: 'dev',
      title: 'Développeuse Java',
      company: 'Atelier Exemple',
      dates: '2020 à aujourd’hui',
      lines: ['Maintenance d’une application métier', 'Interfaces avec un ERP en SFTP'],
    ),
    CvExperience(
      id: 'maint',
      title: 'Responsable de maintenance',
      company: 'Usine Exemple',
      dates: '2010 - 2019',
      lines: ['Planification des interventions'],
    ),
  ],
  education: [
    CvEducation(id: 'bts', title: 'BTS Maintenance', place: 'Lycée Exemple', dates: '2008')
  ],
  projects: [
    CvProject(
        id: 'p1', name: 'Calculatrice', url: 'https://example.org/calc', lines: ['Java Swing']),
  ],
  skills: [
    CvSkillGroup(id: 's1', title: 'Développement', items: ['Java', 'SQL', 'API REST']),
  ],
  languages: [CvLanguage(name: 'Anglais', level: 'B2')],
  strengths: ['Rigueur', 'Esprit d’analyse'],
);

const sampleVersion = CvVersion(
  id: 'dev',
  label: 'Développeur',
  headline: 'Développeuse Java',
  summary: 'Dix ans d’industrie, cinq ans d’informatique.',
  sections: [
    CvSection.summary,
    CvSection.experience,
    CvSection.projects,
    CvSection.skills,
    CvSection.education,
    CvSection.languages,
  ],
  experienceIds: ['dev', 'maint', 'inconnu'],
  projectIds: ['p1'],
  skillIds: ['s1'],
);
