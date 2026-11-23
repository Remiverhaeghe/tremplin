// Ce que lit un logiciel de tri : on relit le PDF comme lui, par son texte, et on vérifie que
// chaque mot du CV s'y retrouve, accents compris.

import 'dart:convert';
import 'dart:typed_data';

import 'cv_check.dart';
import 'cv_document.dart';
import 'cv_pdf.dart';

/// Le texte du PDF, une ligne par commande d'écriture, dans l'ordre du fichier.
String pdfText(Uint8List pBytes) {
  final vFile = latin1.decode(pBytes);
  final rLines = <String>[];

  for (final vMatch in RegExp(r'\(((?:\\.|[^\\)])*)\) Tj').allMatches(vFile)) {
    final vRaw = vMatch.group(1)!.replaceAllMapped(RegExp(r'\\(.)'), (pPart) => pPart.group(1)!);
    rLines.add(cvPdfDecode(vRaw));
  }

  return rLines.join('\n');
}

typedef CvReadback = ({String text, List<String> missing});

/// Le texte lu et les mots du document qui n'y sont pas, par exemple un lien coupé en deux.
CvReadback atsReadback(CvDocument pDocument, Uint8List pBytes) {
  final vText = pdfText(pBytes);
  final vRead = cvPlain(vText);
  final vMissing = <String>{
    for (final vWord in cvPlain(pDocument.plainText).split(RegExp(r'\s+')))
      if (vWord.isNotEmpty && !vRead.contains(vWord)) vWord,
  };

  return (text: vText, missing: vMissing.toList());
}
