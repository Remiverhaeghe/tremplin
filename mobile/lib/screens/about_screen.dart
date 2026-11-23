// Écran « À propos » : version, langue choisie, où vivent les données, code source et licences.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/texts.dart';
import '../logic/app_info.dart';
import '../revision_state.dart';
import 'setup_screen.dart';

/// Nom de la langue choisie dans les réglages, dans la langue affichée.
String languageName(AppLocalizations pText, String pLanguage) => switch (pLanguage) {
      'fr' => pText.setupFrancais,
      'en' => pText.setupEnglish,
      _ => pText.aboutLanguagePhone,
    };

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, required this.state});

  final RevisionState state;

  @override
  Widget build(BuildContext context) {
    final vText = context.texts;
    final vTheme = Theme.of(context);

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vText.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tremplin', style: vTheme.textTheme.headlineSmall),
          Text(vText.aboutVersion(appVersion), style: vTheme.textTheme.bodyMedium),
          const SizedBox(height: 12),
          Text(vText.aboutPurpose),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListenableBuilder(
                  listenable: state,
                  builder: (pContext, _) => ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(vText.setupLangue),
                    subtitle: Text(languageName(pContext.texts, state.language)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => SetupScreen(state: state)),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.phone_android),
                  title: Text(vText.aboutDataTitle),
                  subtitle: Text(vText.aboutData),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(vText.aboutSource),
                  subtitle: const Text(sourceUrl),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => launchUrl(Uri.parse(sourceUrl), mode: LaunchMode.externalApplication),
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(vText.aboutLicenses),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Tremplin',
                    applicationVersion: appVersion,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return rScreen;
  }
}
