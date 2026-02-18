import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      'login_title': 'اختبار TMT',
      'patient_space': 'فضاء المريض',
      'doctor_space': 'فضاء الطبيب',
      'patient_id_label': 'معرف المريض',
      'patient_id_hint': 'الرجاء إدخال معرف المريض',
      'doctor_id_label': 'المعرف',
      'doctor_pwd_label': 'كلمة المرور',
      'login_btn': 'دخول',
      'login_action': 'تسجيل الدخول',
      'invalid_login': 'بيانات الدخول غير صحيحة',
      'welcome': 'مرحباً',
      'start_test': 'ابدأ الاختبار',
      'test_title': 'اختبار TMT',
      'sequence_label': 'التسلسل',
      'repeat_sequence': 'كرر التسلسل',
      'listen_btn': 'استمع',
      'listening': 'أنا أستمع...',
      'next_confirm': 'التالي / تأكيد',
      'finish_test': 'إنهاء الاختبار',
      'correct_feedback': 'صحيح! +0.5',
      'wrong_feedback': 'خطأ.',
      'heard': 'سمعت: ',
      'test_finished_title': 'انتهى الاختبار',
      'test_finished_msg': 'تم الاختبار بنجاح.\nشكراً لمشاركتك.',
      'main_menu': 'القائمة الرئيسية',
      'doctor_dashboard': 'لوحة تحكم الطبيب',
      'recent_results': 'النتائج الأخيرة',
      'id_prefix': 'المعرف: ',
      'result_prefix': 'النتيجة: ',
      'time_prefix': 'الوقت: ',
      'date_prefix': 'التاريخ: ',
      'play_btn': 'تشغيل...',
      'validate_btn': 'تأكيد',
      'next_btn': 'التالي',
      'logout': 'تسجيل الخروج',
      'back': 'رجوع',
      // Test Selection
      'select_test_title': 'اختيار الاختبار',
      'welcome_msg': 'مرحباً، ',
      'tmt_a_btn': 'TMT - الجزء أ',
      'tmt_b_btn': 'TMT - الجزء ب',
      // TMT Pages
      'tmt_a_title': 'اختبار TMT-A',
      'tmt_b_title': 'اختبار TMT-B',
      'start_label': 'بداية',
      'end_label': 'نهاية',
      'tmt_a_instructions':
          'اضغط على الأرقام بالترتيب من 1 إلى 25.\nاضغط على 1 للبدء.',
      'tmt_b_instructions':
          'اربط الأرقام بالترتيب مع التناوب بين الألوان.\n1 (أبيض) -> 1 (أزرق) -> 2 (أبيض) -> 2 (أزرق)...',
      'well_done': 'أحسنت!',
      'test_completed_success': 'لقد أتممت الاختبار بنجاح.',
      // Doctor Dashboard
      'search_hint': 'بحث بالمعرف...',
      'add_patient_btn': 'إضافة مريض',
      'no_patients': 'لا يوجد مرضى',
      'patient_added': 'تم إضافة المريض بنجاح',
      'add_patient_title': 'إضافة مريض جديد',
      'full_name_label': 'الاسم الكامل',
      'add_btn': 'إضافة',
      'cancel_btn': 'إلغاء',
      // Patient Details
      'test_history': 'سجل الاختبارات',
      'filter_date': 'تصفية حسب التاريخ',
      'no_tmt_found': 'لا توجد اختبارات TMT.',
      'col_date': 'التاريخ',
      'col_test_name': 'اسم الاختبار',
      'col_time_spent': 'الوقت المستغرق',
      // Register
      'register_title_doc': 'تسجيل طبيب',
      'confirm_password': 'تأكيد كلمة المرور',
      'register_btn': 'تسجيل',
      'already_account': 'لديك حساب بالفعل؟',
    },
    'fr': {
      'login_title': 'Test TMT',
      'patient_space': 'Espace Patient',
      'doctor_space': 'Espace Médecin',
      'patient_id_label': 'Identifiant Patient',
      'patient_id_hint': 'Veuillez entrer l\'ID du patient',
      'doctor_id_label': 'Identifiant',
      'doctor_pwd_label': 'Mot de passe',
      'login_btn': 'Entrer',
      'login_action': 'Se connecter',
      'invalid_login': 'Identifiants incorrects',
      'welcome': 'Bienvenue',
      'start_test': 'Commencer le test',
      'test_title': 'Test TMT',
      'sequence_label': 'Séquence',
      'repeat_sequence': 'Répétez la séquence',
      'listen_btn': 'Écouter',
      'listening': 'J\'écoute...',
      'next_confirm': 'Suivant / Valider',
      'finish_test': 'Terminer le test',
      'correct_feedback': 'Correct! +0.5',
      'wrong_feedback': 'Faux.',
      'heard': 'Entendu: ',
      'test_finished_title': 'Test Terminé',
      'test_finished_msg':
          'Le test est terminé avec succès.\nMerci pour votre participation.',
      'main_menu': 'Menu Principal',
      'doctor_dashboard': 'Tableau de bord Médecin',
      'recent_results': 'Résultats Récents',
      'id_prefix': 'ID: ',
      'result_prefix': 'Score: ',
      'time_prefix': 'Temps: ',
      'date_prefix': 'Date: ',
      'play_btn': 'Lecture...',
      'validate_btn': 'Valider',
      'next_btn': 'Suivant',
      'validate_first_msg': 'Veuillez valider la réponse d\'abord',
      // NEW KEYS FR
      'logout': 'Déconnexion',
      'back': 'Retour',
      // Test Selection
      'select_test_title': 'Choisir le test',
      'welcome_msg': 'Bienvenue, ',
      'tmt_a_btn': 'TMT - Partie A',
      'tmt_b_btn': 'TMT - Partie B',
      // TMT Pages
      'tmt_a_title': 'Test TMT-A',
      'tmt_b_title': 'Test TMT-B',
      'start_label': 'Début',
      'end_label': 'Fin',
      'tmt_a_instructions':
          'Appuyez sur les chiffres de 1 à 25.\nAppuyez sur 1 pour commencer.',
      'tmt_b_instructions':
          'Reliez les chiffres en alternant les couleurs.\n1 (Blanc) -> 1 (Bleu) -> 2 (Blanc)...',
      'well_done': 'Bravo!',
      'test_completed_success': 'Test terminé avec succès.',
      // Doctor Dashboard
      'search_hint': 'Chercher par ID...',
      'add_patient_btn': 'Ajouter Patient',
      'no_patients': 'Aucun patient trouvé',
      'patient_added': 'Patient ajouté avec succès',
      'add_patient_title': 'Ajouter un nouveau patient',
      'full_name_label': 'Nom complet',
      'add_btn': 'Ajouter',
      'cancel_btn': 'Annuler',
      // Patient Details
      'test_history': 'Historique des tests',
      'filter_date': 'Filtrer par date',
      'no_tmt_found': 'Aucun test TMT trouvé.',
      'col_date': 'Date',
      'col_test_name': 'Nom du test',
      'col_time_spent': 'Temps écoulé',
      // Register
      'register_title_doc': 'Inscription Médecin',
      'confirm_password': 'Confirmer le mot de passe',
      'register_btn': 'S\'inscrire',
      'already_account': 'Vous avez déjà un compte?',
    },
  };

  String get loginTitle =>
      _localizedValues[locale.languageCode]!['login_title']!;
  String get patientSpace =>
      _localizedValues[locale.languageCode]!['patient_space']!;
  String get doctorSpace =>
      _localizedValues[locale.languageCode]!['doctor_space']!;
  String get patientIdLabel =>
      _localizedValues[locale.languageCode]!['patient_id_label']!;
  String get patientIdHint =>
      _localizedValues[locale.languageCode]!['patient_id_hint']!;
  String get doctorIdLabel =>
      _localizedValues[locale.languageCode]!['doctor_id_label']!;
  String get doctorPwdLabel =>
      _localizedValues[locale.languageCode]!['doctor_pwd_label']!;
  String get loginBtn => _localizedValues[locale.languageCode]!['login_btn']!;
  String get loginAction =>
      _localizedValues[locale.languageCode]!['login_action']!;
  String get invalidLogin =>
      _localizedValues[locale.languageCode]!['invalid_login']!;
  String get welcome => _localizedValues[locale.languageCode]!['welcome']!;
  String get startTest => _localizedValues[locale.languageCode]!['start_test']!;
  String get testTitle => _localizedValues[locale.languageCode]!['test_title']!;
  String get sequenceLabel =>
      _localizedValues[locale.languageCode]!['sequence_label']!;
  String get repeatSequence =>
      _localizedValues[locale.languageCode]!['repeat_sequence']!;
  String get listenBtn => _localizedValues[locale.languageCode]!['listen_btn']!;
  String get listening => _localizedValues[locale.languageCode]!['listening']!;
  String get nextConfirm =>
      _localizedValues[locale.languageCode]!['next_confirm']!;
  String get finishTest =>
      _localizedValues[locale.languageCode]!['finish_test']!;
  String get correctFeedback =>
      _localizedValues[locale.languageCode]!['correct_feedback']!;
  String get wrongFeedback =>
      _localizedValues[locale.languageCode]!['wrong_feedback']!;
  String get heard => _localizedValues[locale.languageCode]!['heard']!;
  String get testFinishedTitle =>
      _localizedValues[locale.languageCode]!['test_finished_title']!;
  String get testFinishedMsg =>
      _localizedValues[locale.languageCode]!['test_finished_msg']!;
  String get mainMenu => _localizedValues[locale.languageCode]!['main_menu']!;
  String get doctorDashboard =>
      _localizedValues[locale.languageCode]!['doctor_dashboard']!;
  String get recentResults =>
      _localizedValues[locale.languageCode]!['recent_results']!;
  String get idPrefix => _localizedValues[locale.languageCode]!['id_prefix']!;
  String get resultPrefix =>
      _localizedValues[locale.languageCode]!['result_prefix']!;
  String get timePrefix =>
      _localizedValues[locale.languageCode]!['time_prefix']!;
  String get datePrefix =>
      _localizedValues[locale.languageCode]!['date_prefix']!;
  String get playBtn => _localizedValues[locale.languageCode]!['play_btn']!;
  String get validateBtn =>
      _localizedValues[locale.languageCode]!['validate_btn']!;
  String get nextBtn => _localizedValues[locale.languageCode]!['next_btn']!;
  String get validateFirstMsg =>
      _localizedValues[locale.languageCode]!['validate_first_msg']!;

  // NEW GETTERS
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get back => _localizedValues[locale.languageCode]!['back']!;
  String get selectTestTitle =>
      _localizedValues[locale.languageCode]!['select_test_title']!;
  String get welcomeMsg =>
      _localizedValues[locale.languageCode]!['welcome_msg']!;
  String get tmtABtn => _localizedValues[locale.languageCode]!['tmt_a_btn']!;
  String get tmtBBtn => _localizedValues[locale.languageCode]!['tmt_b_btn']!;
  String get tmtATitle =>
      _localizedValues[locale.languageCode]!['tmt_a_title']!;
  String get tmtBTitle =>
      _localizedValues[locale.languageCode]!['tmt_b_title']!;
  String get startLabel =>
      _localizedValues[locale.languageCode]!['start_label']!;
  String get endLabel => _localizedValues[locale.languageCode]!['end_label']!;
  String get tmtAInstructions =>
      _localizedValues[locale.languageCode]!['tmt_a_instructions']!;
  String get tmtBInstructions =>
      _localizedValues[locale.languageCode]!['tmt_b_instructions']!;
  String get wellDone => _localizedValues[locale.languageCode]!['well_done']!;
  String get testCompletedSuccess =>
      _localizedValues[locale.languageCode]!['test_completed_success']!;
  String get searchHint =>
      _localizedValues[locale.languageCode]!['search_hint']!;
  String get addPatientBtn =>
      _localizedValues[locale.languageCode]!['add_patient_btn']!;
  String get noPatients =>
      _localizedValues[locale.languageCode]!['no_patients']!;
  String get patientAdded =>
      _localizedValues[locale.languageCode]!['patient_added']!;
  String get addPatientTitle =>
      _localizedValues[locale.languageCode]!['add_patient_title']!;
  String get fullNameLabel =>
      _localizedValues[locale.languageCode]!['full_name_label']!;
  String get addBtn => _localizedValues[locale.languageCode]!['add_btn']!;
  String get cancelBtn => _localizedValues[locale.languageCode]!['cancel_btn']!;
  String get testHistory =>
      _localizedValues[locale.languageCode]!['test_history']!;
  String get filterDate =>
      _localizedValues[locale.languageCode]!['filter_date']!;
  String get noTmtFound =>
      _localizedValues[locale.languageCode]!['no_tmt_found']!;
  String get colDate => _localizedValues[locale.languageCode]!['col_date']!;
  String get colTestName =>
      _localizedValues[locale.languageCode]!['col_test_name']!;
  String get colTimeSpent =>
      _localizedValues[locale.languageCode]!['col_time_spent']!;
  String get registerTitleDoc =>
      _localizedValues[locale.languageCode]!['register_title_doc']!;
  String get confirmPassword =>
      _localizedValues[locale.languageCode]!['confirm_password']!;
  String get registerBtn =>
      _localizedValues[locale.languageCode]!['register_btn']!;
  String get alreadyAccount =>
      _localizedValues[locale.languageCode]!['already_account']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
