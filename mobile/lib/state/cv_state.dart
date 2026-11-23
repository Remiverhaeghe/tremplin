part of '../revision_state.dart';

/// CV sur le téléphone : un parcours, plusieurs versions, et la liste des CV envoyés. Rien ne
/// part vers le PC : le parcours contient des coordonnées réelles.
mixin CvState on ChangeNotifier {
  Map<String, dynamic> get preferences;

  Reminders? get reminders;

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
    String pSnapshot = '',
    String pFile = '',
    DateTime? pAt,
  }) async {
    final vAt = (pAt ?? DateTime.now()).toIso8601String().split('.').first;
    final vEntry = {
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'at': vAt,
      'version_id': pVersion.id,
      'version': pVersion.label,
      'format': pFormat,
      'company': pCompany.trim(),
      'title': pTitle.trim(),
      'url': pUrl.trim(),
      'tailored': pTailored,
      'outcome': '',
      'followed_up': '',
      'snapshot': pSnapshot,
      'files': [if (pFile.isNotEmpty) pFile],
    };
    final vAll = [vEntry, ...cvSent].take(maxCvSent).toList();

    // Le texte figé n'est gardé que pour les envois récents : il pèse plusieurs ko chacun.
    for (var vIndex = maxCvSnapshots; vIndex < vAll.length; vIndex++) {
      vAll[vIndex]['snapshot'] = '';
    }
    await savePreference(cvSentPreference, vAll);
    await scheduleCvFollowUps();
  }

  List<CvContact> get cvContacts => [
        for (final vItem in preferences[cvContactsPreference] as List? ?? const [])
          CvContact.fromJson(Map<String, Object?>.from(vItem as Map)),
      ];

  Future<void> saveCvContacts(List<CvContact> pContacts) =>
      savePreference(cvContactsPreference, [for (final vItem in pContacts) vItem.toJson()]);

  List<CvTraining> get cvTrainings => [
        for (final vItem in preferences[cvTrainingsPreference] as List? ?? const [])
          CvTraining.fromJson(Map<String, Object?>.from(vItem as Map)),
      ];

  Future<void> saveCvTrainings(List<CvTraining> pTrainings) =>
      savePreference(cvTrainingsPreference, [for (final vItem in pTrainings) vItem.toJson()]);

  /// Replanifie les rappels de relance d'après les envois sans réponse.
  Future<void> scheduleCvFollowUps() async =>
      reminders?.scheduleFollowUps(followUpAlerts(cvSent, DateTime.now()));

  /// Change des champs d'un envoi noté (réponse reçue, relance faite, pièce jointe ajoutée).
  Future<void> updateCvSent(String pId, Map<String, Object?> pChanges) async {
    final vAll = cvSent;
    final vAt = vAll.indexWhere((pItem) => '${pItem['id']}' == pId);

    if (vAt >= 0) {
      final vAnswered =
          '${pChanges['outcome'] ?? ''}'.isNotEmpty && '${vAll[vAt]['answered_at'] ?? ''}'.isEmpty;

      vAll[vAt] = {
        ...vAll[vAt],
        ...pChanges,
        if (vAnswered) 'answered_at': DateTime.now().toIso8601String().split('.').first,
      };
      await savePreference(cvSentPreference, vAll);
      await scheduleCvFollowUps();
    }
  }

  /// Ajoute un fichier (une lettre, par exemple) au dernier envoi pour cette entreprise et ce poste.
  Future<void> addCvSentFile(String pCompany, String pTitle, String pFile) async {
    final vAll = cvSent;
    final vAt = vAll.indexWhere(
      (pItem) => pItem['company'] == pCompany.trim() && pItem['title'] == pTitle.trim(),
    );

    if (vAt >= 0) {
      final vFiles = List<String>.from(vAll[vAt]['files'] as List? ?? const []);
      vAll[vAt] = {
        ...vAll[vAt],
        'files': [...vFiles.where((pName) => pName != pFile), pFile],
      };
      await savePreference(cvSentPreference, vAll);
    }
  }

  /// Tout le CV en un texte chiffré par [pPassword], prêt à être partagé.
  Future<String> exportCvBackup(String pPassword, {int? pIterations}) => sealCv(
        {for (final vKey in cvPreferenceKeys) vKey: preferences[vKey]},
        pPassword,
        pIterations: pIterations,
      );

  /// Restaure un CV sauvegardé ; faux si le mot de passe ou le fichier ne conviennent pas.
  Future<bool> importCvBackup(String pSealed, String pPassword) async {
    final vData = await openCv(pSealed.trim(), pPassword);

    if (vData == null || vData[cvProfilePreference] == null) {
      return false;
    }
    for (final vKey in cvPreferenceKeys) {
      if (vData[vKey] != null) {
        await savePreference(vKey, vData[vKey]!);
      }
    }

    return true;
  }

  /// Phrases avec un chiffre que Rémi a confirmé, sous leur clé (`cvClaimKey`).
  Set<String> get cvConfirmedClaims => {
        for (final vItem in preferences[cvConfirmedPreference] as List? ?? const []) '$vItem',
      };

  Future<void> confirmCvClaim(String pText) =>
      savePreference(cvConfirmedPreference, {...cvConfirmedClaims, cvClaimKey(pText)}.toList());

  LetterKit get cvLetterKit {
    final vRaw = preferences[cvLetterKitPreference];

    return vRaw is Map ? LetterKit.fromJson(Map<String, Object?>.from(vRaw)) : const LetterKit();
  }

  Future<void> saveCvLetterKit(LetterKit pKit) =>
      savePreference(cvLetterKitPreference, pKit.toJson());

  /// Réponses de formulaire ; celles de départ tant que Rémi n'a rien enregistré.
  List<CvAnswer> get cvAnswers {
    final vRaw = preferences[cvAnswersPreference];

    return vRaw is List
        ? [for (final vItem in vRaw) CvAnswer.fromJson(Map<String, Object?>.from(vItem as Map))]
        : startingAnswers(cvProfile);
  }

  Future<void> saveCvAnswers(List<CvAnswer> pAnswers) =>
      savePreference(cvAnswersPreference, [for (final vItem in pAnswers) vItem.toJson()]);

  /// Ajoute un projet au parcours ; avec [pToProjectVersions], il rejoint les versions qui ont
  /// une section Projets.
  Future<void> addCvProject(CvProject pProject, {bool pToProjectVersions = true}) async {
    final vProfile = cvProfile;

    await savePreference(
      cvProfilePreference,
      CvProfile(
        contact: vProfile.contact,
        experiences: vProfile.experiences,
        education: vProfile.education,
        certifications: vProfile.certifications,
        projects: [...vProfile.projects, pProject],
        skills: vProfile.skills,
        languages: vProfile.languages,
        strengths: vProfile.strengths,
        interests: vProfile.interests,
      ).toJson(),
    );
    if (pToProjectVersions) {
      await saveCvVersions([
        for (final vVersion in cvVersions)
          vVersion.sections.contains(CvSection.projects)
              ? vVersion.copyWith(projectIds: [...vVersion.projectIds, pProject.id])
              : vVersion,
      ]);
    }
  }

  /// Ajoute une habilitation ; les versions qui n'avaient pas la section la reçoivent.
  Future<void> addCvCertification(CvCertification pCertification) async {
    final vProfile = cvProfile;

    await savePreference(
      cvProfilePreference,
      CvProfile(
        contact: vProfile.contact,
        experiences: vProfile.experiences,
        education: vProfile.education,
        certifications: [...vProfile.certifications, pCertification],
        projects: vProfile.projects,
        skills: vProfile.skills,
        languages: vProfile.languages,
        strengths: vProfile.strengths,
        interests: vProfile.interests,
      ).toJson(),
    );
    await saveCvVersions([
      for (final vVersion in cvVersions)
        vVersion.sections.contains(CvSection.certifications)
            ? vVersion
            : vVersion.copyWith(
                sections: [
                  for (final vSection in CvSection.values)
                    if (vSection == CvSection.certifications ||
                        vVersion.sections.contains(vSection))
                      vSection,
                ],
              ),
    ]);
  }

  /// Identifiant neuf pour un projet ou une habilitation.
  String newCvId() => const Uuid().v4();
}
