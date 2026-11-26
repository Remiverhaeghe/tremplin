// Rappels par notification locale d'Android et vérification des offres en arrière-plan.

import 'dart:developer';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../l10n/texts.dart';
import '../logic/interview_alerts.dart';
import 'reminders.dart';

class LocalReminders implements Reminders {
  final plugin = FlutterLocalNotificationsPlugin();
  bool initialized = false;

  Future<void> initialize() async {
    if (initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(
      tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier),
    );

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    final vGranted = await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final rGranted = vGranted ?? false;

    return rGranted;
  }

  @override
  Future<void> schedule(int pDueCount, {int pMissedCount = 0}) async {
    await initialize();

    final vNow = tz.TZDateTime.now(tz.local);
    var vNext = tz.TZDateTime(
      tz.local,
      vNow.year,
      vNow.month,
      vNow.day,
      reminderHour,
      reminderMinute,
    );

    if (!vNext.isAfter(vNow)) {
      vNext = vNext.add(const Duration(days: 1));
    }

    // Planification inexacte : Android regroupe le réveil avec d'autres, sans
    // permission d'alarme exacte, à quelques minutes près.
    await plugin.zonedSchedule(
      id: reminderId,
      scheduledDate: vNext,
      title: deviceTexts().reminderTitle,
      body: pMissedCount > 0
          ? deviceTexts().reminderMissed(pMissedCount, pDueCount)
          : (pDueCount > 0 ? deviceTexts().reminderDue(pDueCount) : deviceTexts().reminderNew),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'revision',
          deviceTexts().reminderChannel,
          channelDescription: deviceTexts().reminderChannelHelp,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    log('Rappel planifié à $reminderHour:$reminderMinute ($pDueCount à revoir, $pMissedCount ratées)',
        name: 'rappel');
  }

  @override
  Future<void> cancel() async {
    await initialize();
    await plugin.cancel(id: reminderId);
  }

  @override
  Future<void> showNewOffers(List<Map<String, dynamic>> pOffers) async {
    await initialize();

    final vText = deviceTexts();
    final vTitles = [for (final vOffer in pOffers.take(3)) vOffer['title'] ?? vText.offerUntitled];

    await plugin.show(
      id: offersNotificationId,
      title: vText.offersNotification(pOffers.length),
      body: vTitles.join(' · '),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'offers',
          vText.offersChannel,
          channelDescription: vText.offersChannelHelp,
        ),
      ),
    );

    log('Notification de ${pOffers.length} nouvelle(s) offre(s)', name: 'offres');
  }

  @override
  Future<void> showReplies(List<Map<String, dynamic>> pReplies) async {
    await initialize();

    await plugin.show(
      id: repliesNotificationId,
      title: deviceTexts().repliesNotification(pReplies.length),
      body: pReplies.take(3).map(describeReply).join(' · '),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'replies',
          deviceTexts().repliesChannel,
          channelDescription: deviceTexts().repliesChannelHelp,
        ),
      ),
    );

    log('Notification de ${pReplies.length} réponse(s) de recruteur', name: 'réponses');
  }

  @override
  Future<void> showWithdrawn(List<Map<String, dynamic>> pOffers) async {
    await initialize();

    await plugin.show(
      id: withdrawnNotificationId,
      title: deviceTexts().withdrawnNotification(pOffers.length),
      body: pOffers
          .take(3)
          .map((vOffer) => '${vOffer['title'] ?? deviceTexts().offerUntitled}')
          .join(' · '),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'withdrawn',
          deviceTexts().withdrawnChannel,
          channelDescription: deviceTexts().withdrawnChannelHelp,
        ),
      ),
    );

    log('Notification de ${pOffers.length} offre(s) retirée(s)', name: 'offres');
  }

  @override
  Future<void> showSeasonReview(Map<String, dynamic> pSeason) async {
    await initialize();

    await plugin.show(
      id: seasonNotificationId,
      title: deviceTexts().seasonNotification('${pSeason['title']}'),
      body: '${pSeason['summary']}',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'season',
          deviceTexts().seasonChannel,
          channelDescription: deviceTexts().seasonChannelHelp,
        ),
      ),
    );

    log('Notification du bilan ${pSeason['key']}', name: 'progression');
  }

  @override
  Future<void> scheduleInterviews(List<InterviewAlert> pAlerts) async {
    await initialize();

    // Un entretien déplacé ou annulé ne doit pas laisser d'ancien rappel.
    for (var vIndex = 0; vIndex < maxInterviewAlerts; vIndex++) {
      await plugin.cancel(id: firstInterviewAlertId + vIndex);
    }

    for (final (vIndex, vAlert) in pAlerts.take(maxInterviewAlerts).indexed) {
      await plugin.zonedSchedule(
        id: firstInterviewAlertId + vIndex,
        scheduledDate: tz.TZDateTime.from(vAlert.at, tz.local),
        title: vAlert.title,
        body: vAlert.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'interviews',
            deviceTexts().interviewsChannel,
            channelDescription: deviceTexts().interviewsChannelHelp,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    log("${pAlerts.length} rappel(s) d'entretien planifié(s)", name: 'entretiens');
  }

  @override
  Future<void> scheduleFollowUps(List<InterviewAlert> pAlerts) async {
    await initialize();

    for (var vIndex = 0; vIndex < maxFollowUpAlerts; vIndex++) {
      await plugin.cancel(id: firstFollowUpAlertId + vIndex);
    }

    for (final (vIndex, vAlert) in pAlerts.take(maxFollowUpAlerts).indexed) {
      await plugin.zonedSchedule(
        id: firstFollowUpAlertId + vIndex,
        scheduledDate: tz.TZDateTime.from(vAlert.at, tz.local),
        title: vAlert.title,
        body: vAlert.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'followups',
            deviceTexts().followUpsChannel,
            channelDescription: deviceTexts().followUpsChannelHelp,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    log("${pAlerts.length} rappel(s) de relance planifié(s)", name: 'cv');
  }

  @override
  Future<void> scheduleOfferChecks(bool pEnabled) async {
    if (pEnabled) {
      await Workmanager().registerPeriodicTask(
        offerCheckTask,
        offerCheckTask,
        frequency: offerCheckFrequency,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      );
    } else {
      await Workmanager().cancelByUniqueName(offerCheckTask);
    }

    log('Vérification des offres en arrière-plan ${pEnabled ? 'activée' : 'arrêtée'}',
        name: 'offres');
  }
}
