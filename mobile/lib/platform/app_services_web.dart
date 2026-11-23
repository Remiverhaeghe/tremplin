// Version web : stockage du navigateur ; ni notification, ni widget, ni tâche de fond.

import '../revision_state.dart';
import '../services/web_store.dart';

/// État de l'application dans le navigateur.
RevisionState createRevisionState() => RevisionState(WebRevisionStore());

/// Le navigateur ne relance pas l'application fermée : rien à démarrer.
Future<void> startBackgroundTasks() async {}
