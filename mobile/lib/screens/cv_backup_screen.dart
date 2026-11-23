// Sauvegarde et restauration chiffrées du CV : un texte chiffré par un mot de passe, partagé comme
// un fichier ou collé pour restaurer.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/texts.dart';
import '../logic/cv_dossier.dart';
import '../revision_state.dart';
import '../services/file_sender.dart';

class CvBackupScreen extends StatefulWidget {
  const CvBackupScreen({super.key, required this.state, this.send = shareFile});

  final RevisionState state;
  final FileSender send;

  @override
  State<CvBackupScreen> createState() => _CvBackupScreenState();
}

class _CvBackupScreenState extends State<CvBackupScreen> {
  static const aMinLength = 8;

  final aPassword = TextEditingController();
  final aSealed = TextEditingController();
  String aMessage = '';

  @override
  void dispose() {
    aPassword.dispose();
    aSealed.dispose();
    super.dispose();
  }

  Future<void> backup() async {
    final vTooShort = context.texts.cvMotDePasseCourt;

    if (aPassword.text.length < aMinLength) {
      setState(() => aMessage = vTooShort);
      return;
    }
    final vSealed = await widget.state.exportCvBackup(aPassword.text);

    await widget.send(Uint8List.fromList(utf8.encode(vSealed)), 'cv-sauvegarde.cvsave', mimeText);
  }

  Future<void> exportAll() async {
    final vText = buildDossier(
      pProfile: widget.state.cvProfile,
      pVersions: widget.state.cvVersions,
      pSent: widget.state.cvSent,
      pKit: widget.state.cvLetterKit,
      pAnswers: widget.state.cvAnswers,
      pNow: DateTime.now(),
    );

    await widget.send(Uint8List.fromList(utf8.encode(vText)), 'cv-dossier.txt', mimeText);
  }

  Future<void> restore() async {
    final vOk = context.texts.cvRestaureOk;
    final vNo = context.texts.cvRestaureNon;
    final vDone = await widget.state.importCvBackup(aSealed.text, aPassword.text);

    if (mounted) {
      setState(() => aMessage = vDone ? vOk : vNo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vTexts = context.texts;

    final rScreen = Scaffold(
      appBar: AppBar(title: Text(vTexts.cvSauvegarde)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vTexts.cvSauvegardeAide),
          const SizedBox(height: 12),
          TextField(
            controller: aPassword,
            obscureText: true,
            decoration: InputDecoration(labelText: vTexts.cvMotDePasse),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: backup, child: Text(vTexts.cvSauvegarder)),
          const SizedBox(height: 8),
          Text(vTexts.cvDossierAide),
          OutlinedButton(onPressed: exportAll, child: Text(vTexts.cvDossier)),
          const SizedBox(height: 24),
          TextField(
            controller: aSealed,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(labelText: vTexts.cvRestaurerColler),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: restore, child: Text(vTexts.cvRestaurer)),
          if (aMessage.isNotEmpty) ...[const SizedBox(height: 12), Text(aMessage)],
        ],
      ),
    );

    return rScreen;
  }
}
