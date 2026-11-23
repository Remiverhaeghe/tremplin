// Rendu « visuel » du PDF : en-tête avec photo ronde et pastilles de contact, titres de section
// sur bandeau, frise verticale pour le parcours, compétences en couleur avec étoiles. Tout est
// dessiné en vecteurs autour du texte, qui reste le même que dans le PDF sobre.

part of 'cv_pdf.dart';

/// Couleurs des familles de compétences, reprises dans l'ordre.
const _palette = <int>[0x008BB5, 0x3A8D3A, 0xF28C28, 0xE53935, 0x6A20C9, 0x7B2C5B];

/// Étoile à cinq branches : sommets extérieurs et intérieurs, en rayons de 1 (y vers le bas).
const _star = <(double, double)>[
  (0.0, -1.0), (0.2351, -0.3236), (0.9511, -0.3090), (0.3804, 0.1236), (0.5878, 0.8090), //
  (0.0, 0.4), (-0.5878, 0.8090), (-0.3804, 0.1236), (-0.9511, -0.3090), (-0.2351, -0.3236),
];

/// Photo JPEG lue : octets et dimensions, pour l'image du PDF.
class _Photo {
  _Photo(this.bytes, this.width, this.height);

  final List<int> bytes;
  final int width;
  final int height;

  static _Photo? tryRead(List<int> pBytes) {
    var vAt = 2;

    while (vAt + 9 < pBytes.length) {
      if (pBytes[vAt] != 0xFF) {
        return null;
      }
      final vMarker = pBytes[vAt + 1];
      final vLength = (pBytes[vAt + 2] << 8) | pBytes[vAt + 3];

      if (vMarker >= 0xC0 && vMarker <= 0xC2) {
        final vHeight = (pBytes[vAt + 5] << 8) | pBytes[vAt + 6];
        final vWidth = (pBytes[vAt + 7] << 8) | pBytes[vAt + 8];

        return vWidth > 0 && vHeight > 0 ? _Photo(pBytes, vWidth, vHeight) : null;
      }
      vAt += 2 + vLength;
    }

    return null;
  }
}

int _tint(int pRgb, [double pShare = 0.12]) {
  int mix(int pShift) {
    final vPart = (pRgb >> pShift) & 0xFF;

    return (255 - (255 - vPart) * pShare).round();
  }

  return (mix(16) << 16) | (mix(8) << 8) | mix(0);
}

extension _Visual on _Painter {
  String _pt(double pX, double pYTop) => '${_number(pX)} ${_number(_pageHeight - pYTop)}';

  void fillRect(double pX, double pTop, double pWidth, double pHeight, int pRgb) {
    page.writeln('${_color(pRgb)} rg ${_pt(pX, pTop + pHeight)} ${_number(pWidth)} '
        '${_number(pHeight)} re f');
  }

  String _circlePath(double pCx, double pCy, double pRadius) {
    const vK = 0.5523;
    final vC = pRadius * vK;
    final vY = _pageHeight - pCy;

    return '${_number(pCx + pRadius)} ${_number(vY)} m '
        '${_number(pCx + pRadius)} ${_number(vY + vC)} ${_number(pCx + vC)} '
        '${_number(vY + pRadius)} ${_number(pCx)} ${_number(vY + pRadius)} c '
        '${_number(pCx - vC)} ${_number(vY + pRadius)} ${_number(pCx - pRadius)} '
        '${_number(vY + vC)} ${_number(pCx - pRadius)} ${_number(vY)} c '
        '${_number(pCx - pRadius)} ${_number(vY - vC)} ${_number(pCx - vC)} '
        '${_number(vY - pRadius)} ${_number(pCx)} ${_number(vY - pRadius)} c '
        '${_number(pCx + vC)} ${_number(vY - pRadius)} ${_number(pCx + pRadius)} '
        '${_number(vY - vC)} ${_number(pCx + pRadius)} ${_number(vY)} c';
  }

  void fillCircle(double pCx, double pCy, double pRadius, int pRgb) {
    page.writeln('${_color(pRgb)} rg ${_circlePath(pCx, pCy, pRadius)} f');
  }

  void strokeLine(double pX1, double pY1, double pX2, double pY2, int pRgb, double pWidth) {
    page.writeln('${_color(pRgb)} RG ${_number(pWidth)} w ${_pt(pX1, pY1)} m '
        '${_pt(pX2, pY2)} l S');
  }

  void drawStar(double pCx, double pCy, double pRadius, int pRgb) {
    final vPath = StringBuffer();

    for (var vIndex = 0; vIndex < _star.length; vIndex++) {
      final vPoint = _star[vIndex];

      vPath.write('${_pt(pCx + vPoint.$1 * pRadius, pCy + vPoint.$2 * pRadius)} '
          '${vIndex == 0 ? 'm' : 'l'} ');
    }
    page.writeln('${_color(pRgb)} rg $vPath h f');
  }

  /// Cinq étoiles, `pLevel` pleines, alignées à droite sur la ligne qui commence à `top`.
  void stars(int pLevel, double pLineHeight) {
    const vRadius = 5.0;
    const vStep = 12.5;
    final vFirst = right - 4 * vStep - vRadius;

    for (var vIndex = 0; vIndex < 5; vIndex++) {
      drawStar(
        vFirst + vIndex * vStep,
        top + pLineHeight / 2,
        vRadius,
        vIndex < pLevel ? 0xF5A623 : 0xD9DEE3,
      );
    }
  }

  /// Pastille ronde avec un signe blanc : courriel, téléphone, lieu ou autre.
  void icon(String pLine, double pCx, double pCy) {
    fillCircle(pCx, pCy, 6.2, accent);
    final vPlain = pLine.trim();

    if (vPlain.contains('@')) {
      fillRect(pCx - 3.4, pCy - 2.3, 6.8, 4.6, 0xFFFFFF);
      strokeLine(pCx - 3.4, pCy - 2.3, pCx, pCy + 0.4, accent, 0.7);
      strokeLine(pCx + 3.4, pCy - 2.3, pCx, pCy + 0.4, accent, 0.7);
    } else if (RegExp(r'^[+\d\s().-]{6,}$').hasMatch(vPlain)) {
      fillRect(pCx - 1.9, pCy - 3.4, 3.8, 6.8, 0xFFFFFF);
      fillRect(pCx - 1.2, pCy - 2.6, 2.4, 4.0, accent);
    } else {
      fillCircle(pCx, pCy - 0.8, 2.1, 0xFFFFFF);
      page.writeln('1 1 1 rg ${_pt(pCx - 1.7, pCy + 0.2)} m ${_pt(pCx + 1.7, pCy + 0.2)} l '
          '${_pt(pCx, pCy + 3.6)} l h f');
    }
  }

  /// En-tête : photo ronde à gauche si elle existe, nom, poste, puis les coordonnées en pastilles.
  void header(CvDocument pDocument) {
    const vRadius = 40.0;
    final vPhoto = photo;
    final vOffset = vPhoto == null ? 0.0 : 100.0;
    final vStart = top;

    if (vPhoto != null) {
      final vCx = _marginSide + vRadius;
      final vCy = vStart + vRadius + 2;
      final vScale = 2 * vRadius / (vPhoto.width < vPhoto.height ? vPhoto.width : vPhoto.height);
      final vWidth = vPhoto.width * vScale;
      final vHeight = vPhoto.height * vScale;

      page.writeln('q ${_circlePath(vCx, vCy, vRadius)} W n '
          '${_number(vWidth)} 0 0 ${_number(vHeight)} ${_number(vCx - vWidth / 2)} '
          '${_number(_pageHeight - vCy - vHeight / 2)} cm /Im1 Do Q');
      page.writeln('${_color(accent)} RG 3 w ${_circlePath(vCx, vCy, vRadius + 1.5)} S');
    }
    top = vStart + (vPhoto == null ? 0 : 10);
    for (final vLine in cvWrap(pDocument.name, textWidth - vOffset, pSize: 24, pBold: true)) {
      text(vLine, pSize: 24, pX: _marginSide + vOffset, pBold: true);
      top += 29;
    }
    for (final vLine in cvWrap(pDocument.headline, textWidth - vOffset, pSize: 12.5, pBold: true)) {
      text(vLine, pSize: 12.5, pX: _marginSide + vOffset, pBold: true, pRgb: accent);
      top += 16;
    }
    top = vPhoto == null ? top + 4 : vStart + 2 * vRadius + 14;

    var vX = _marginSide;
    for (final vLine in pDocument.contactLines) {
      final vWidth = cvTextWidth(vLine, pSize: 9.5) + 26;

      if (vX + vWidth > right + 4 && vX > _marginSide) {
        vX = _marginSide;
        top += 17;
      }
      icon(vLine, vX + 6.2, top + 6);
      text(vLine, pSize: 9.5, pX: vX + 16, pRgb: 0x26323B);
      vX += vWidth;
    }
    top += 20;
  }

  /// Titre de section sur un bandeau teinté, avec une barre de couleur à gauche.
  void band(String pHeading) {
    ensure(40);
    top += 6;
    fillRect(_marginSide, top, textWidth, 20, _tint(accent));
    fillRect(_marginSide, top, 4, 20, accent);
    top += 4.5;
    text(pHeading, pSize: 11.5, pX: _marginSide + 12, pBold: true, pRgb: accent);
    top += 21.5;
  }

  /// Frise verticale du parcours : un trait et un point par bloc, sur la marge.
  void timeline(int pPage, double pFromTop, double pToTop) {
    const vX = _marginSide - 14;
    final vSaved = pages.length - 1;

    if (pPage == vSaved) {
      strokeLine(vX, pFromTop + 5, vX, pToTop - 4, _tint(accent, 0.45), 1.2);
    } else {
      pages[pPage].writeln('${_color(_tint(accent, 0.45))} RG 1.2 w '
          '${_pt(vX, pFromTop + 5)} m ${_pt(vX, _pageHeight - _marginBottom)} l S');
      strokeLine(vX, _marginTop, vX, pToTop - 4, _tint(accent, 0.45), 1.2);
    }
  }

  void timelineDot(double pTop) => fillCircle(_marginSide - 14, pTop + 5.5, 3.4, accent);
}
