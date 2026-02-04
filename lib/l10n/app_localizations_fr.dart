// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AroggyaPath';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get settings => 'Paramètres';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get english => 'Anglais';

  @override
  String get arabic => 'Arabe';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get french => 'Français';

  @override
  String get navHome => 'Accueil';

  @override
  String get navAppointments => 'Rendez-vous';

  @override
  String get navReels => 'Reels';

  @override
  String get navMessages => 'Messages';

  @override
  String get navProfile => 'Profil';

  @override
  String get personalInfo => 'Informations personnelles';

  @override
  String get myAppointment => 'Mon rendez-vous';

  @override
  String get myDependents => 'Mes Personnes à Charge';

  @override
  String get appointmentSetting => 'Paramètres de rendez-vous';

  @override
  String get myEarning => 'Mes gains';

  @override
  String get changePasswordLabel => 'Changer le mot de passe';

  @override
  String get helpSupport => 'Aide et support';

  @override
  String get logOut => 'Déconnexion';

  @override
  String get loading => 'Chargement...';

  @override
  String get checkingAuth => 'Vérification de l\'authentification';

  @override
  String get invalidSession => 'Session invalide';

  @override
  String get sessionExpiredMessage => 'Votre session est invalide.\nVeuillez vous reconnecter.';

  @override
  String get goToLogin => 'Aller à la connexion';

  @override
  String get searchDoctorHint => 'Rechercher un docteur...';

  @override
  String get locationServicesDisabledTitle => 'Services de localisation désactivés';

  @override
  String get locationServicesDisabledMessage => 'Les services de localisation sont désactivés. Veuillez les activer pour voir les docteurs à proximité.';

  @override
  String get locationPermissionRequiredTitle => 'Autorisation de localisation requise';

  @override
  String get locationPermissionRequiredMessage => 'L\'autorisation de localisation est requise pour afficher les docteurs à proximité. Veuillez accorder l\'autorisation dans les paramètres de l\'application.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get cancel => 'Annuler';

  @override
  String get loadingRoute => 'Chargement de l\'itinéraire...';

  @override
  String get directionsApiDisabled => 'API d\'itinéraire non activée. Utilisation de l\'itinéraire en ligne droite.';

  @override
  String get retry => 'Réessayer';

  @override
  String get loadingMap => 'Chargement de la carte...';

  @override
  String get distance => 'Distance';

  @override
  String get upcomingAppointment => 'Rendez-vous à venir';

  @override
  String get nearbyDoctors => 'Docteurs à proximité';

  @override
  String get seeAll => 'Voir tout';

  @override
  String get noDoctorsFound => 'Aucun docteur trouvé';

  @override
  String get available => 'Disponible';

  @override
  String get noSchedule => 'Aucun horaire';

  @override
  String get videoConsultation => 'Consultation vidéo';

  @override
  String get bookNow => 'Réserver maintenant';

  @override
  String get notAvailable => 'Pas disponible';

  @override
  String get noScheduleSet => 'Aucun horaire défini';

  @override
  String searchFailed(String error) {
    return 'La recherche a échoué : $error';
  }

  @override
  String get sessionExpiredTitle => 'Session expirée';

  @override
  String get sessionExpiredMessageDoc => 'Votre session a expiré. Veuillez vous reconnecter.';

  @override
  String get ok => 'D\'accord';

  @override
  String get failedLoadPosts => 'Échec du chargement des publications';

  @override
  String get connectionError => 'Erreur de connexion. Veuillez réessayer.';

  @override
  String get searchHintDoctor => 'Rechercher des médecins, des publications, des spécialités...';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get searching => 'Recherche en cours...';

  @override
  String get searchAnything => 'Rechercher n\'importe quoi';

  @override
  String get findEverything => 'Trouver des médecins, des publications ou des spécialités';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get tryDifferentKeywords => 'Essayez de rechercher avec des mots-clés différents';

  @override
  String get posts => 'Publications';

  @override
  String get noPostsYet => 'Pas encore de publications. Soyez le premier à partager !';

  @override
  String get shareInsights => 'Partagez vos réflexions avec vos confrères...';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Vidéo';

  @override
  String get reels => 'Reels';

  @override
  String get createPost => 'Créer une publication';

  @override
  String yearsExperience(int years) {
    return '$years ans d\'expérience';
  }

  @override
  String get noBioAvailable => 'Aucune biographie disponible';

  @override
  String get message => 'Message';

  @override
  String get welcomeBack => 'Bon retour';

  @override
  String loginToAccountAs(String userType) {
    return 'Veuillez vous connecter à votre compte en tant que $userType';
  }

  @override
  String get emailAddress => 'Adresse e-mail';

  @override
  String get emailHint => 'vous@gmail.com';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordHint => '****************';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ? ';

  @override
  String get signup => 'S\'inscrire';

  @override
  String welcomeBackUser(String userName) {
    return 'Bon retour, $userName !';
  }

  @override
  String get invalidAccountType => 'Type de compte invalide';

  @override
  String accountRegisteredAs(String role) {
    return 'Ce compte est enregistré en tant que $role. Veuillez utiliser l\'option de connexion correcte.';
  }

  @override
  String get loginFailed => 'Échec de la connexion. Veuillez vérifier vos identifiants.';

  @override
  String get enterEmail => 'Veuillez entrer votre e-mail';

  @override
  String createAccount(String userType) {
    return 'Créer un compte $userType';
  }

  @override
  String get fillDetails => 'Veuillez remplir les détails ci-dessous';

  @override
  String get fullName => 'Nom complet *';

  @override
  String get enterFullName => 'Entrez votre nom complet';

  @override
  String get emailAddressStar => 'Adresse e-mail *';

  @override
  String get emailExample => 'vous@exemple.com';

  @override
  String get invalidEmail => 'Veuillez entrer un e-mail valide';

  @override
  String get medicalLicenseNumber => 'Numéro de licence médicale *';

  @override
  String get enterLicenseNumber => 'Entrez le numéro de licence';

  @override
  String get referralCode => 'Code de parrainage';

  @override
  String get enterReferralCode => 'Entrez le code de parrainage';

  @override
  String get medicalSpecialty => 'Spécialité médicale *';

  @override
  String get selectSpecialty => 'Sélectionner la spécialité';

  @override
  String get yearsExperienceStar => 'Années d\'expérience *';

  @override
  String get yearsExperienceExample => 'ex. : 5';

  @override
  String get passwordStar => 'Mot de passe *';

  @override
  String get passwordLength => 'Au moins 6 caractères';

  @override
  String get confirmPasswordStar => 'Confirmer le mot de passe *';

  @override
  String get reenterPassword => 'Re-saisissez votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordAtLeast6 => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get licenseRequired => 'Le numéro de licence médicale est requis';

  @override
  String get specialtyRequired => 'Veuillez sélectionner une spécialité';

  @override
  String get experienceRequired => 'Les années d\'expérience sont requises';

  @override
  String get registrationSuccessful => 'Inscription réussie !';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? ';

  @override
  String get signInLabel => 'Se connecter';

  @override
  String get createAccountBtn => 'Créer un compte';

  @override
  String get forgotPasswordTitle => 'Mot de passe oublié';

  @override
  String get selectContactReset => 'Sélectionnez les coordonnées que nous devrions utiliser pour réinitialiser votre mot de passe';

  @override
  String get emailLabel => 'E-mail :';

  @override
  String get enterYourEmail => 'Entrez votre e-mail';

  @override
  String get sending => 'Envoi en cours...';

  @override
  String get continueText => 'Continuer';

  @override
  String get otpTitle => 'OTP';

  @override
  String get sentCodeEmail => 'Nous vous avons envoyé un code unique sur votre e-mail';

  @override
  String get valid6DigitOtp => 'Veuillez entrer un code OTP valide à 6 chiffres';

  @override
  String get emailNotFound => 'E-mail non trouvé. Veuillez recommencer le processus.';

  @override
  String get otpSentAgain => 'OTP renvoyé avec succès';

  @override
  String get didntGetCode => 'Vous n\'avez pas reçu le code ? ';

  @override
  String get resend => 'Renvoyer';

  @override
  String get resending => 'Renvoi en cours...';

  @override
  String get verifying => 'Vérification en cours...';

  @override
  String get resetPasswordTitle => 'Réinitialiser le mot de passe';

  @override
  String get setNewPassword => 'Définissez le nouveau mot de passe pour votre compte';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get fillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get success => 'Succès';

  @override
  String get passwordResetSuccess => 'Le mot de passe a été réinitialisé avec succès';

  @override
  String get resetting => 'Réinitialisation en cours...';

  @override
  String get appointmentManagement => 'Gestion des rendez-vous';

  @override
  String get manageConsultations => 'Gérez vos consultations vidéo\net physiques';

  @override
  String get pending => 'En attente';

  @override
  String get confirmed => 'Confirmé';

  @override
  String get completed => 'Terminé';

  @override
  String noAppointments(String status) {
    return 'Aucun rendez-vous $status';
  }

  @override
  String forDependent(String name) {
    return 'Pour : $name';
  }

  @override
  String get physical => 'Physique';

  @override
  String get seeDetails => 'Voir détails';

  @override
  String get accept => 'Accepter';

  @override
  String get startSession => 'Démarrer la session';

  @override
  String get appointmentDetails => 'Détails du rendez-vous';

  @override
  String get patientInformation => 'Informations du patient';

  @override
  String bookedFor(String name) {
    return 'Réservé pour : $name';
  }

  @override
  String get symptoms => 'Symptômes';

  @override
  String get noSymptoms => 'Aucun symptôme fourni';

  @override
  String get medicalDocuments => 'Documents médicaux';

  @override
  String docsUploaded(int count) {
    return '$count document(s) téléchargé(s)';
  }

  @override
  String get noDocsUploaded => 'Aucun document médical téléchargé';

  @override
  String get paymentScreenshot => 'Capture d\'écran du paiement';

  @override
  String get viewPaymentScreenshot => 'Voir la capture d\'écran du paiement';

  @override
  String get noPaymentScreenshot => 'Aucune capture d\'écran du paiement téléchargée';

  @override
  String get documentUrl => 'URL du document';

  @override
  String get close => 'Fermer';

  @override
  String errorOpeningDoc(String error) {
    return 'Erreur lors de l\'ouverture du document : $error';
  }

  @override
  String get cancelAppointment => 'Annuler le rendez-vous';

  @override
  String get confirmCancel => 'Êtes-vous sûr de vouloir annuler ce rendez-vous ?';

  @override
  String get no => 'Non';

  @override
  String get yes => 'Oui';

  @override
  String get appointmentAccepted => 'Rendez-vous accepté avec succès';

  @override
  String get failedAccept => 'Échec de l\'acceptation du rendez-vous';

  @override
  String get appointmentCancelled => 'Rendez-vous annulé';

  @override
  String get cancelled => 'Annulé';

  @override
  String get failedCancel => 'Échec de l\'annulation du rendez-vous';

  @override
  String get loadingImage => 'Chargement de l\'image...';

  @override
  String get failedLoadImage => 'Échec du chargement de l\'image';

  @override
  String get medicalDocument => 'Document médical';

  @override
  String get resetZoom => 'Réinitialiser le zoom';

  @override
  String get zoomInstructions => 'Pinçage pour zoomer • Glissement pour panoramique';

  @override
  String get upcoming => 'À venir';

  @override
  String upcomingCount(int count) {
    return 'À venir ($count)';
  }

  @override
  String get reschedule => 'Reprogrammer';

  @override
  String get writeReview => 'Écrire un avis';

  @override
  String get updateReview => 'Mettre à jour votre avis';

  @override
  String get rateExperience => 'Évaluez votre expérience';

  @override
  String withDoctor(String name) {
    return 'avec $name';
  }

  @override
  String get notif_appointment_booked_title => 'Nouvelle demande de rendez-vous';

  @override
  String get notif_appointment_booked_body => 'Vous avez une nouvelle demande de rendez-vous d\'un patient.';

  @override
  String get notif_appointment_confirmed_title => 'Rendez-vous confirmé';

  @override
  String get notif_appointment_confirmed_body => 'Votre rendez-vous avec le médecin a été confirmé.';

  @override
  String get notif_appointment_cancelled_title => 'Rendez-vous annulé';

  @override
  String get notif_appointment_cancelled_body => 'Un rendez-vous a été annulé.';

  @override
  String get notif_appointment_completed_title => 'Rendez-vous terminé';

  @override
  String get notif_appointment_completed_body => 'Votre rendez-vous a été marqué comme terminé.';

  @override
  String get notif_post_liked_title => 'Nouveau J\'aime';

  @override
  String get notif_post_liked_body => 'Quelqu\'un a aimé votre publication.';

  @override
  String get notif_post_commented_title => 'Nouveau commentaire';

  @override
  String get notif_post_commented_body => 'Quelqu\'un a commenté votre publication.';

  @override
  String get notif_reel_liked_title => 'Nouveau J\'aime sur Reel';

  @override
  String get notif_reel_liked_body => 'Quelqu\'un a aimé votre reel.';

  @override
  String get notif_reel_commented_title => 'Nouveau commentaire sur Reel';

  @override
  String get notif_reel_commented_body => 'Quelqu\'un a commenté votre reel.';

  @override
  String get reviewSubmitted => 'Avis soumis avec succès ! ⭐';

  @override
  String get failedSubmitReview => 'Échec de l\'envoi de l\'avis';

  @override
  String get submit => 'Soumettre';

  @override
  String get doctor => 'Docteur';

  @override
  String get videoAvailable => 'Consultation vidéo disponible';

  @override
  String get inPersonOnly => 'En personne uniquement';

  @override
  String reviewsCount(int count) {
    return '($count avis)';
  }

  @override
  String get bio => 'Biographie';

  @override
  String get specialty => 'Spécialité';

  @override
  String get degree => 'Diplôme';

  @override
  String get fees => 'Honoraires';

  @override
  String get dzd => 'DZD';

  @override
  String get visitingHours => 'Heures de visite';

  @override
  String get notSet => 'Non défini';

  @override
  String get messageDoctor => 'Contacter le docteur';

  @override
  String get invalidDoctor => 'Docteur invalide';

  @override
  String get doctorIdNotFound => 'ID du docteur non trouvé';

  @override
  String get failedCreateChat => 'Échec de la création du chat';

  @override
  String get failedOpenChat => 'Échec de l\'ouverture du chat';

  @override
  String get physicalVisit => 'Consultation physique';

  @override
  String get videoCall => 'Appel vidéo';

  @override
  String get audioVideoCalls => 'Appels Audio/Vidéo';

  @override
  String get rescheduleAppointment => 'Reprogrammer le rendez-vous';

  @override
  String get bookAppointment => 'Prendre rendez-vous';

  @override
  String get rescheduleBanner => 'Vous reprogrammez votre rendez-vous. L\'ancien rendez-vous sera annulé.';

  @override
  String get videoUploadWarning => 'Consultations vidéo - le patient doit\ntélécharger une capture d\'écran du paiement BaridiMob';

  @override
  String get appointmentTypeLabel => 'Type de rendez-vous';

  @override
  String get payAtClinic => 'Payer à la clinique';

  @override
  String get onlinePayment => 'Paiement en ligne';

  @override
  String get bookAppointmentFor => 'Prendre rendez-vous pour';

  @override
  String get myself => 'Moi-même';

  @override
  String get orSelectDependent => 'Ou sélectionnez un dépendant :';

  @override
  String get addNewDependent => 'Ajouter un nouveau dépendant';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get datePlaceholder => 'jj/mm/aaaa';

  @override
  String get availableTime => 'Heures disponibles';

  @override
  String get noTimeSlots => 'Aucun créneau horaire disponible pour cette date';

  @override
  String get timeTo => 'À';

  @override
  String get booked => 'Réservé';

  @override
  String get describeSymptoms => 'Décrivez vos symptômes';

  @override
  String get symptomsHint => 'Veuillez décrire vos symptômes en détail....';

  @override
  String get uploadMedicalDocs => 'Télécharger des documents médicaux';

  @override
  String get tapToUpload => 'Appuyez pour télécharger une image ou un PDF';

  @override
  String get uploadPaymentScreenshot => 'Télécharger une capture d\'écran du paiement';

  @override
  String get tapToUploadPayment => 'Appuyez pour télécharger votre preuve de paiement';

  @override
  String get confirmReschedule => 'Confirmer la reprogrammation';

  @override
  String get submitAppointmentRequest => 'Envoyer la demande de rendez-vous';

  @override
  String get invalidDoctorBooking => 'Docteur invalide - Impossible de prendre rendez-vous';

  @override
  String get selectDateTime => 'Veuillez sélectionner la date et l\'heure';

  @override
  String rescheduleFailed(String error) {
    return 'Échec de la reprogrammation : $error';
  }

  @override
  String get paymentRequired => 'Capture d\'écran de paiement requise pour la consultation vidéo';

  @override
  String get bookingFailed => 'Échec de la réservation';

  @override
  String get completeSession => 'Terminer la session';

  @override
  String get sessionCompleted => 'Session terminée avec succès ! ✅';

  @override
  String get failedCompleteSession => 'Échec de la fin de session';

  @override
  String get sessionPaymentDetails => 'Détails du paiement de la session';

  @override
  String get enterSessionDetails => 'Entrez les détails pour terminer cette session';

  @override
  String get patientFullName => 'Nom complet du patient';

  @override
  String get enterPatientName => 'Entrez le nom complet du patient';

  @override
  String get patientNameRequired => 'Veuillez entrer le nom du patient';

  @override
  String get payableAmount => 'Montant à payer (DZD)';

  @override
  String get enterAmountReceived => 'Entrez le montant reçu';

  @override
  String get amountRequired => 'Veuillez entrer le montant';

  @override
  String get validAmountRequired => 'Veuillez entrer un montant valide';

  @override
  String get notificationTitle => 'Notification';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get markAllAsRead => 'Tout marquer comme lu';

  @override
  String get newNotifications => 'Nouveau';

  @override
  String get earlierNotifications => 'Plus tôt';

  @override
  String get noNotifications => 'Aucune notification';

  @override
  String get noNotificationsYet => 'Pas encore de notifications';

  @override
  String get doctorNotificationEmptySubtitle => 'Nous vous informerons lorsqu\'un patient réserve ou met à jour un rendez-vous.';

  @override
  String get upcomingPatient => 'Patient à venir';

  @override
  String get addTextOrMedia => 'Veuillez ajouter du texte ou un média à publier';

  @override
  String get reelPrivacy => 'Confidentialité du Reel';

  @override
  String get reelVisibleDoctorsOnly => '🔒 Ce reel sera visible uniquement par les médecins.';

  @override
  String get reelVisibleEveryone => '🌍 Ce reel sera visible par tout le monde (médecins et patients).';

  @override
  String currentPrivacy(Object privacy) {
    return 'Confidentialité actuelle : $privacy';
  }

  @override
  String get privateDoctorsOnly => 'Privé (Médecins uniquement)';

  @override
  String get publicEveryone => 'Public (Tout le monde)';

  @override
  String get uploadReel => 'Télécharger le Reel';

  @override
  String get privateReelUploaded => '✓ Reel privé téléchargé ! (Médecins uniquement)';

  @override
  String get publicReelUploaded => '✓ Reel public téléchargé ! (Visible par tous)';

  @override
  String get failedUploadReel => 'Échec du téléchargement du reel';

  @override
  String get postSharedSuccessfully => '✓ Publication partagée avec succès !';

  @override
  String get failedCreatePost => 'Échec de la création de la publication';

  @override
  String get whatsOnYourMind => 'Qu\'avez-vous en tête ?.......';

  @override
  String get videoSelected => 'Vidéo sélectionnée';

  @override
  String get failedLikePost => 'Échec du like';

  @override
  String get deletePost => 'Supprimer la publication';

  @override
  String get reportPost => 'Signaler la publication';

  @override
  String get reportComingSoon => 'Signalement - Bientôt disponible !';

  @override
  String get confirmDeletePost => 'Êtes-vous sûr de vouloir supprimer cette publication ?';

  @override
  String get delete => 'Supprimer';

  @override
  String get postDeletedSuccessfully => '✓ Publication supprimée avec succès';

  @override
  String get failedDeletePost => 'Échec de la suppression de la publication';

  @override
  String get sharePost => 'Partager la publication';

  @override
  String get shareExternally => 'Partager à l\'extérieur';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String get shareMessageComingSoon => 'Partager par message - Bientôt disponible !';

  @override
  String authorPosted(Object name) {
    return '$name a publié :';
  }

  @override
  String imagesCount(Object count) {
    return '$count image(s)';
  }

  @override
  String videosCount(Object count) {
    return '$count vidéo(s)';
  }

  @override
  String get noCommentsYet => 'Pas encore de commentaires';

  @override
  String get writeComment => 'Écrire un commentaire...';

  @override
  String get likeLabel => 'J\'aime';

  @override
  String get commentLabel => 'Commenter';

  @override
  String get shareLabel => 'Partager';

  @override
  String likesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'likes',
      one: 'like',
    );
    return '$count $_temp0';
  }

  @override
  String commentsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'commentaires',
      one: 'commentaire',
    );
    return '$count $_temp0';
  }

  @override
  String sharesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'partages',
      one: 'partage',
    );
    return '$count $_temp0';
  }

  @override
  String get post => 'Publier';

  @override
  String get commentsLabel => 'Commentaires';

  @override
  String get reelsLabel => 'Reels';

  @override
  String get failedLoadReels => 'Échec du chargement des réels';

  @override
  String get retryLabel => 'Réessayer';

  @override
  String get noReelsAvailable => 'Aucun réel disponible';

  @override
  String get unknownDoctor => 'Docteur inconnu';

  @override
  String get unknown => 'Inconnu';

  @override
  String get doctorsOnlyLabel => 'Médecins seulement';

  @override
  String get failedLikeReel => 'Échec de l\'appréciation du réel';

  @override
  String authorSharedReel(Object name) {
    return '$name a partagé un réel';
  }

  @override
  String playbackSpeed(Object speed) {
    return 'Vitesse ${speed}x';
  }

  @override
  String get justNow => 'À l\'instant';

  @override
  String get messagesLabel => 'Messages';

  @override
  String get allLabel => 'Tous';

  @override
  String get doctorsLabel => 'Médecins';

  @override
  String get patientsLabel => 'Patients';

  @override
  String get noMessagesYet => 'Pas encore de messages';

  @override
  String get noConversationsYet => 'Pas encore de conversations';

  @override
  String get deleteChats => 'Supprimer les chats';

  @override
  String get deleteMessages => 'Supprimer les messages';

  @override
  String deleteConversationsConfirm(Object count) {
    return 'Êtes-vous sûr de vouloir supprimer $count conversations ? Cela supprimera tous les messages.';
  }

  @override
  String deleteMessagesConfirm(Object count) {
    return 'Êtes-vous sûr de vouloir supprimer $count messages ?';
  }

  @override
  String get deleteLabel => 'Supprimer';

  @override
  String get conversationsDeleted => 'Conversations supprimées';

  @override
  String get messagesDeleted => 'Messages supprimés';

  @override
  String failedToDelete(Object error) {
    return 'Échec de la suppression: $error';
  }

  @override
  String startConversationWith(Object name) {
    return 'Démarrer une conversation avec $name';
  }

  @override
  String get typeAMessage => 'Tapez un message...';

  @override
  String get failedToSendMessage => 'Échec de l\'envoi du message';

  @override
  String get cannotStartCallNoId => 'Impossible de démarrer l\'appel - ID utilisateur introuvable';

  @override
  String failedToStartCall(Object error) {
    return 'Échec du démarrage de l\'appel: $error';
  }

  @override
  String get voiceCall => 'Appel vocal';

  @override
  String get doctorUnavailableForCalls => 'Le médecin n\'est pas disponible pour les appels à ce moment';

  @override
  String doctorUnavailableForCallsDescription(Object type) {
    return 'Le médecin n\'est pas disponible pour les appels $type. Vous pouvez envoyer un message ou réessayer plus tard.';
  }

  @override
  String get imageLabel => '[Image]';

  @override
  String get fileLabel => '[Fichier]';

  @override
  String get messageLabel => '[Message]';

  @override
  String get yesterday => 'Hier';

  @override
  String get todayLabel => 'Aujourd\'hui';

  @override
  String daysAgo(Object count) {
    return 'Il y a ${count}j';
  }

  @override
  String hoursAgo(Object count) {
    return 'Il y a ${count}h';
  }

  @override
  String minutesAgo(Object count) {
    return 'Il y a ${count}m';
  }

  @override
  String get meLabel => 'Moi';

  @override
  String get patientLabel => 'Patient';

  @override
  String get doctorLabel => 'Docteur';

  @override
  String get startConversation => 'Démarrer la conversation';

  @override
  String get helpSupportComingSoon => 'Aide et Support - Bientôt disponible';

  @override
  String get noDependentsAdded => 'Aucune personne à charge ajoutée pour le moment';

  @override
  String get addDependent => 'Ajouter une Personne à Charge';

  @override
  String get editDependent => 'Modifier le Dépendant';

  @override
  String get inactive => 'Inactif';

  @override
  String get active => 'Actif';

  @override
  String get ageLabel => 'Âge';

  @override
  String get genderLabel => 'Genre';

  @override
  String get contactLabel => 'Contact';

  @override
  String get deleteDependentTitle => 'Supprimer le Dépendant ?';

  @override
  String deleteDependentConfirm(Object name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?';
  }

  @override
  String get deleteDependentWarning => 'S\'ils ont des rendez-vous actifs, vous devez d\'abord les annuler.';

  @override
  String get cannotDeleteTitle => 'Impossible de Supprimer';

  @override
  String get howToFix => 'Comment réparer :';

  @override
  String get deleteFixInstructions => '1. Allez dans Mes Rendez-vous\n2. Annulez tout rendez-vous en attente/accepté pour ce dépendant\n3. Réessayez ensuite de supprimer';

  @override
  String get goToAppointments => 'Aller aux Rendez-vous';

  @override
  String dependentDeletedSuccess(Object name) {
    return '$name supprimé avec succès';
  }

  @override
  String get dependentAddedSuccess => 'Dépendant ajouté avec succès !';

  @override
  String get dependentUpdatedSuccess => 'Dépendant mis à jour avec succès !';

  @override
  String get failedToAddDependent => 'Échec de l\'ajout du dépendant';

  @override
  String get failedToUpdateDependent => 'Échec de la mise à jour du dépendant';

  @override
  String get basicInformation => 'Informations de Base';

  @override
  String get nameIsRequired => 'Le nom est requis';

  @override
  String get selectRelationship => 'Veuillez sélectionner la relation';

  @override
  String get selectDob => 'Veuillez sélectionner la date de naissance';

  @override
  String get relationshipLabel => 'Relation';

  @override
  String get relationshipHint => 'Relation (ex: Enfant, Conjoint)';

  @override
  String get contactDetails => 'Détails du Contact';

  @override
  String get guardianContactLabel => 'Contact Parent/Tuteur (Principal)';

  @override
  String get userInfoWillBeUsed => 'Vos informations d\'utilisateur seront utilisées';

  @override
  String get dependentContactHint => 'Contact du dépendant (le cas échéant)';

  @override
  String get additionalInformation => 'Informations Additionnelles';

  @override
  String get medicalNotesHint => 'Notes Médicales / Allergies (Optionnel)';

  @override
  String get saveDependent => 'Enregistrer le Dépendant';

  @override
  String get updateDependent => 'Mettre à jour le Dépendant';

  @override
  String get relChild => 'Enfant';

  @override
  String get relSpouse => 'Conjoint';

  @override
  String get relFather => 'Père';

  @override
  String get relMother => 'Mère';

  @override
  String get relBrother => 'Frère';

  @override
  String get relSister => 'Sœur';

  @override
  String get relGrandparent => 'Grand-parent';

  @override
  String get relOther => 'Autre';

  @override
  String get relSon => 'Fils';

  @override
  String get relDaughter => 'Fille';

  @override
  String get male => 'Homme';

  @override
  String get female => 'Femme';

  @override
  String get edit => 'Modifier';

  @override
  String get dateOfBirth => 'Date de Naissance';

  @override
  String get editYourProfile => 'Modifier votre profil';

  @override
  String get profilePicture => 'Photo de profil';

  @override
  String get tapToChangePicture => 'Appuyez pour changer votre photo';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get address => 'Adresse';

  @override
  String get updateProfile => 'Mettre à jour le profil';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès';

  @override
  String get updateFailed => 'Échec de la mise à jour';

  @override
  String get nameEmptyError => 'Le nom ne peut pas être vide';

  @override
  String get noChangesToSave => 'Aucun changement à enregistrer';

  @override
  String errorMsg(Object error) {
    return 'Erreur : $error';
  }

  @override
  String get addBio => 'Ajouter une biographie';

  @override
  String get bioHint => 'Dites-nous en plus sur vous...';

  @override
  String get degreeHint => 'MBBS, MD, etc.';

  @override
  String get emailLockedNote => 'L\'email ne peut pas être modifié';

  @override
  String get clinicLocation => 'Emplacement de la clinique';

  @override
  String get clinicLocationHint => 'Définir l\'emplacement de votre clinique';

  @override
  String get contactNumberHint => 'Numéro de contact';

  @override
  String get specCardiologist => 'Cardiologue';

  @override
  String get specDermatologist => 'Dermatologue';

  @override
  String get specNeurologist => 'Neurologue';

  @override
  String get specOrthopedic => 'Orthopédiste';

  @override
  String get specPediatrician => 'Pédiatre';

  @override
  String get specPsychiatrist => 'Psychiatre';

  @override
  String get specGeneralPhysician => 'Médecin généraliste';

  @override
  String get specENT => 'ORL';

  @override
  String get specGynecologist => 'Gynécologue';

  @override
  String get specOphthalmologist => 'Ophtalmologue';

  @override
  String get specDentist => 'Dentiste';

  @override
  String get specUrologist => 'Urologue';

  @override
  String get statusLabel => 'Statut';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get passwordLengthRequirement => 'Le mot de passe doit comporter au moins 6 caractères';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get enterCurrentPassword => 'Entrez le mot de passe actuel';

  @override
  String get enterNewPassword => 'Entrez le nouveau mot de passe';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get reEnterNewPassword => 'Ré-entrez le nouveau mot de passe';

  @override
  String get passwordsDoNotMatchError => 'Le nouveau mot de passe et la confirmation ne correspondent pas';

  @override
  String get passwordChangedSuccess => 'Mot de passe changé avec succès';

  @override
  String get changePasswordFailed => 'Échec du changement de mot de passe';

  @override
  String get earningOverview => 'Aperçu des revenus';

  @override
  String get trackIncomeSubtitle => 'Suivez vos revenus pour tous les types de rendez-vous.';

  @override
  String get daily => 'Quotidien';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get monthly => 'Mensuel';

  @override
  String get totalEarning => 'Gain total';

  @override
  String appointmentsCount(Object count) {
    return '$count rendez-vous';
  }

  @override
  String sessionsCount(Object count) {
    return '$count séances';
  }

  @override
  String get weeklyPerformance => 'Performance hebdomadaire';

  @override
  String get failedFetchEarnings => 'Échec de la récupération des revenus';

  @override
  String get onlineAppointment => 'Rendez-vous en ligne';

  @override
  String get consultationFees => 'Frais de consultation (DZD)';

  @override
  String get weeklySchedule => 'Programme hebdomadaire';

  @override
  String get addNewSlot => 'Ajouter un nouveau créneau';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get endTimeError => 'L\'heure de fin doit être après l\'heure de début';

  @override
  String get enterConsultationFees => 'Veuillez saisir les frais de consultation';

  @override
  String get scheduleSavedSuccess => 'Programme enregistré avec succès!';

  @override
  String get to => 'À';

  @override
  String get selectStartTime => 'Sélectionner l\'heure de début';

  @override
  String get selectEndTime => 'Sélectionner l\'heure de fin';

  @override
  String get selectTimeFromPicker => 'Veuillez sélectionner l\'heure dans le sélecteur ci-dessous';

  @override
  String get faqTitle => 'Foire Aux Questions (FAQ)';

  @override
  String get faq1Question => '1. Comment créer un compte ?';

  @override
  String get faq1Answer => 'Vous pouvez vous inscrire en tant que patient ou médecin en choisissant votre rôle et en suivant les étapes d\'inscription dans l\'application.';

  @override
  String get faq2Question => '2. J\'ai oublié mon mot de passe. Que dois-je faire ?';

  @override
  String get faq2Answer => 'Allez sur l\'écran de connexion et appuyez sur « Mot de passe oublié ». Suivez les instructions pour réinitialiser votre mot de passe en toute sécurité.';

  @override
  String get faq3Question => '3. Comment prendre rendez-vous avec un médecin ?';

  @override
  String get faq3Answer => 'Recherchez un médecin ou une spécialité, sélectionnez un créneau horaire disponible et confirmez votre rendez-vous.';

  @override
  String get faq4Question => '4. Puis-je annuler ou reprogrammer mon rendez-vous ?';

  @override
  String get faq4Answer => 'Oui, vous pouvez annuler ou reprogrammer vos rendez-vous dans la section « Mes rendez-vous », selon l\'état du rendez-vous.';

  @override
  String get faq5Question => '5. Comment fonctionnent les consultations audio/vidéo en ligne ?';

  @override
  String get faq5Answer => 'Une fois votre rendez-vous confirmé, vous pouvez démarrer un appel audio ou vidéo directement depuis le chat à l\'heure prévue (si activé par le médecin).';

  @override
  String get faq6Question => '6. Pourquoi ne puis-je pas démarrer un appel avec le médecin ?';

  @override
  String get faq6Answer => 'Le médecin a peut-être désactivé temporairement les appels audio/vidéo. Veuillez réessayer plus tard ou contacter l\'assistance.';

  @override
  String get faq7Question => '7. Comment changer la langue de l\'application ?';

  @override
  String get faq7Answer => 'Vous pouvez changer la langue dans les paramètres de l\'application à tout moment.';

  @override
  String get faq8Question => '8. Comment les médecins gèrent-ils les informations de leur profil ?';

  @override
  String get faq8Answer => 'Les médecins peuvent modifier leurs informations personnelles et professionnelles dans les paramètres du profil.';

  @override
  String get faq9Question => '9. Comment fonctionne le système de parrainage ?';

  @override
  String get faq9Answer => 'Si les codes de parrainage sont activés, les médecins peuvent s\'inscrire en utilisant un code de parrainage valide fourni par l\'administrateur.';

  @override
  String get stillNeedHelp => 'Besoin d\'aide supplémentaire ?';

  @override
  String get emailUs => 'Envoyez-nous un e-mail';

  @override
  String get callUs => 'Appelez-nous';

  @override
  String get emailSubject => 'Demande d\'aide et de support';

  @override
  String get bookingSuccess => 'Rendez-vous pris avec succès !';
}
