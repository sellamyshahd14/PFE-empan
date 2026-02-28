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
      'login_title': 'اختبار HADS',
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
      'test_title': 'اختبار HADS',
      'sequence_label': 'التسلسل',
      'repeat_sequence': 'كرر التسلسل',
      'listen_btn': 'استمع',
      'listening': 'أنا أستمع...',
      'next_confirm': 'التالي / تأكيد',
      'finish_test': 'إنهاء الاختبار',
      'correct_feedback': 'صحيح!',
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
      'depression': 'الاكتئاب',
      'anxiety': 'القلق',
      'state_normal': 'طبيعي',
      'state_moderate': 'معتدل',
      'state_mild': 'متوسط',
      'state_severe': 'شديد',
      'test_history': 'سجل الاختبارات (HADS)',
      'filter_by_date': 'تصفية حسب التاريخ',
      'no_tests_found': 'لم يتم العثور على اختبارات.',
      'no_tests_date': 'لم يتم العثور على اختبارات في هذا التاريخ.',
      'date_label': 'التاريخ',
      'add_patient_title': 'إضافة مريض جديد',
      'first_name': 'الاسم الشخصي',
      'last_name': 'الاسم العائلي',
      'patient_id_login': 'معرف المريض (معرف الدخول)',
      'cancel': 'إلغاء',
      'add_btn': 'إضافة',
      'your_patients': 'مرضاك',
      'search_patient_hint': 'البحث عن طريق معرف المريض',
      'no_patients_found': 'لم يتم العثور على مرضى. انقر على + للإضافة.',
      'no_match_found': 'لم يتم العثور على مرضى مطابقين لـ',
      'create_account': 'إنشاء حساب طبيب جديد',
      'patient_not_found': 'لم يتم العثور على معرف المريض. اسأل طبيبك.',
      'login_failed':
          'فشل تسجيل الدخول. تحقق من البريد الإلكتروني وكلمة المرور.',
      'register_title': 'إنشاء حساب طبيب',
      'email_label': 'البريد الإلكتروني',
      'register_btn': 'إنشاء حساب',
      'already_have_account': 'لديك حساب بالفعل؟ سجل الدخول',
      'registration_success': 'نجح التسجيل! يرجى تسجيل الدخول.',
      'registration_failed': 'فشل التسجيل',
      'work_id': 'معرف العمل',
      // HADS Questions Arabic
      'hads_q1': 'أشعر بالتوتر أو الانزعاج',
      'hads_q1_a3': 'معظم الوقت',
      'hads_q1_a2': 'غالباً',
      'hads_q1_a1': 'من وقت لآخر',
      'hads_q1_a0': 'أبداً',
      'hads_q2': 'أستمتع بنفس الأشياء التي كنت أستمتع بها سابقاً',
      'hads_q2_a0': 'نعم، تماماً كما في السابق',
      'hads_q2_a1': 'ليس بنفس القدر',
      'hads_q2_a2': 'قليلاً فقط',
      'hads_q2_a3': 'تقريباً لا شيء',
      'hads_q3': 'ينتابني شعور بالخوف كأن شيئاً فظيعاً سيحدث لي',
      'hads_q3_a3': 'نعم، بوضوح شديد',
      'hads_q3_a2': 'نعم، لكن الأمر ليس خطيراً جداً',
      'hads_q3_a1': 'قليلاً، لكنه لا يقلقني',
      'hads_q3_a0': 'أبداً',
      'hads_q4': 'أضحك بسهولة وأرى الجانب المشرق من الأمور',
      'hads_q4_a0': 'بقدر ما كنت في الماضي',
      'hads_q4_a1': 'ليس بقدر ما كنت في السابق',
      'hads_q4_a2': 'أقل بكثير من السابق',
      'hads_q4_a3': 'أبداً',
      'hads_q5': 'أشعر بالقلق',
      'hads_q5_a3': 'غالباً جداً',
      'hads_q5_a2': 'غالباً',
      'hads_q5_a1': 'أحياناً',
      'hads_q5_a0': 'نادراً جداً',
      'hads_q6': 'أشعر بأنني في حالة مزاجية جيدة',
      'hads_q6_a3': 'أبداً',
      'hads_q6_a2': 'نادراً',
      'hads_q6_a1': 'غالباً',
      'hads_q6_a0': 'معظم الوقت',
      'hads_q7': 'يمكنني الجلوس بهدوء دون فعل شيء والشعور بالاسترخاء',
      'hads_q7_a0': 'نعم، مهما حدث',
      'hads_q7_a1': 'نعم، بشكل عام',
      'hads_q7_a2': 'نادراً',
      'hads_q7_a3': 'أحياناً',
      'hads_q8': 'أشعر وكأنني أعمل ببطء',
      'hads_q8_a3': 'دائماً تقريباً',
      'hads_q8_a2': 'غالباً جداً',
      'hads_q8_a1': 'أحياناً',
      'hads_q8_a0': 'أبداً',
      'hads_q9': 'ينتابني شعور بالخوف وأشعر بضيق في المعدة',
      'hads_q9_a0': 'أبداً',
      'hads_q9_a1': 'أحياناً',
      'hads_q9_a2': 'غالباً',
      'hads_q9_a3': 'غالباً جداً',
      'hads_q10': 'لم أعد أهتم بمظهري',
      'hads_q10_a3': 'إطلاقاً',
      'hads_q10_a2': 'لا أعطيه الاهتمام الذي يجب علي إعطاؤه',
      'hads_q10_a1': 'قد لا أهتم به كما كنت سابقاً',
      'hads_q10_a0': 'أهتم به كما في السابق',
      'hads_q11': 'أشعر بالتململ ولا أستطيع البقاء في مكاني',
      'hads_q11_a3': 'نعم، هذا هو الحال تماماً',
      'hads_q11_a2': 'قليلاً',
      'hads_q11_a1': 'ليس كثيراً',
      'hads_q11_a0': 'أبداً',
      'hads_q12': 'أتطلع بلهفة للقيام ببعض الأشياء',
      'hads_q12_a0': 'بقدر ما كنت سابقاً',
      'hads_q12_a1': 'أقل قليلاً من السابق',
      'hads_q12_a2': 'أقل بكثير من السابق',
      'hads_q12_a3': 'تقريباً أبداً',
      'hads_q13': 'ينتابني شعور مفاجئ بالذعر',
      'hads_q13_a3': 'غالباً جداً',
      'hads_q13_a2': 'غالباً',
      'hads_q13_a1': 'ليس غالباً',
      'hads_q13_a0': 'أبداً',
      'hads_q14': 'يمكنني الاستمتاع بكتاب جيد أو برنامج إذاعي أو تلفزيوني',
      'hads_q14_a0': 'غالباً',
      'hads_q14_a1': 'أحياناً',
      'hads_q14_a2': 'نادراً',
      'hads_q14_a3': 'نادراً جداً',
      'error_label': 'خطأ',
      'id_label': 'المعرف',
      'unknown_label': 'غير معروف',
    },
    'fr': {
      'login_title': 'Test HADS',
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
      'test_title': 'Test HADS',
      'sequence_label': 'Séquence',
      'repeat_sequence': 'Répétez la séquence',
      'listen_btn': 'Écouter',
      'listening': 'J\'écoute...',
      'next_confirm': 'Suivant / Valider',
      'finish_test': 'Terminer le test',
      'correct_feedback': 'Correct!',
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
      'depression': 'Dépression',
      'anxiety': 'Anxiété',
      'state_normal': 'Normal',
      'state_moderate': 'Modéré',
      'state_mild': 'Moyen',
      'state_severe': 'Sévère',
      'test_history': 'Historique des tests (HADS)',
      'filter_by_date': 'Filtrer par Date',
      'no_tests_found': 'Aucun test trouvé.',
      'no_tests_date': 'Aucun test trouvé à cette date.',
      'date_label': 'Date',
      'add_patient_title': 'Ajouter un nouveau patient',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'patient_id_login': 'ID Patient (ID Connexion)',
      'cancel': 'Annuler',
      'add_btn': 'Ajouter',
      'your_patients': 'Vos Patients',
      'search_patient_hint': 'Rechercher par ID Patient',
      'no_patients_found': 'Aucun patient trouvé. Cliquez sur + pour ajouter.',
      'no_match_found': 'Aucun patient trouvé correspondant à',
      'create_account': 'Créer un nouveau compte Médecin',
      'patient_not_found': 'ID Patient non trouvé. Demandez à votre Médecin.',
      'login_failed': 'Échec de la connexion. Vérifiez l\'Email/Mot de passe.',
      'register_title': 'Créer un compte Médecin',
      'email_label': 'Email',
      'register_btn': 'Créer le compte',
      'already_have_account': 'Vous avez déjà un compte ? Connectez-vous',
      'registration_success': 'Inscription réussie ! Veuillez vous connecter.',
      'registration_failed': 'Échec de l\'inscription',
      'work_id': 'ID Travail',
      // HADS Questions French
      'hads_q1': 'Je me sens tendu ou énervé',
      'hads_q1_a3': 'La plupart du temps',
      'hads_q1_a2': 'Souvent',
      'hads_q1_a1': 'De temps en temps',
      'hads_q1_a0': 'Jamais',
      'hads_q2': 'Je prends plaisir aux mêmes choses qu\'autrefois',
      'hads_q2_a0': 'Oui, tout autant',
      'hads_q2_a1': 'Pas autant',
      'hads_q2_a2': 'Un peu seulement',
      'hads_q2_a3': 'Presque plus',
      'hads_q3':
          'J\'اي une sensation de peur comme si quelque chose d\'horrible allait m\'arriver',
      'hads_q3_a3': 'Oui, très nettement',
      'hads_q3_a2': 'Oui, mais ce n\'est pas trop grave',
      'hads_q3_a1': 'Un peu, mais cela ne m\'inquiète pas',
      'hads_q3_a0': 'Pas du tout',
      'hads_q4': 'Je ris facilement et vois le bon côté des choses',
      'hads_q4_a0': 'Autant que par le passé',
      'hads_q4_a1': 'Plus autant qu\'avant',
      'hads_q4_a2': 'Vraiment moins qu\'avant',
      'hads_q4_a3': 'Plus du tout',
      'hads_q5': 'Je me fais du souci',
      'hads_q5_a3': 'Très souvent',
      'hads_q5_a2': 'Assez souvent',
      'hads_q5_a1': 'Occasionnellement',
      'hads_q5_a0': 'Très occasionnellement',
      'hads_q6': 'Je suis de bonne humeur',
      'hads_q6_a3': 'Jamais',
      'hads_q6_a2': 'Rarement',
      'hads_q6_a1': 'Assez souvent',
      'hads_q6_a0': 'La plupart du temps',
      'hads_q7':
          'Je peux rester tranquillement assis à ne rien faire et me sentir décontracté',
      'hads_q7_a0': 'Oui, quoi qu\'il arrive',
      'hads_q7_a1': 'Oui, en général',
      'hads_q7_a2': 'Rarement',
      'hads_q7_a3': 'Parfois',
      'hads_q8': 'J\'ai l\'impression de fonctionner au ralenti',
      'hads_q8_a3': 'Presque toujours',
      'hads_q8_a2': 'Très souvent',
      'hads_q8_a1': 'Parfois',
      'hads_q8_a0': 'Jamais',
      'hads_q9': 'J\'éprouve des sensations de peur et j\'ai l\'estomac noué',
      'hads_q9_a0': 'Jamais',
      'hads_q9_a1': 'Parfois',
      'hads_q9_a2': 'Assez souvent',
      'hads_q9_a3': 'Très souvent',
      'hads_q10': 'Je ne m\'intéresse plus à mon apparence',
      'hads_q10_a3': 'Plus du tout',
      'hads_q10_a2':
          'Je n\'y accorde pas autant d\'attention que je le devrais',
      'hads_q10_a1': 'Il se peut que je n\'y fasse plus autant attention',
      'hads_q10_a0': 'J\'y prête autant d\'attention que par le passé',
      'hads_q11': 'J\'ai la bougeotte et n\'arrive pas à tenir en place',
      'hads_q11_a3': 'Oui, c\'est tout à fait le cas',
      'hads_q11_a2': 'Un peu',
      'hads_q11_a1': 'Pas tellement',
      'hads_q11_a0': 'Pas du tout',
      'hads_q12': 'Je me réjouis d\'avance à l\'idée de faire certaines choses',
      'hads_q12_a0': 'Autant qu\'avant',
      'hads_q12_a1': 'Un peu moins qu\'avant',
      'hads_q12_a2': 'Bien moins qu\'avant',
      'hads_q12_a3': 'Presque jamais',
      'hads_q13': 'J\'éprouve des sensations soudaines de panique',
      'hads_q13_a3': 'Vraiment très souvent',
      'hads_q13_a2': 'Assez souvent',
      'hads_q13_a1': 'Pas très souvent',
      'hads_q13_a0': 'Jamais',
      'hads_q14':
          'Je peux prendre plaisir à un bon livre ou à une bonne émission radio ou de télévision',
      'hads_q14_a0': 'Souvent',
      'hads_q14_a1': 'Parfois',
      'hads_q14_a2': 'Rarement',
      'hads_q14_a3': 'Très rarement',
      'error_label': 'Erreur',
      'id_label': 'ID',
      'unknown_label': 'Inconnu',
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

  String get depression =>
      _localizedValues[locale.languageCode]!['depression']!;
  String get anxiety => _localizedValues[locale.languageCode]!['anxiety']!;
  String get stateNormal =>
      _localizedValues[locale.languageCode]!['state_normal']!;
  String get stateModerate =>
      _localizedValues[locale.languageCode]!['state_moderate']!;
  String get stateMild => _localizedValues[locale.languageCode]!['state_mild']!;
  String get stateSevere =>
      _localizedValues[locale.languageCode]!['state_severe']!;
  String get testHistory =>
      _localizedValues[locale.languageCode]!['test_history']!;
  String get filterByDate =>
      _localizedValues[locale.languageCode]!['filter_by_date']!;
  String get noTestsFound =>
      _localizedValues[locale.languageCode]!['no_tests_found']!;
  String get noTestsDate =>
      _localizedValues[locale.languageCode]!['no_tests_date']!;
  String get dateLabel => _localizedValues[locale.languageCode]!['date_label']!;
  String get addPatientTitle =>
      _localizedValues[locale.languageCode]!['add_patient_title']!;
  String get firstName => _localizedValues[locale.languageCode]!['first_name']!;
  String get lastName => _localizedValues[locale.languageCode]!['last_name']!;
  String get patientIdLogin =>
      _localizedValues[locale.languageCode]!['patient_id_login']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get addBtn => _localizedValues[locale.languageCode]!['add_btn']!;
  String get yourPatients =>
      _localizedValues[locale.languageCode]!['your_patients']!;
  String get searchPatientHint =>
      _localizedValues[locale.languageCode]!['search_patient_hint']!;
  String get noPatientsFound =>
      _localizedValues[locale.languageCode]!['no_patients_found']!;
  String get noMatchFound =>
      _localizedValues[locale.languageCode]!['no_match_found']!;
  String get createAccount =>
      _localizedValues[locale.languageCode]!['create_account']!;
  String get patientNotFound =>
      _localizedValues[locale.languageCode]!['patient_not_found']!;
  String get loginFailed =>
      _localizedValues[locale.languageCode]!['login_failed']!;
  String get registerTitle =>
      _localizedValues[locale.languageCode]!['register_title']!;
  String get emailLabel =>
      _localizedValues[locale.languageCode]!['email_label']!;
  String get registerBtn =>
      _localizedValues[locale.languageCode]!['register_btn']!;
  String get alreadyHaveAccount =>
      _localizedValues[locale.languageCode]!['already_have_account']!;
  String get registrationSuccess =>
      _localizedValues[locale.languageCode]!['registration_success']!;
  String get registrationFailed =>
      _localizedValues[locale.languageCode]!['registration_failed']!;
  String get workId => _localizedValues[locale.languageCode]!['work_id']!;
  String get errorLabel =>
      _localizedValues[locale.languageCode]!['error_label']!;
  String get idLabel => _localizedValues[locale.languageCode]!['id_label']!;
  String get unknownLabel =>
      _localizedValues[locale.languageCode]!['unknown_label']!;

  String translate(String key) {
    return _localizedValues[locale.languageCode]![key] ?? key;
  }
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
