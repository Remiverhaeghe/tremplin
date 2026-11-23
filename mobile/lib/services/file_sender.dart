// Envoi d'un fichier produit par l'appli (CV en PDF, Word, texte) : la feuille de partage du
// système propose courriel, Drive ou « enregistrer ». Les tests donnent leur propre envoi.

import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Envoie un fichier : octets, nom du fichier, type de contenu.
typedef FileSender = Future<void> Function(Uint8List pBytes, String pName, String pMime);

const mimePdf = 'application/pdf';
const mimeDocx = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
const mimeText = 'text/plain';

Future<void> shareFile(Uint8List pBytes, String pName, String pMime) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(pBytes, mimeType: pMime, name: pName)],
      fileNameOverrides: [pName],
    ),
  );
}
