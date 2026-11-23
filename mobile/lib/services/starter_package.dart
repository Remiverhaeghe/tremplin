// Paquet de révision livré avec l'application (assets/revision/depart.json.gz),
// écrit par tools/mobile_package.py : de quoi réviser sans jamais avoir vu le PC.

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

const starterPackageAsset = 'assets/revision/depart.json.gz';

/// Retourne le contenu du paquet livré, décompressé, prêt pour RevisionState.
Future<String> loadStarterPackage([AssetBundle? pBundle]) async {
  final vData = await (pBundle ?? rootBundle).load(starterPackageAsset);
  // Décompression en Dart pur : la même sur le téléphone et dans le navigateur
  final rContent = utf8.decode(const GZipDecoder().decodeBytes(vData.buffer.asUint8List()));

  return rContent;
}
