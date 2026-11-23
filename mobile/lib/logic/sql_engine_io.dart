// Exécution SQL sur le téléphone : SQLite dans un isolat, arrêté au bout du délai.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import 'sql_sandbox.dart';

/// Fonctions SQL ajoutées, selon le dialecte, comme open_database côté PC.
void registerFunctions(Database pDatabase, String pDialect) {
  void add(String pName, int pCount, Object? Function(List<Object?>) pFunction,
      {bool pDeterministic = true}) {
    pDatabase.createFunction(
      functionName: pName,
      argumentCount: AllowedArgumentCount(pCount),
      deterministic: pDeterministic,
      directOnly: false,
      function: (pArguments) =>
          pFunction([for (var vIndex = 0; vIndex < pCount; vIndex++) pArguments[vIndex]]),
    );
  }

  add('YEAR', 1, (pArgs) => pArgs[0] == null ? null : parseMoment(pArgs[0]!).year);
  add('MONTH', 1, (pArgs) => pArgs[0] == null ? null : parseMoment(pArgs[0]!).month);
  add('DAY', 1, (pArgs) => pArgs[0] == null ? null : parseMoment(pArgs[0]!).day);

  if (pDialect == 'mysql') {
    add(
      'DATEDIFF',
      2,
      (pArgs) => pArgs[0] == null || pArgs[1] == null
          ? null
          : daysBetween(parseMoment(pArgs[1]!), parseMoment(pArgs[0]!)),
    );
    add(
      'timestamp_diff',
      3,
      (pArgs) => pArgs[1] == null || pArgs[2] == null
          ? null
          : (secondsBetween(parseMoment(pArgs[1]!), parseMoment(pArgs[2]!)) /
                  unitSeconds[pArgs[0]]!)
              .truncate(),
      pDeterministic: false,
    );
    add('mysql_isnull', 1, (pArgs) => pArgs[0] == null ? 1 : 0);
  } else {
    add(
      'boundary_diff',
      3,
      (pArgs) {
        if (pArgs[1] == null || pArgs[2] == null) {
          return null;
        }

        final vStart = parseMoment(pArgs[1]!);
        final vEnd = parseMoment(pArgs[2]!);
        final vUnit = pArgs[0] as String;

        if (vUnit == 'day') {
          return daysBetween(vStart, vEnd);
        }

        DateTime cut(DateTime pMoment) => DateTime.utc(
              pMoment.year,
              pMoment.month,
              pMoment.day,
              pMoment.hour,
              vUnit == 'hour' ? 0 : pMoment.minute,
            );

        return (secondsBetween(cut(vStart), cut(vEnd)) / unitSeconds[vUnit]!).floor();
      },
      pDeterministic: false,
    );
  }
}

/// Lit au plus pMaxRows lignes d'un curseur ; erreur si une valeur dépasse la limite du PC.
Map<String, Object?> fetchRows(IteratingCursor pCursor, int pMaxRows, int pMaxValueLength) {
  final vRows = <List<Object?>>[];
  var vTruncated = false;

  while (pCursor.moveNext()) {
    if (vRows.length == pMaxRows) {
      vTruncated = true;
      break;
    }

    final vValues = pCursor.current.values;

    for (final vValue in vValues) {
      final vLength =
          vValue is String ? utf8.encode(vValue).length : (vValue is Uint8List ? vValue.length : 0);

      if (vLength > pMaxValueLength) {
        throw SqliteException(extendedResultCode: 18, message: 'string or blob too big');
      }
    }

    vRows.add(List<Object?>.from(vValues));
  }

  return {
    'columns': List<String>.from(pCursor.columnNames),
    'rows': vRows,
    'truncated': vTruncated
  };
}

/// Exécution dans l'isolat : base neuve, requête, contrôle ; renvoie le résultat brut.
void _runInIsolate(List<Object?> pMessage) {
  final vPort = pMessage[0] as SendPort;
  final vResult = <String, Object?>{
    'columns': <String>[],
    'rows': <List<Object?>>[],
    'truncated': false,
    'changed': null
  };
  final vDatabase = sqlite3.openInMemory();

  try {
    vDatabase.execute(pMessage[1] as String);
    registerFunctions(vDatabase, pMessage[3] as String);

    final vStatement = vDatabase.prepare(pMessage[2] as String);

    try {
      final vCursor = vStatement.selectCursor();

      if (vCursor.columnNames.isEmpty) {
        while (vCursor.moveNext()) {}
        vResult['changed'] = vDatabase.updatedRows;
      } else {
        vResult.addAll(fetchRows(vCursor, pMessage[5] as int, pMessage[6] as int));
      }
    } finally {
      vStatement.close();
    }

    final vCheck = pMessage[4] as String;

    if (vCheck.isNotEmpty) {
      final vCheckStatement = vDatabase.prepare(vCheck);

      try {
        vResult.addAll(
            fetchRows(vCheckStatement.selectCursor(), pMessage[5] as int, pMessage[6] as int));
      } finally {
        vCheckStatement.close();
      }
    }
  } on SqliteException catch (vError) {
    vResult['raw_error'] = vError.message;
  } finally {
    vDatabase.close();
  }

  Isolate.exit(vPort, vResult);
}

/// Lance la requête dans un isolat ; [pMessage] tient le script, la requête, le dialecte, le
/// contrôle et les limites. Renvoie le résultat brut, ou null si le délai est dépassé.
Future<Map<String, Object?>?> runIsolated(List<Object?> pMessage, Duration pTimeout) async {
  final vPort = ReceivePort();
  final vIsolate = await Isolate.spawn(_runInIsolate, [vPort.sendPort, ...pMessage]);
  Map<String, Object?>? rRaw;

  try {
    rRaw = Map<String, Object?>.from(await vPort.first.timeout(pTimeout) as Map);
  } on TimeoutException {
    vIsolate.kill(priority: Isolate.immediate);
  } finally {
    vPort.close();
  }

  return rRaw;
}
