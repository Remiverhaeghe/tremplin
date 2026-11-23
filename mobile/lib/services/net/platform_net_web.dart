// Réseau dans le navigateur : il garde la main sur les certificats et ne montre pas les
// adresses du réseau local.

import 'package:http/http.dart' as http;

/// Le navigateur ne peut pas sonder le Wi-Fi : l'adresse du PC se tape ou se scanne.
const canScanNetwork = false;

/// Le navigateur vérifie lui-même les certificats : un certificat auto-signé doit d'abord
/// être accepté dans Safari ou Chrome, l'épinglage ne s'applique pas.
http.Client certificateClient(bool Function(List<int> pDer) pAccept, {Duration? pConnect}) =>
    http.Client();

/// Aucune adresse locale visible depuis le navigateur.
Future<List<String>> localAddresses() async => const [];
