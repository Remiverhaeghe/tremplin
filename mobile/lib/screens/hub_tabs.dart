// Onglets « Entretien » et « Plus » de l'accueil : des listes courtes qui mènent
// aux écrans existants, au lieu d'icônes sans texte dans la barre du haut.

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../revision_state.dart';
import '../theme.dart';
import 'about_screen.dart';
import 'cv_screen.dart';
import 'interview_screen.dart';
import 'labs_screen.dart';
import 'library_screen.dart';
import 'oral_screen.dart';
import 'setup_screen.dart';
import 'skills_screen.dart';
import 'statistics_screen.dart';
import 'tracking_screen.dart';

/// Une entrée de liste : icône dans une pastille, titre, phrase d'explication.
class HubTile extends StatelessWidget {
  const HubTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final vScheme = Theme.of(context).colorScheme;
    final rTile = Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: (color ?? vScheme.primary).withValues(alpha: 0.14),
          foregroundColor: color ?? vScheme.primary,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );

    return rTile;
  }
}

void _open(BuildContext pContext, Widget Function() pBuild) =>
    Navigator.of(pContext).push(MaterialPageRoute<void>(builder: (_) => pBuild()));

/// Onglet Entretien : préparation, simulation, oral et auto-évaluation.
class InterviewHub extends StatelessWidget {
  const InterviewHub({super.key, required this.state});

  final RevisionState state;

  @override
  Widget build(BuildContext context) {
    final vNext = state.nextInterview(DateTime.now());
    final vSheet = vNext == null ? null : state.sheetOf(vNext);

    final rTab = Scaffold(
      appBar: AppBar(title: Text(context.texts.hubEntretien)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (vNext != null)
            HubTile(
              icon: Icons.event_available,
              color: coralColor,
              title: context.texts.homeEntretien(formatMoment(vNext['interview_at'] as String?)),
              subtitle: context.texts.hubFichePreparationPitchQuestions,
              onTap: vSheet == null ? null : () => _open(context, () => SheetScreen(sheet: vSheet)),
            ),
          HubTile(
            icon: Icons.description_outlined,
            title: context.texts.cvTitre,
            subtitle: context.texts.cvHubSousTitre,
            onTap: () => _open(context, () => CvScreen(state: state)),
          ),
          HubTile(
            icon: Icons.forum_outlined,
            title: context.texts.interviewSimulationEntretien,
            subtitle: context.texts.hubQuestionsTechniquesTireesTes,
            onTap: () => _open(context, () => InterviewScreen(state: state)),
          ),
          HubTile(
            icon: Icons.record_voice_over_outlined,
            title: context.texts.commonEntretienOral,
            subtitle: context.texts.hubQuestionsLuesVoixHaute,
            onTap: () => _open(context, () => OralScreen(state: state)),
          ),
          HubTile(
            icon: Icons.tune,
            title: context.texts.skillsAutoEvaluation,
            subtitle: context.texts.hubNoteTonNiveauSur,
            onTap: () => _open(context, () => SkillsScreen(state: state)),
          ),
        ],
      ),
    );

    return rTab;
  }
}

/// Onglet Plus : statistiques, examen blanc, simulations, guides et paramètres.
class MoreTab extends StatelessWidget {
  const MoreTab({super.key, required this.state, required this.onExam});

  final RevisionState state;
  final VoidCallback? onExam;

  @override
  Widget build(BuildContext context) {
    final vPackage = state.package;

    final rTab = Scaffold(
      appBar: AppBar(title: Text(context.texts.hubPlus)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HubTile(
            icon: Icons.insights,
            title: context.texts.statisticsStatistiques,
            subtitle: context.texts.hubActiviteDerniersJoursReussite,
            onTap: () => _open(context, () => StatisticsScreen(state: state)),
          ),
          HubTile(
            icon: Icons.timer_outlined,
            title: context.texts.homeExamenBlanc,
            subtitle: context.texts.hubTousThemesChronometre,
            onTap: onExam,
          ),
          HubTile(
            icon: Icons.build_circle_outlined,
            title: context.texts.labsSimulations,
            subtitle: context.texts.hubPannesAutomateSchemasGit,
            onTap: () => _open(context, () => LabsScreen(state: state)),
          ),
          HubTile(
            icon: Icons.local_library_outlined,
            title: context.texts.libraryGuidesSchemas,
            subtitle: context.texts.hubGuidesPratiquesSchemasChaque,
            onTap: vPackage == null
                ? null
                : () => _open(context, () => LibraryScreen(package: vPackage)),
          ),
          HubTile(
            icon: Icons.settings_outlined,
            title: context.texts.setupParametres,
            subtitle: context.texts.hubConnexionAuPcApparence,
            onTap: () => _open(context, () => SetupScreen(state: state)),
          ),
          HubTile(
            icon: Icons.info_outline,
            title: context.texts.aboutTitle,
            subtitle: context.texts.hubAboutSubtitle,
            onTap: () => _open(context, () => AboutScreen(state: state)),
          ),
        ],
      ),
    );

    return rTab;
  }
}
