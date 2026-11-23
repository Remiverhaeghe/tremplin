// Stockage sur le téléphone : fichiers JSON dans le dossier de l'application,
// jeton dans le stockage chiffré du système.

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'text_store.dart';

export 'text_store.dart';

/// Au-delà, le verrou vient d'une synchronisation interrompue (application
/// arrêtée net) : il est repris.
const staleSyncLock = Duration(minutes: 5);

/// Crée le fichier de verrou de façon exclusive ; retourne s'il est obtenu.
///
/// La création exclusive est atomique, même entre l'application et la tâche
/// d'arrière-plan qui tournent dans le même processus Android, où les verrous
/// de fichier classiques ne s'excluent pas.
Future<bool> acquireLockFile(File pFile, {DateTime? pNow}) async {
  var rAcquired = false;

  try {
    await pFile.create(exclusive: true);
    rAcquired = true;
  } on FileSystemException {
    try {
      final vAge = (pNow ?? DateTime.now()).difference(await pFile.lastModified());

      if (vAge > staleSyncLock) {
        await pFile.delete();
        await pFile.create(exclusive: true);
        rAcquired = true;
      }
    } on FileSystemException {
      // Repris entre-temps par l'autre synchronisation : elle garde la main.
      rAcquired = false;
    }
  }

  return rAcquired;
}

class FileRevisionStore extends TextRevisionStore {
  FileRevisionStore({super.pSecureStorage});

  Future<File> getFile(String pName) async {
    final vDirectory = await getApplicationDocumentsDirectory();

    final rFile = File('${vDirectory.path}/$pName');

    return rFile;
  }

  @override
  Future<String?> readText(String pName) async {
    final vFile = await getFile(pName);

    final rText = await vFile.exists() ? await vFile.readAsString() : null;

    return rText;
  }

  /// Écrit dans un fichier temporaire puis le renomme : une coupure pendant
  /// l'écriture ne laisse jamais de fichier à moitié écrit.
  @override
  Future<void> writeText(String pName, String pText) async {
    final vFile = await getFile(pName);
    final vTemporary = File('${vFile.path}.tmp');

    await vTemporary.writeAsString(pText, flush: true);
    await vTemporary.rename(vFile.path);
  }

  @override
  Future<bool> acquireSyncLock() async => acquireLockFile(await getFile(syncLockFile));

  @override
  Future<void> releaseSyncLock() async {
    final vFile = await getFile(syncLockFile);

    if (await vFile.exists()) {
      await vFile.delete();
    }
  }
}
