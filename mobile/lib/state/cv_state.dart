part of '../revision_state.dart';

/// CV sur le téléphone : un parcours, plusieurs versions, et la liste des CV envoyés. Rien ne
/// part vers le PC : le parcours contient des coordonnées réelles.
mixin CvState on ChangeNotifier {
  Map<String, dynamic> get preferences;

  Future<void> savePreference(String pKey, Object pValue);

  CvProfile get cvProfile {
    final vRaw = preferences[cvProfilePreference];
    final rProfile =
        vRaw is Map ? CvProfile.fromJson(Map<String, Object?>.from(vRaw)) : const CvProfile();

    return rProfile;
  }

  List<CvVersion> get cvVersions => [
        for (final vItem in preferences[cvVersionsPreference] as List? ?? const [])
          CvVersion.fromJson(Map<String, Object?>.from(vItem as Map)),
      ];

  /// Envois notés, les plus récents d'abord.
  List<Map<String, dynamic>> get cvSent => [
        for (final vItem in preferences[cvSentPreference] as List? ?? const [])
          Map<String, dynamic>.from(vItem as Map),
      ];

  /// Garde un parcours collé ou importé ; refuse un texte qui n'est pas un parcours.
  /// Les versions de départ sont créées si aucune n'existe encore.
  Future<bool> importCvProfile(String pText) async {
    final vProfile = CvProfile.tryParse(pText);
    final rImported = vProfile != null && !vProfile.isEmpty;

    if (rImported) {
      await savePreference(cvProfilePreference, vProfile.toJson());
      if (cvVersions.isEmpty) {
        await saveCvVersions(startingVersions(vProfile));
      }
    }

    return rImported;
  }

  Future<void> saveCvVersions(List<CvVersion> pVersions) =>
      savePreference(cvVersionsPreference, [for (final vItem in pVersions) vItem.toJson()]);

  /// Remplace la version de même identifiant, ou l'ajoute à la fin.
  Future<void> saveCvVersion(CvVersion pVersion) async {
    final vVersions = cvVersions;
    final vAt = vVersions.indexWhere((pItem) => pItem.id == pVersion.id);

    if (vAt >= 0) {
      vVersions[vAt] = pVersion;
    } else {
      vVersions.add(pVersion);
    }
    await saveCvVersions(vVersions);
  }

  Future<void> removeCvVersion(String pId) => saveCvVersions([
        for (final vItem in cvVersions)
          if (vItem.id != pId) vItem
      ]);

  /// Note un CV envoyé : quelle version, à qui, dans quel format.
  Future<void> recordCvSent({
    required CvVersion pVersion,
    required String pFormat,
    String pCompany = '',
    String pTitle = '',
    String pUrl = '',
    bool pTailored = false,
    DateTime? pAt,
  }) async {
    final vEntry = {
      'at': (pAt ?? DateTime.now()).toIso8601String().split('.').first,
      'version_id': pVersion.id,
      'version': pVersion.label,
      'format': pFormat,
      'company': pCompany.trim(),
      'title': pTitle.trim(),
      'url': pUrl.trim(),
      'tailored': pTailored,
    };

    await savePreference(cvSentPreference, [vEntry, ...cvSent].take(maxCvSent).toList());
  }

  /// Phrases avec un chiffre que Rémi a confirmé, sous leur clé (`cvClaimKey`).
  Set<String> get cvConfirmedClaims => {
        for (final vItem in preferences[cvConfirmedPreference] as List? ?? const []) '$vItem',
      };

  Future<void> confirmCvClaim(String pText) =>
      savePreference(cvConfirmedPreference, {...cvConfirmedClaims, cvClaimKey(pText)}.toList());
}
