// Application Android : fichiers, notifications, widget et vérification des offres.

import 'package:workmanager/workmanager.dart';

import '../revision_state.dart';
import '../services/android_home_widget.dart';
import '../services/file_store.dart';
import '../services/local_reminders.dart';
import '../services/offer_checks.dart';

/// État de l'application, avec ce que le téléphone sait faire.
RevisionState createRevisionState() => RevisionState(
      FileRevisionStore(),
      reminders: LocalReminders(),
      homeWidget: AndroidHomeWidget(),
    );

/// Point d'entrée de la vérification des offres, lancée par Android même application fermée.
Future<void> startBackgroundTasks() => Workmanager().initialize(checkOffersInBackground);
