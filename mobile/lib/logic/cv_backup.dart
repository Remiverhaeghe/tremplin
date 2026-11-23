// Sauvegarde chiffrée du CV : le parcours contient des coordonnées réelles, le fichier est donc
// chiffré par un mot de passe (PBKDF2-HMAC-SHA256, puis AES-256-GCM) avant de quitter le téléphone.

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

const _iterations = 100000;

Future<SecretKey> _key(String pPassword, List<int> pSalt, int pIterations) =>
    Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: pIterations, bits: 256)
        .deriveKeyFromPassword(password: pPassword, nonce: pSalt);

List<int> _random(int pLength) {
  final vRandom = Random.secure();

  return List<int>.generate(pLength, (_) => vRandom.nextInt(256));
}

/// Données chiffrées en texte : version, sel, nonce et contenu en base 64.
Future<String> sealCv(Map<String, Object?> pData, String pPassword, {int? pIterations}) async {
  final vIterations = pIterations ?? _iterations;
  final vSalt = _random(16);
  final vBox = await AesGcm.with256bits().encrypt(
    utf8.encode(jsonEncode(pData)),
    secretKey: await _key(pPassword, vSalt, vIterations),
  );

  return jsonEncode({
    'v': 1,
    'iterations': vIterations,
    'salt': base64Encode(vSalt),
    'data': base64Encode(vBox.concatenation()),
  });
}

/// Les données déchiffrées, ou null si le mot de passe ou le fichier ne conviennent pas.
Future<Map<String, Object?>?> openCv(String pSealed, String pPassword) async {
  try {
    final vJson = jsonDecode(pSealed) as Map<String, dynamic>;
    final vKey = await _key(
      pPassword,
      base64Decode(vJson['salt'] as String),
      vJson['iterations'] as int,
    );
    final vBox = SecretBox.fromConcatenation(
      base64Decode(vJson['data'] as String),
      nonceLength: 12,
      macLength: 16,
    );
    final vClear = await AesGcm.with256bits().decrypt(vBox, secretKey: vKey);

    return Map<String, Object?>.from(jsonDecode(utf8.decode(vClear)) as Map);
  } on Object {
    return null;
  }
}
