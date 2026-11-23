// CV en PDF, écrit à la main : polices standard du PDF (Helvetica) et vrai texte, sans image de
// texte, pour que les logiciels de tri le lisent dans l'ordre. Deux rendus du même document :
// « sobre » (noir sur blanc, pour les formulaires et les logiciels de tri) et « visuel »
// (bandeau d'en-tête et titres de section en couleur, pour l'envoi par courriel).

import 'dart:convert';
import 'dart:typed_data';

import 'cv_document.dart';
import 'cv_version.dart';

enum CvPdfStyle { plain, visual }

const _pageWidth = 595.28;
const _pageHeight = 841.89;
const _marginSide = 50.0;
const _marginTop = 52.0;
const _marginBottom = 48.0;
const _bandHeight = 96.0;

/// Largeurs Helvetica des caractères 32 à 126, en millièmes de corps.
const _regularWidths = <int>[
  278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278, //
  556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
  1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
  667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
  333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
  556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584,
];

/// Largeurs Helvetica-Bold des caractères 32 à 126.
const _boldWidths = <int>[
  278, 333, 474, 556, 556, 889, 722, 238, 333, 333, 389, 584, 278, 333, 278, 278, //
  556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 333, 333, 584, 584, 584, 611,
  975, 722, 722, 722, 722, 667, 611, 778, 722, 278, 556, 722, 611, 833, 722, 778,
  667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 333, 278, 333, 584, 556,
  333, 556, 611, 556, 611, 556, 333, 611, 611, 278, 278, 556, 278, 889, 611, 611,
  611, 611, 389, 556, 333, 611, 556, 778, 556, 556, 500, 389, 280, 389, 584,
];

const _folded = {
  'àáâãäå': 'a',
  'ç': 'c',
  'èéêë': 'e',
  'ìíîï': 'i',
  'ñ': 'n',
  'òóôõö': 'o',
  'ùúûü': 'u',
  'ýÿ': 'y',
  'ÀÁÂÃÄÅ': 'A',
  'Ç': 'C',
  'ÈÉÊË': 'E',
  'ÌÍÎÏ': 'I',
  'Ñ': 'N',
  'ÒÓÔÕÖ': 'O',
  'ÙÚÛÜ': 'U',
};

/// Octet de la table Windows-1252 pour les signes hors du Latin-1.
const _windows1252 = {
  0x20AC: 0x80, // €
  0x2026: 0x85, // …
  0x2018: 0x91, // ‘
  0x2019: 0x92, // ’
  0x201C: 0x93, // “
  0x201D: 0x94, // ”
  0x2022: 0x95, // •
  0x2013: 0x96, // –
  0x2014: 0x97, // —
  0x0152: 0x8C, // Œ
  0x0153: 0x9C, // œ
};

/// Texte en octets Windows-1252 (un caractère par unité), tel que le PDF le lit.
String cvPdfEncode(String pText) {
  final rText = StringBuffer();
  for (final vRune in pText.runes) {
    if (vRune == 0x202F || vRune == 0x00A0) {
      rText.writeCharCode(0x20);
    } else if (vRune >= 0x20 && vRune <= 0x7E || vRune >= 0xA1 && vRune <= 0xFF) {
      rText.writeCharCode(vRune);
    } else if (_windows1252[vRune] case final vCode?) {
      rText.writeCharCode(vCode);
    } else if (vRune == 0x09 || vRune == 0x0A) {
      rText.writeCharCode(0x20);
    } else {
      rText.write('?');
    }
  }

  return rText.toString();
}

String _escape(String pEncoded) =>
    pEncoded.replaceAll(r'\', r'\\').replaceAll('(', r'\(').replaceAll(')', r'\)');

String _fold(String pChar) {
  for (final vEntry in _folded.entries) {
    if (vEntry.key.contains(pChar)) {
      return vEntry.value;
    }
  }

  return pChar;
}

/// Largeur d'un texte en points, au corps donné.
double cvTextWidth(String pText, {required double pSize, bool pBold = false}) {
  final vWidths = pBold ? _boldWidths : _regularWidths;
  var vTotal = 0;
  for (final vChar in pText.split('')) {
    final vFolded = _fold(vChar);
    final vCode = vFolded.codeUnitAt(0);
    vTotal += vCode >= 32 && vCode <= 126
        ? vWidths[vCode - 32]
        : switch (vChar) {
            '’' || '‘' => 222,
            '–' || '•' => 556,
            '—' => 1000,
            'œ' || 'Œ' => 889,
            _ => 556,
          };
  }

  return vTotal * pSize / 1000;
}

/// Coupe un texte en lignes qui tiennent dans la largeur ; un mot trop long est coupé.
List<String> cvWrap(String pText, double pWidth, {required double pSize, bool pBold = false}) {
  double width(String pPart) => cvTextWidth(pPart, pSize: pSize, pBold: pBold);

  final rLines = <String>[];
  var vLine = '';
  for (final vWord in pText.split(RegExp(r'\s+')).where((pWord) => pWord.isNotEmpty)) {
    var vRest = vWord;
    while (width(vRest) > pWidth) {
      var vCut = vRest.length - 1;
      while (vCut > 1 && width(vRest.substring(0, vCut)) > pWidth) {
        vCut--;
      }
      if (vLine.isNotEmpty) {
        rLines.add(vLine);
        vLine = '';
      }
      rLines.add(vRest.substring(0, vCut));
      vRest = vRest.substring(vCut);
    }
    final vTry = vLine.isEmpty ? vRest : '$vLine $vRest';
    if (width(vTry) <= pWidth) {
      vLine = vTry;
    } else {
      rLines.add(vLine);
      vLine = vRest;
    }
  }
  if (vLine.isNotEmpty) {
    rLines.add(vLine);
  }

  return rLines;
}

String _number(double pValue) => pValue.toStringAsFixed(2);

String _color(int pRgb) {
  final vRed = (pRgb >> 16) & 0xFF;
  final vGreen = (pRgb >> 8) & 0xFF;
  final vBlue = pRgb & 0xFF;

  return '${_number(vRed / 255)} ${_number(vGreen / 255)} ${_number(vBlue / 255)}';
}

/// Dessine les pages une à une : un curseur descend, une page est ajoutée quand elle est pleine.
class _Painter {
  _Painter(this.style, this.accent);

  final CvPdfStyle style;
  final int accent;
  final pages = <StringBuffer>[StringBuffer()];
  double top = _marginTop;

  bool get visual => style == CvPdfStyle.visual;

  StringBuffer get page => pages.last;

  double get right => _pageWidth - _marginSide;

  double get textWidth => right - _marginSide;

  void ensure(double pHeight) {
    if (top + pHeight > _pageHeight - _marginBottom) {
      pages.add(StringBuffer());
      top = _marginTop;
    }
  }

  void text(
    String pText, {
    required double pSize,
    double pX = _marginSide,
    bool pBold = false,
    int pRgb = 0x1A1A1A,
  }) {
    final vY = _pageHeight - top - pSize;
    page.writeln('BT /${pBold ? 'F2' : 'F1'} ${_number(pSize)} Tf ${_color(pRgb)} rg '
        '${_number(pX)} ${_number(vY)} Td (${_escape(cvPdfEncode(pText))}) Tj ET');
  }

  /// Paragraphe coupé à la largeur, avec un retrait pour les puces.
  void paragraph(
    String pText, {
    double pSize = 10,
    bool pBold = false,
    int pRgb = 0x1A1A1A,
    double pIndent = 0,
    String pBullet = '',
    double pAfter = 2,
  }) {
    final vLead = pSize * 1.35;
    final vLines = cvWrap(pText, textWidth - pIndent, pSize: pSize, pBold: pBold);
    for (var vIndex = 0; vIndex < vLines.length; vIndex++) {
      ensure(vLead);
      if (vIndex == 0 && pBullet.isNotEmpty) {
        text(pBullet, pSize: pSize, pX: _marginSide + pIndent - 9, pRgb: pRgb);
      }
      text(vLines[vIndex], pSize: pSize, pX: _marginSide + pIndent, pBold: pBold, pRgb: pRgb);
      top += vLead;
    }
    top += pAfter;
  }

  /// « Libellé : texte » avec le libellé en gras, sur la même ligne.
  void labelled(String pLabel, String pText, {double pSize = 10}) {
    final vLead = pSize * 1.35;
    final vLabel = '$pLabel : ';
    final vLabelWidth = cvTextWidth(vLabel, pSize: pSize, pBold: true);
    final vWords = pText.split(RegExp(r'\s+')).where((pWord) => pWord.isNotEmpty).toList();
    var vFirst = true;
    var vLine = '';
    final vParts = <(String, bool)>[];
    for (final vWord in vWords) {
      final vTry = vLine.isEmpty ? vWord : '$vLine $vWord';
      final vRoom = vFirst ? textWidth - vLabelWidth : textWidth;
      if (cvTextWidth(vTry, pSize: pSize) <= vRoom) {
        vLine = vTry;
      } else {
        vParts.add((vLine, vFirst));
        vFirst = false;
        vLine = vWord;
      }
    }
    vParts.add((vLine, vFirst));
    for (final vPart in vParts) {
      ensure(vLead);
      if (vPart.$2) {
        text(vLabel, pSize: pSize, pBold: true);
        text(vPart.$1, pSize: pSize, pX: _marginSide + vLabelWidth);
      } else {
        text(vPart.$1, pSize: pSize);
      }
      top += vLead;
    }
    top += 2;
  }

  void rule(int pRgb, double pWidth) {
    final vY = _pageHeight - top;
    page.writeln('${_color(pRgb)} RG ${_number(pWidth)} w '
        '${_number(_marginSide)} ${_number(vY)} m ${_number(right)} ${_number(vY)} l S');
  }
}

String _pdfString(String pText) => '(${_escape(cvPdfEncode(pText))})';

/// Le PDF du document, prêt à écrire dans un fichier.
Uint8List buildCvPdf(
  CvDocument pDocument, {
  CvPdfStyle pStyle = CvPdfStyle.plain,
  int pAccent = 0x1F5F8B,
}) {
  final vPainter = _Painter(pStyle, pAccent);

  if (vPainter.visual) {
    vPainter.page.writeln('${_color(pAccent)} rg 0 ${_number(_pageHeight - _bandHeight)} '
        '${_number(_pageWidth)} ${_number(_bandHeight)} re f');
    vPainter.top = 28;
    vPainter.text(pDocument.name, pSize: 24, pBold: true, pRgb: 0xFFFFFF);
    vPainter.top += 30;
    if (pDocument.headline.isNotEmpty) {
      vPainter.text(pDocument.headline, pSize: 12.5, pRgb: 0xFFFFFF);
    }
    vPainter.top = _bandHeight + 16;
  } else {
    vPainter.paragraph(pDocument.name, pSize: 22, pBold: true, pAfter: 1);
    if (pDocument.headline.isNotEmpty) {
      vPainter.paragraph(pDocument.headline, pSize: 12.5, pAfter: 2);
    }
  }
  if (pDocument.contactLines.isNotEmpty) {
    vPainter.paragraph(pDocument.contactLines.join('   |   '),
        pSize: 9.5, pRgb: vPainter.visual ? 0x44505A : 0x1A1A1A, pAfter: 6);
  }

  for (final vSection in pDocument.sections) {
    vPainter
      ..top += 6
      ..ensure(40)
      ..paragraph(vSection.heading,
          pSize: 12, pBold: true, pRgb: vPainter.visual ? pAccent : 0x1A1A1A, pAfter: 0);
    vPainter
      ..top -= 2
      ..rule(vPainter.visual ? pAccent : 0x1A1A1A, vPainter.visual ? 0.9 : 0.5)
      ..top += 6;
    for (final vBlock in vSection.blocks) {
      _block(vPainter, vSection.section, vBlock);
    }
  }

  return _assemble(vPainter.pages, pDocument);
}

void _block(_Painter pPainter, CvSection pSection, CvBlock pBlock) {
  final vMuted = pPainter.visual ? 0x44505A : 0x1A1A1A;
  switch (pSection) {
    case CvSection.skills when pBlock.title.isNotEmpty:
    case CvSection.languages when pBlock.title.isNotEmpty:
      pPainter.labelled(pBlock.title, pBlock.lines.join(', '));
    case CvSection.summary:
    case CvSection.interests:
      for (final vLine in pBlock.lines) {
        pPainter.paragraph(vLine, pAfter: 3);
      }
    case CvSection.strengths:
      for (final vLine in pBlock.lines) {
        pPainter.paragraph(vLine, pIndent: 12, pBullet: '•', pAfter: 1);
      }
    default:
      pPainter.ensure(40);
      if (pBlock.title.isNotEmpty) {
        pPainter.paragraph(pBlock.title, pBold: true, pSize: 10.5, pAfter: 0);
      }
      final vSub = [pBlock.detail, pBlock.dates].where((pPart) => pPart.isNotEmpty).join('   |   ');
      if (vSub.isNotEmpty) {
        pPainter.paragraph(vSub, pSize: 9.5, pRgb: vMuted, pAfter: 1);
      }
      for (final vLine in pBlock.lines) {
        pPainter.paragraph(vLine, pIndent: 12, pBullet: '•', pAfter: 1);
      }
      pPainter.top += 5;
  }
}

Uint8List _assemble(List<StringBuffer> pPages, CvDocument pDocument) {
  final vObjects = <String>[];
  final vFirstPage = 6;
  final vKids = [
    for (var vIndex = 0; vIndex < pPages.length; vIndex++) '${vFirstPage + vIndex * 2} 0 R'
  ];

  vObjects
    ..add('<< /Type /Catalog /Pages 2 0 R /Lang (fr-FR) >>')
    ..add('<< /Type /Pages /Kids [${vKids.join(' ')}] /Count ${pPages.length} >>')
    ..add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>')
    ..add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>')
    ..add('<< /Title ${_pdfString('CV ${pDocument.name}')} /Author ${_pdfString(pDocument.name)} '
        '/Subject ${_pdfString(pDocument.headline)} >>');
  for (var vIndex = 0; vIndex < pPages.length; vIndex++) {
    final vContent = pPages[vIndex].toString();
    vObjects
      ..add('<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${_number(_pageWidth)} '
          '${_number(_pageHeight)}] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
          '/Contents ${vFirstPage + vIndex * 2 + 1} 0 R >>')
      ..add('<< /Length ${vContent.length} >>\nstream\n$vContent\nendstream');
  }

  final vFile = StringBuffer('%PDF-1.4\n');
  final vOffsets = <int>[];
  for (var vIndex = 0; vIndex < vObjects.length; vIndex++) {
    vOffsets.add(vFile.length);
    vFile.write('${vIndex + 1} 0 obj\n${vObjects[vIndex]}\nendobj\n');
  }
  final vXref = vFile.length;
  vFile.write('xref\n0 ${vObjects.length + 1}\n0000000000 65535 f \n');
  for (final vOffset in vOffsets) {
    vFile.write('${vOffset.toString().padLeft(10, '0')} 00000 n \n');
  }
  vFile.write('trailer\n<< /Size ${vObjects.length + 1} /Root 1 0 R /Info 5 0 R >>\n'
      'startxref\n$vXref\n%%EOF\n');

  return Uint8List.fromList(latin1.encode(vFile.toString()));
}
