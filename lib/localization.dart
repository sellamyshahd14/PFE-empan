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
      'login_title': 'اختبار الاداء المعرفي',
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
      'test_title': 'اختبار إمبان المباشر',
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
      'validate_first_msg': 'يرجى تأكيد الإجابة أولاً',
      'tmt_a_title': 'اختبار TMT-A',
      'tmt_b_title': 'اختبار TMT-B',
      'empan_test': 'اختبار إمبان',
      'choose_test': 'اختر الاختبار',
      'bravo': 'أحسنت!',
      'test_success': 'لقد أتممت الاختبار بنجاح.',
      'start_node': 'بداية',
      'end_node': 'نهاية',
      'tmt_a_instr':
          'اضغط على الأرقام بالترتيب من 1 إلى 25.\nاضغط على 1 للبدء.',
      'tmt_b_instr':
          'اربط الأرقام بالترتيب مع التناوب بين الألوان.\n1 (أبيض) -> 2 (أزرق) -> 3 (أبيض) -> 4 (أزرق)...',
    },
    'fr': {
      'login_title': 'Test de Performance Cognitive',
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
      'test_title': 'Test d\'Empan Direct',
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
      'tmt_a_title': 'Test TMT-A',
      'tmt_b_title': 'Test TMT-B',
      'empan_test': 'Test d\'Empan',
      'choose_test': 'Choisissez le test',
      'bravo': 'Bravo !',
      'test_success': 'Vous avez terminé le test avec succès.',
      'start_node': 'Début',
      'end_node': 'Fin',
      'tmt_a_instr':
          'Appuyez sur les nombres dans l\'ordre de 1 à 25.\nAppuyez sur 1 pour commencer.',
      'tmt_b_instr':
          'Reliez les nombres dans l\'ordre en alternant les couleurs.\n1 (Blanc) -> 2 (Bleu) -> 3 (Blanc) -> 4 (Bleu)...',
    },
  };

  String get loginTitle =>
      _localizedValues[locale.languageCode]!['login_title']!;
  // ... (omitting middle lines for brevity in thought, but tool needs exact context)
  // Actually, I can use a smaller chunk for the map and another for the getter.

  // Chunk 1: Add key to 'fr' map (since 'ar' was maybe added? No, let's check again.)
  // In step 227 it failed. In step 228 it succeeded for 'ar' but failed for 'fr'?
  // Looking at the file content in Step 239:
  // Lines 49-50: 'validate_btn', 'next_btn' are there in 'ar'.
  // Line 51: 'validate_first_msg' IS MISSING in 'ar'.
  // Lines 87-88: 'validate_btn', 'next_btn' are there in 'fr'.
  // Line 89: 'validate_first_msg' IS MISSING in 'fr'.

  // So I need to add it to BOTH.

  // Chunk 3: Add getter.
  // Line 148: String get nextBtn ...
  // I need to add String get validateFirstMsg ...

  // Let's do it in one go if possible, or multiple chunks.

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
  String get tmtATitle =>
      _localizedValues[locale.languageCode]!['tmt_a_title']!;
  String get tmtBTitle =>
      _localizedValues[locale.languageCode]!['tmt_b_title']!;
  String get empanTest => _localizedValues[locale.languageCode]!['empan_test']!;
  String get chooseTest =>
      _localizedValues[locale.languageCode]!['choose_test']!;
  String get bravo => _localizedValues[locale.languageCode]!['bravo']!;
  String get testSuccess =>
      _localizedValues[locale.languageCode]!['test_success']!;
  String get startNode => _localizedValues[locale.languageCode]!['start_node']!;
  String get endNode => _localizedValues[locale.languageCode]!['end_node']!;
  String get tmtAInstr =>
      _localizedValues[locale.languageCode]!['tmt_a_instr']!;
  String get tmtBInstr =>
      _localizedValues[locale.languageCode]!['tmt_b_instr']!;
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
