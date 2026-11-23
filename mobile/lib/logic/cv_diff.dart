// Avant / après : ce que l'adaptation à une offre change dans le CV, ligne par ligne.

enum CvDiffKind { same, removed, added }

typedef CvDiffLine = ({CvDiffKind kind, String text});

/// Différence ligne à ligne (plus longue sous-suite commune), lignes vides ignorées.
List<CvDiffLine> diffLines(String pBefore, String pAfter) {
  final vA = [for (final vLine in pBefore.split('\n')) if (vLine.trim().isNotEmpty) vLine.trimRight()];
  final vB = [for (final vLine in pAfter.split('\n')) if (vLine.trim().isNotEmpty) vLine.trimRight()];
  final vTable = List.generate(vA.length + 1, (_) => List.filled(vB.length + 1, 0));

  for (var vI = vA.length - 1; vI >= 0; vI--) {
    for (var vJ = vB.length - 1; vJ >= 0; vJ--) {
      vTable[vI][vJ] = vA[vI] == vB[vJ]
          ? vTable[vI + 1][vJ + 1] + 1
          : vTable[vI + 1][vJ] >= vTable[vI][vJ + 1]
              ? vTable[vI + 1][vJ]
              : vTable[vI][vJ + 1];
    }
  }

  final rLines = <CvDiffLine>[];
  var vI = 0;
  var vJ = 0;
  while (vI < vA.length && vJ < vB.length) {
    if (vA[vI] == vB[vJ]) {
      rLines.add((kind: CvDiffKind.same, text: vA[vI]));
      vI++;
      vJ++;
    } else if (vTable[vI + 1][vJ] >= vTable[vI][vJ + 1]) {
      rLines.add((kind: CvDiffKind.removed, text: vA[vI++]));
    } else {
      rLines.add((kind: CvDiffKind.added, text: vB[vJ++]));
    }
  }
  while (vI < vA.length) {
    rLines.add((kind: CvDiffKind.removed, text: vA[vI++]));
  }
  while (vJ < vB.length) {
    rLines.add((kind: CvDiffKind.added, text: vB[vJ++]));
  }

  return rLines;
}
