// Test d'intégration avec le vrai serveur : pas de liaison de test, qui remplacerait le
// réseau par des réponses 400. Ce fichier, plus proche, prend la place de celui de test/.

import 'dart:async';

Future<void> testExecutable(FutureOr<void> Function() pTestMain) async => pTestMain();
