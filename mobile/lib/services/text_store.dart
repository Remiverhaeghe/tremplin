// Stockage commun au téléphone et au navigateur : textes JSON nommés, jeton dans le
// stockage chiffré. Chaque plateforme dit seulement où lire et écrire un texte.

import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'revision_store.dart';

const addressKey = 'server_address';
const tokenKey = 'api_token';
const certificateKey = 'certificate_sha256';

const packageFile = 'package.json';
const progressFile = 'progress.json';
const pendingFile = 'pending.json';
const examsFile = 'exams.json';
const preferencesFile = 'preferences.json';
const offersFile = 'offers.json';
const syncLockFile = 'sync.lock';

abstract class TextRevisionStore implements RevisionStore {
  TextRevisionStore({FlutterSecureStorage? pSecureStorage})
      : secureStorage = pSecureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage secureStorage;

  /// Texte rangé sous ce nom, ou null s'il n'existe pas encore.
  Future<String?> readText(String pName);

  /// Remplace le texte rangé sous ce nom.
  Future<void> writeText(String pName, String pText);

  @override
  Future<ServerSettings?> loadSettings() async {
    final vAddress = await secureStorage.read(key: addressKey);
    final vToken = await secureStorage.read(key: tokenKey);
    final vCertificate = await secureStorage.read(key: certificateKey);

    final rSettings = vAddress == null || vToken == null
        ? null
        : ServerSettings(address: vAddress, token: vToken, certificateSha256: vCertificate);

    return rSettings;
  }

  @override
  Future<void> saveSettings(ServerSettings pSettings) async {
    await secureStorage.write(key: addressKey, value: pSettings.address);
    await secureStorage.write(key: tokenKey, value: pSettings.token);

    if (pSettings.certificateSha256 == null) {
      await secureStorage.delete(key: certificateKey);
    } else {
      await secureStorage.write(key: certificateKey, value: pSettings.certificateSha256);
    }
  }

  @override
  Future<String?> loadPackage() => readText(packageFile);

  @override
  Future<void> savePackage(String pContent) => writeText(packageFile, pContent);

  @override
  Future<Map<String, dynamic>?> loadProgress() async {
    final vText = await readText(progressFile);

    final rProgress = vText == null ? null : jsonDecode(vText) as Map<String, dynamic>;

    return rProgress;
  }

  @override
  Future<void> saveProgress(Map<String, dynamic> pProgress) =>
      writeText(progressFile, jsonEncode(pProgress));

  Future<List<Map<String, dynamic>>> readList(String pName) async {
    final vText = await readText(pName);

    final rItems = vText == null
        ? <Map<String, dynamic>>[]
        : [
            for (final vItem in jsonDecode(vText) as List) Map<String, dynamic>.from(vItem as Map),
          ];

    return rItems;
  }

  @override
  Future<List<Map<String, dynamic>>> loadPending() => readList(pendingFile);

  @override
  Future<void> savePending(List<Map<String, dynamic>> pAnswers) =>
      writeText(pendingFile, jsonEncode(pAnswers));

  @override
  Future<List<Map<String, dynamic>>> loadExamResults() => readList(examsFile);

  @override
  Future<void> saveExamResults(List<Map<String, dynamic>> pResults) =>
      writeText(examsFile, jsonEncode(pResults));

  @override
  Future<List<Map<String, dynamic>>> loadOffers() => readList(offersFile);

  @override
  Future<void> saveOffers(List<Map<String, dynamic>> pOffers) =>
      writeText(offersFile, jsonEncode(pOffers));

  @override
  Future<Map<String, dynamic>> loadPreferences() async {
    final vText = await readText(preferencesFile);

    final rPreferences =
        vText == null ? <String, dynamic>{} : jsonDecode(vText) as Map<String, dynamic>;

    return rPreferences;
  }

  @override
  Future<void> savePreferences(Map<String, dynamic> pPreferences) =>
      writeText(preferencesFile, jsonEncode(pPreferences));
}
