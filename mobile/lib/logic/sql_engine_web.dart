// Version web : pas de SQLite dans le navigateur, le bac à sable reste sur Android.

/// Répond sans exécuter : la requête demande l'application Android.
Future<Map<String, Object?>?> runIsolated(List<Object?> pMessage, Duration pTimeout) async => {
      'columns': <String>[],
      'rows': <List<Object?>>[],
      'truncated': false,
      'changed': null,
      'unavailable': true,
    };
