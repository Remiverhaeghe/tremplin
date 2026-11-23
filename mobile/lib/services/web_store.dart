// Stockage dans le navigateur (version web, iPhone compris) : textes JSON dans le
// stockage local du site, jeton dans le stockage chiffré de flutter_secure_storage.

import 'package:web/web.dart' as web;

import 'text_store.dart';

/// Préfixe des clés, pour ne pas mêler les données à celles d'un autre site du domaine.
const webKeyPrefix = 'tremplin.';

class WebRevisionStore extends TextRevisionStore {
  WebRevisionStore({super.pSecureStorage});

  @override
  Future<String?> readText(String pName) async =>
      web.window.localStorage.getItem('$webKeyPrefix$pName');

  @override
  Future<void> writeText(String pName, String pText) async =>
      web.window.localStorage.setItem('$webKeyPrefix$pName', pText);

  // Un seul onglet synchronise à la fois en pratique, et le navigateur ne lance aucune
  // tâche d'arrière-plan : pas de verrou à prendre.
  @override
  Future<bool> acquireSyncLock() async => true;

  @override
  Future<void> releaseSyncLock() async {}
}
