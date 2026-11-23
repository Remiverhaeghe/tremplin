// Point d'entrée : charge le stockage local, puis ouvre la configuration au
// premier lancement ou directement les thèmes de révision.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/texts.dart';
import 'platform/app_services.dart';
import 'revision_state.dart';
import 'screens/home_screen.dart';
import 'screens/connect_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Vérification des offres en arrière-plan sur Android ; rien dans le navigateur.
  await startBackgroundTasks();

  runApp(RevisionApp(state: createRevisionState()));
}

class RevisionApp extends StatelessWidget {
  const RevisionApp({super.key, required this.state});

  final RevisionState state;

  static const themeModes = {
    'system': ThemeMode.system,
    'light': ThemeMode.light,
    'dark': ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    final rApp = ListenableBuilder(
      listenable: state,
      builder: (_, __) => MaterialApp(
        title: 'Tremplin',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: themeModes[state.appearance],
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // Le choix de l'application s'ajoute à la taille réglée sur le téléphone.
        builder: (pContext, pChild) => MediaQuery(
          data: MediaQuery.of(pContext).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.textScalerOf(pContext).scale(1) * state.textScale,
            ),
          ),
          child: pChild!,
        ),
        home: StartScreen(state: state),
      ),
    );

    return rApp;
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.state});

  final RevisionState state;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late final Future<void> loading = widget.state.load();

  @override
  Widget build(BuildContext context) {
    final rScreen = FutureBuilder<void>(
      future: loading,
      builder: (pContext, pSnapshot) {
        if (pSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Sans PC ni paquet : premier lancement, on propose de connecter le PC ou
        // de réviser tout de suite avec le paquet livré
        return widget.state.settings == null && widget.state.package == null
            ? ConnectScreen(state: widget.state)
            : HomeScreen(state: widget.state);
      },
    );

    return rScreen;
  }
}
