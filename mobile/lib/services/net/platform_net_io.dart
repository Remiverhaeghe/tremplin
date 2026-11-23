// Réseau sur Android : certificat épinglé, sondage du Wi-Fi et adresses locales.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// La recherche du PC sur le Wi-Fi est possible.
const canScanNetwork = true;

/// Client qui n'accepte un certificat sans autorité que s'il passe [pAccept] ; appelé
/// seulement pour un certificat qu'aucune autorité ne garantit, comme celui créé sur le PC.
http.Client certificateClient(bool Function(List<int> pDer) pAccept, {Duration? pConnect}) =>
    IOClient(
      HttpClient()
        ..connectionTimeout = pConnect
        ..badCertificateCallback = (pCertificate, _, __) => pAccept(pCertificate.der),
    );

/// Adresses IPv4 du téléphone sur ses réseaux.
Future<List<String>> localAddresses() async => [
      for (final vInterface in await NetworkInterface.list(type: InternetAddressType.IPv4))
        for (final vAddress in vInterface.addresses) vAddress.address,
    ];
