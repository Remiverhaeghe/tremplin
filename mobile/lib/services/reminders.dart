// Rappel quotidien de révision et alerte des nouvelles offres, par notification
// locale : aucune donnée ne quitte le téléphone.

import '../l10n/texts.dart';
import '../logic/interview_alerts.dart';

/// Heure du rappel, chaque jour.
const reminderHour = 18;
const reminderMinute = 30;

const reminderId = 1;
const offersNotificationId = 2;
const repliesNotificationId = 3;
const withdrawnNotificationId = 4;
const seasonNotificationId = 5;

// Rappels d'entretien : identifiants réservés, un par rappel
const firstInterviewAlertId = 100;
const maxInterviewAlerts = 20;

/// Résume une réponse : « Entretien chez Kiabi le 05/11 à 14:00 », « Refus de Kiabi ».
String describeReply(Map<String, dynamic> pReply, [AppLocalizations? pText]) {
  final vText = pText ?? deviceTexts();
  final vCompany = '${pReply['company'] ?? vText.replyCompanyUnknown}';

  if (pReply['status'] != 'INTERVIEW') {
    return vText.replyRefusal(vCompany);
  }

  final vDate = DateTime.tryParse('${pReply['interview_at'] ?? ''}');

  final rText = vDate == null
      ? vText.replyInterview(vCompany)
      : vText.replyInterviewAt(
          vCompany,
          twoDigits(vDate.day),
          twoDigits(vDate.month),
          twoDigits(vDate.hour),
          twoDigits(vDate.minute),
        );

  return rText;
}

/// Vérification des offres en arrière-plan : Android la lance au mieux toutes les
/// trois heures, seulement avec une connexion réseau.
const offerCheckTask = 'offer-check';
const offerCheckFrequency = Duration(hours: 3);

/// Rappel quotidien ; remplaçable dans les tests.
abstract class Reminders {
  /// Demande l'autorisation d'afficher des notifications ; retourne si elle est accordée.
  Future<bool> requestPermission();

  /// Planifie le rappel de chaque jour avec le nombre de questions à revoir.
  Future<void> schedule(int pDueCount);

  Future<void> cancel();

  /// Signale les nouvelles offres proches du profil, en une seule notification.
  Future<void> showNewOffers(List<Map<String, dynamic>> pOffers);

  /// Signale les réponses de recruteurs repérées par le PC, en une seule notification.
  Future<void> showReplies(List<Map<String, dynamic>> pReplies);

  /// Signale les offres suivies que leur site a retirées.
  Future<void> showWithdrawn(List<Map<String, dynamic>> pOffers);

  /// Annonce le bilan de la semaine écoulée.
  Future<void> showSeasonReview(Map<String, dynamic> pSeason);

  /// Remplace les rappels d'entretien par ceux donnés.
  Future<void> scheduleInterviews(List<InterviewAlert> pAlerts);

  /// Lance ou arrête la vérification périodique des offres en arrière-plan.
  Future<void> scheduleOfferChecks(bool pEnabled);
}
