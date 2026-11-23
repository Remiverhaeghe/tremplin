// Widget de l'écran d'accueil Android, par le paquet home_widget.

import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'home_widget_service.dart';

class AndroidHomeWidget implements HomeWidgetUpdater {
  @override
  Future<void> show((String, String) pLines) async {
    try {
      await HomeWidget.saveWidgetData<String>('due', pLines.$1);
      await HomeWidget.saveWidgetData<String>('next', pLines.$2);
      await HomeWidget.updateWidget(androidName: widgetProviderName);
    } on PlatformException catch (vException) {
      // Un widget indisponible n'empêche pas la synchronisation.
      log('Widget non mis à jour : ${vException.message}', name: 'widget');
    }
  }

  @override
  Stream<Uri?> launches() async* {
    try {
      yield await HomeWidget.initiallyLaunchedFromHomeWidget();
    } on PlatformException catch (vException) {
      log('Lancement du widget illisible : ${vException.message}', name: 'widget');
    }
    yield* HomeWidget.widgetClicked;
  }
}
