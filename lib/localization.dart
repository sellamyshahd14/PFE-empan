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
      'zero': 'صفر',
      'one': 'واحد',
      'two': 'اثنان',
      'three': 'ثلاثة',
      'four': 'أربعة',
      'five': 'خمسة',
      'six': 'ستة',
      'seven': 'سبعة',
      'eight': 'ثمانية',
      'nine': 'تسعة',
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
      'empan_test': 'اختبار إمبان المباشر',
      'choose_test': 'اختر الاختبار',
      'bravo': 'أحسنت!',
      'test_success': 'لقد أتممت الاختبار بنجاح.',
      'start_node': 'بداية',
      'end_node': 'نهاية',
      'empan_direct_intro':
          'سوف تسمع سلسلة من الأرقام. استمع جيداً وكررها بنفس الترتيب. يرجى التحدث فقط عندما يصبح لون الأيقونة برتقالياً وتسمع "فلنبدأ".',
      'empan_inverse_intro':
          'سوف تسمع سلسلة من الأرقام. استمع جيداً وكررها بالترتيب العكسي. يرجى التحدث فقط عندما يصبح لون الأيقونة برتقالياً وتسمع "فلنبدأ".',
      'tmt_a_instr':
          'اضغط على الأرقام بالترتيب من 1 إلى 25.\nاضغط على 1 للبدء.',
      'tmt_b_instr':
          'صِل بالترتيب مع التناوب: 1 (أبيض) ← 1 (أخضر) ← 2 (أبيض) ← 2 (أخضر) ← 3 (أبيض)...',
      'tmt_c_title': 'اختبار TMT-C',
      'tmt_c_instr':
          'اربط بالتناوب: 1 \u200F← A \u200F← 2 \u200F← B \u200F← 3 \u200F← C ... اضغط على 1 للبدء.',
      'empan_inverse_test': 'اختبار إمبان العكسي',
      'dsm48_title': 'اختبار DSM-48',
      'dsm48_menu_encodage': 'مرحلة الحفظ (الترميز)',
      'dsm48_menu_set1': 'المجموعة 1',
      'dsm48_menu_set2': 'المجموعة 2',
      'dsm48_menu_set3': 'المجموعة 3',
      'dsm48_encodage_instr': 'ركز على الـ 48 صورة واحفظها.',
      'dsm48_finish_encodage': 'إنهاء الحفظ',
      'dsm48_image_counter': 'صورة {} / 48',
      'dsm48_set_instr': 'اختر الصورة التي حفظتها سابقاً',
      'dsm48_score': 'النتيجة: {}/48',
      'dsm48_encodage_question': 'ما هو اللون الذي تراه؟',
      'dsm48_listening': 'أنا أستمع...',
      'dsm48_mic_btn_tooltip': 'اضغط للتحدث',
      'dsm48_voice_error': 'يرجى الإجابة قبل الانتقال',
      // HADS
      'hads_test_title': 'اختبار HADS',
      'depression': 'الاكتئاب',
      'anxiety': 'القلق',
      'state_normal': 'طبيعي',
      'state_moderate': 'معتدل',
      'state_mild': 'متوسط',
      'state_severe': 'شديد',
      'hads_q1': 'نحس روحي على أعصابي و متوتر',
      'hads_q1_a3': 'دائما',
      'hads_q1_a2': 'أغلب الأوقات',
      'hads_q1_a1': 'مرّات',
      'hads_q1_a0': 'لا أبدا',
      'hads_q2': 'نستمتع بنفس الحوايج متاع قبل',
      'hads_q2_a0': 'نعم كيف العادة',
      'hads_q2_a1': 'لا موش ياسر',
      'hads_q2_a2': 'شوية شوية',
      'hads_q2_a3': 'تقريبا بالكلّ',
      'hads_q3': 'نحس بالخوف كأنه حاجة مرعبة باش تصير',
      'hads_q3_a3': 'نعم بالضبط',
      'hads_q3_a2': 'نعم أما ما ثماش خطر كبير',
      'hads_q3_a1': 'شوية، أما موش متقلق من الحكاية',
      'hads_q3_a0': 'لا أبدا',
      'hads_q4': 'نضحك بسهولة ونشوف الناحية الإيجابية من الأشياء',
      'hads_q4_a0': 'نعم كيف العادة',
      'hads_q4_a1': 'موش كيف العادة',
      'hads_q4_a2': 'أقل ياسر من العادة',
      'hads_q4_a3': 'لا أبدا',
      'hads_q5': 'نخمم ونشغل روحي',
      'hads_q5_a3': 'دائما',
      'hads_q5_a2': 'أغلب الأوقات',
      'hads_q5_a1': 'مرات',
      'hads_q5_a0': 'نادرا',
      'hads_q6': 'نحس روحي مفرهد ومزاجي رائق',
      'hads_q6_a0': 'لا أبدا',
      'hads_q6_a1': 'نادرا',
      'hads_q6_a2': 'أغلب الأوقات',
      'hads_q6_a3': 'دائما',
      'hads_q7': 'نجم نقعد مرتاح ما نعمل شيء و نحس روحي مسترخي',
      'hads_q7_a0': 'نعم، مهما كانت الظروف',
      'hads_q7_a1': 'نعم في أغلب الأوقات',
      'hads_q7_a2': 'نادرا',
      'hads_q7_a3': 'لا أبدا',
      'hads_q8': 'نحس إني نمارس نشاطي بنسق بطيء على العادة',
      'hads_q8_a3': 'تقريبا دائما',
      'hads_q8_a2': 'أغلب الأوقات',
      'hads_q8_a1': 'مرّات',
      'hads_q8_a0': 'لا أبدا',
      'hads_q9': 'نحس بالخوف و معدتي معقودة',
      'hads_q9_a0': 'لا أبدا',
      'hads_q9_a1': 'مرّات',
      'hads_q9_a2': 'ياسر',
      'hads_q9_a3': 'دائما',
      'hads_q10': 'ما عدتش نهتم بمظهري الخارجي',
      'hads_q10_a3': 'لا أبدا',
      'hads_q10_a2': 'موش كيف ما يلزم',
      'hads_q10_a1': 'ممكن ساعات ما عدتش نهتم به',
      'hads_q10_a0': 'نهتم كالعادة',
      'hads_q11': 'نحس روحي ما نجمش نركح في بلاصة',
      'hads_q11_a3': 'نعم بالضبط',
      'hads_q11_a2': 'شوية',
      'hads_q11_a1': 'شوية بالكل',
      'hads_q11_a0': 'لا أبدا',
      'hads_q12': 'نشيخ بالمسبق كيف نعرف روحي باش نعمل بعض الأشياء',
      'hads_q12_a0': 'كيف العادة',
      'hads_q12_a1': 'أقل شوية من العادة',
      'hads_q12_a2': 'أقل ياسر من العادة',
      'hads_q12_a3': 'لا أبدا',
      'hads_q13': 'نحس بحالات رعب مفاجئ',
      'hads_q13_a3': 'دائما',
      'hads_q13_a2': 'ياسر مرّات',
      'hads_q13_a1': 'موش ياسر ياسر',
      'hads_q13_a0': 'لا أبدا',
      'hads_q14':
          'نجم نستمتع بقراءة كتاب باهي أو بالاستماع لبرنامج باهي في التلفزة و الراديو',
      'hads_q14_a0': 'دائما',
      'hads_q14_a1': 'مرات',
      'hads_q14_a2': 'نادرا',
      'hads_q14_a3': 'نادر جدا',
      'hads_instruction': 'من فضلك قم باختيار الإجابة المناسبة بالضغط عليها',
      'hads_intro_text':
          'يرجى الإجابة وفقًا لحالتك النفسية خلال الأسبوعين الماضيين، وإذا كان العرض المذكور موجودًا معظم الوقت.',
      'on_commence_cue': 'فلنبدأ',
      'attempts_label': 'المحاولات: {}/3',
      'max_attempts_reached': 'وصلت إلى الحد الأقصى للمحاولات',
      'speak_btn': 'تحدث',
      'do30_title': 'Test DO-30',
      'do30_instr': 'قل بصوت عالٍ ما تراه في الصورة.',
      'do30_correct': 'صحيح!',
      'do30_wrong': 'غير صحيح. حاول مرة أخرى أو تجاوز.',
      'do30_image_counter': 'صورة {} / 30',
      'manual_input_hint': 'إدخال يدوي',
      'manual_input_title': 'إدخال يدوي',
      'manual_input_instr': 'أدخل الأرقام بالترتيب',
      'cancel': 'إلغاء',
      'exitWithoutSaving': 'الخروج بدون حفظ',
      'exitConfirmBody': 'سيتم فقدان تقدمك.',
      'clearAndRetry': 'مسح وإعادة المحاولة',
      'done_listening': 'انتهيت',
      'stt_error': 'خطأ في التعرف على الصوت: ',
      'write_answer': 'اكتب الإجابة هنا...',
      'image_not_found_error': 'الصورة {} غير موجودة',
      'patient_not_found': 'معرف المريض غير موجود. اسأل طبيبك.',
      'login_failed':
          'فشل تسجيل الدخول. تحقق من البريد الإلكتروني/كلمة المرور.',
      'create_doctor_account': 'إنشاء حساب طبيب جديد',
      'first_name': 'الاسم الأول',
      'last_name': 'اللقب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'required': 'مطلوب',
      'create_account': 'إنشاء حساب',
      'account_created': 'تم إنشاء الحساب بنجاح!',
      'add_doctor': 'إضافة طبيب',
      'do30_dont_know': 'لا أعرف',
      'do30_forgot': 'أعرفه و طار عليّ اسمه',
      'validate': 'تأكيد',
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
      'zero': 'zéro',
      'one': 'un',
      'two': 'deux',
      'three': 'trois',
      'four': 'quatre',
      'five': 'cinq',
      'six': 'six',
      'seven': 'sept',
      'eight': 'huit',
      'nine': 'neuf',
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
      'empan_test': 'Test d\'Empan Direct',
      'choose_test': 'Choisissez le test',
      'bravo': 'Bravo !',
      'test_success': 'Vous avez terminé le test avec succès.',
      'start_node': 'Début',
      'end_node': 'Fin',
      'empan_direct_intro':
          'Vous allez entendre une série de chiffres. Écoutez attentivement et répétez-les dans le même ordre. Veuillez parler uniquement lorsque l\'icône devient orange et que vous entendez "On commence".',
      'empan_inverse_intro':
          'Vous allez entendre une série de chiffres. Écoutez attentivement et répétez-les dans l\'ordre inverse. Veuillez parler uniquement lorsque l\'icône devient orange et que vous entendez "On commence".',
      'tmt_a_instr':
          'Appuyez sur les nombres dans l\'ordre de 1 à 25.\nAppuyez sur 1 pour commencer.',
      'tmt_b_instr':
          'Reliez dans l\'ordre en alternant : 1 (blanc) → 1 (vert) → 2 (blanc) → 2 (vert) → 3 (blanc)...',
      'tmt_c_title': 'Test TMT-C',
      'tmt_c_instr':
          'Reliez en alternant : 1 → A → 2 → B → 3 → C... Appuyez sur 1 pour commencer.',
      'empan_inverse_test': 'Test d\'Empan Inverse',
      'dsm48_title': 'Test DSM-48',
      'dsm48_menu_encodage': 'Phase d\'encodage',
      'dsm48_menu_set1': 'Set 1',
      'dsm48_menu_set2': 'Set 2',
      'dsm48_menu_set3': 'Set 3',
      'dsm48_encodage_instr':
          'Concentrez-vous sur les 48 images et mémorisez-les.',
      'dsm48_finish_encodage': 'Terminer la mémorisation',
      'dsm48_image_counter': 'Image {} / 48',
      'dsm48_set_instr': 'Choisissez l\'image que vous avez mémorisée',
      'dsm48_score': 'Score : {}/48',
      'dsm48_encodage_question': 'Quelle couleur voyez-vous ?',
      'dsm48_listening': 'Je vous écoute...',
      'dsm48_mic_btn_tooltip': 'Appuyez pour parler',
      'dsm48_voice_error': 'Veuillez répondre avant de continuer',
      // HADS
      'hads_test_title': 'Test HADS',
      'depression': 'Dépression',
      'anxiety': 'Anxiété',
      'state_normal': 'Normal',
      'state_moderate': 'Modéré',
      'state_mild': 'Moyen',
      'state_severe': 'Sévère',
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
          'J\'ai une sensation de peur comme si quelque chose d\'horrible allait m\'arriver',
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
      'hads_instruction':
          'Veuillez choisir la réponse appropriée en cliquant dessus',
      'hads_intro_text':
          'Veuillez répondre en fonction de votre état psychologique au cours des deux dernières semaines, et si le symptôme mentionné était présent la plupart du temps.',
      'on_commence_cue': 'On commence',
      'attempts_label': 'Essais: {}/3',
      'max_attempts_reached': 'Maximum d\'essais atteint',
      'speak_btn': 'Parler',
      'do30_title': 'Test DO-30',
      'do30_instr': 'Dites à haute voix ce que vous voyez sur l\'image.',
      'do30_correct': 'Correct !',
      'do30_wrong': 'Incorrect. Essayez encore ou passez.',
      'do30_image_counter': 'Image {} / 30',
      'manual_input_hint': 'Saisie manuelle',
      'manual_input_title': 'Saisie manuelle',
      'manual_input_instr': 'Tapez les chiffres dans l\'ordre',
      'cancel': 'Annuler',
      'exitWithoutSaving': 'Quitter sans enregistrer',
      'exitConfirmBody': 'Votre progression sera perdue.',
      'clearAndRetry': 'Effacer et réessayer',
      'done_listening': 'J\'ai terminé',
      'stt_error': 'Erreur STT: ',
      'write_answer': 'Écrire la réponse ici...',
      'image_not_found_error': 'Image {} non trouvée',
      'patient_not_found': 'ID Patient non trouvé. Demandez à votre Docteur.',
      'login_failed': 'Échec de la connexion. Vérifiez l\'email/mot de passe.',
      'create_doctor_account': 'Créer un nouveau compte Docteur',
      'first_name': 'Prénom',
      'last_name': 'Nom',
      'email': 'Email',
      'password': 'Mot de passe',
      'required': 'Champs requis',
      'create_account': 'Créer un compte',
      'account_created': 'Compte créé avec succès !',
      'add_doctor': 'Ajout Médecin',
      'do30_dont_know': 'Je ne connais pas',
      'do30_forgot': 'Je connais mais j\'ai oublié',
      'validate': 'Valider',
    },
  };

  String _get(String key) => _localizedValues[locale.languageCode]![key]!;

  String get loginTitle => _get('login_title');
  String get patientSpace => _get('patient_space');
  String get doctorSpace => _get('doctor_space');
  String get patientIdLabel => _get('patient_id_label');
  String get patientIdHint => _get('patient_id_hint');
  String get doctorIdLabel => _get('doctor_id_label');
  String get doctorPwdLabel => _get('doctor_pwd_label');
  String get loginBtn => _get('login_btn');
  String get loginAction => _get('login_action');
  String get invalidLogin => _get('invalid_login');
  String get welcome => _get('welcome');
  String get startTest => _get('start_test');
  String get testTitle => _get('test_title');
  String get sequenceLabel => _get('sequence_label');
  String get repeatSequence => _get('repeat_sequence');
  String get listenBtn => _get('listen_btn');
  String get listening => _get('listening');
  String get nextConfirm => _get('next_confirm');
  String get finishTest => _get('finish_test');
  String get correctFeedback => _get('correct_feedback');
  String get wrongFeedback => _get('wrong_feedback');
  String get heard => _get('heard');
  String get zero => _get('zero');
  String get one => _get('one');
  String get two => _get('two');
  String get three => _get('three');
  String get four => _get('four');
  String get five => _get('five');
  String get six => _get('six');
  String get seven => _get('seven');
  String get eight => _get('eight');
  String get nine => _get('nine');
  String get testFinishedTitle => _get('test_finished_title');
  String get testFinishedMsg => _get('test_finished_msg');
  String get mainMenu => _get('main_menu');
  String get doctorDashboard => _get('doctor_dashboard');
  String get recentResults => _get('recent_results');
  String get idPrefix => _get('id_prefix');
  String get resultPrefix => _get('result_prefix');
  String get timePrefix => _get('time_prefix');
  String get datePrefix => _get('date_prefix');
  String get playBtn => _get('play_btn');
  String get validateBtn => _get('validate_btn');
  String get nextBtn => _get('next_btn');
  String get validateFirstMsg => _get('validate_first_msg');
  String get tmtATitle => _get('tmt_a_title');
  String get tmtBTitle => _get('tmt_b_title');
  String get tmtCTitle => _get('tmt_c_title');
  String get tmtCInstr => _get('tmt_c_instr');
  String get empanTest => _get('empan_test');
  String get chooseTest => _get('choose_test');
  String get bravo => _get('bravo');
  String get testSuccess => _get('test_success');
  String get startNode => _get('start_node');
  String get endNode => _get('end_node');
  String get addDoctor => _get('add_doctor');
  String get do30DontKnow => _get('do30_dont_know');
  String get do30Forgot => _get('do30_forgot');
  String get validate => _get('validate');
  String get empanDirectIntro => _get('empan_direct_intro');
  String get empanInverseIntro => _get('empan_inverse_intro');
  String get tmtAInstr => _get('tmt_a_instr');
  String get tmtBInstr => _get('tmt_b_instr');
  String get exitWithoutSaving => _get('exitWithoutSaving');
  String get exitConfirmBody => _get('exitConfirmBody');
  String get clearAndRetry => _get('clearAndRetry');
  String get doneListening => _get('done_listening');
  String get patientNotFound => _get('patient_not_found');
  String get loginFailed => _get('login_failed');
  String get createDoctorAccount => _get('create_doctor_account');
  String get firstName => _get('first_name');
  String get lastName => _get('last_name');
  String get email => _get('email');
  String get password => _get('password');
  String get requiredField => _get('required');
  String get createAccount => _get('create_account');
  String get accountCreated => _get('account_created');
  String get imageNotFoundError => _get('image_not_found_error');
  String get sttError => _get('stt_error');
  String get writeAnswer => _get('write_answer');
  String get empanInverseTest => _get('empan_inverse_test');
  String get dsm48Title => _get('dsm48_title');
  String get dsm48MenuEncodage => _get('dsm48_menu_encodage');
  String get dsm48MenuSet1 => _get('dsm48_menu_set1');
  String get dsm48MenuSet2 => _get('dsm48_menu_set2');
  String get dsm48MenuSet3 => _get('dsm48_menu_set3');
  String get dsm48EncodageInstr => _get('dsm48_encodage_instr');
  String get dsm48FinishEncodage => _get('dsm48_finish_encodage');
  String get dsm48ImageCounter => _get('dsm48_image_counter');
  String get dsm48SetInstr => _get('dsm48_set_instr');
  String get dsm48Score => _get('dsm48_score');
  String get dsm48EncodageQuestion => _get('dsm48_encodage_question');
  String get dsm48Listening => _get('dsm48_listening');
  String get dsm48MicBtnTooltip => _get('dsm48_mic_btn_tooltip');
  String get dsm48VoiceError => _get('dsm48_voice_error');
  String get hadsTestTitle => _get('hads_test_title');
  String get depression => _get('depression');
  String get anxiety => _get('anxiety');
  String get stateNormal => _get('state_normal');
  String get stateModerate => _get('state_moderate');
  String get stateMild => _get('state_mild');
  String get stateSevere => _get('state_severe');
  String get hadsIntroText => _get('hads_intro_text');
  String get hadsInstruction => _get('hads_instruction');
  String get onCommenceCue => _get('on_commence_cue');
  String get attemptsLabel => _get('attempts_label');
  String get maxAttemptsReached => _get('max_attempts_reached');
  String get speakBtn => _get('speak_btn');
  String get do30Title => _get('do30_title');
  String get do30Instr => _get('do30_instr');
  String get do30Correct => _get('do30_correct');
  String get do30Wrong => _get('do30_wrong');
  String get do30ImageCounter => _get('do30_image_counter');
  String get manualInputHint => _get('manual_input_hint');
  String get manualInputTitle => _get('manual_input_title');
  String get manualInputInstr => _get('manual_input_instr');
  String get cancel => _get('cancel');

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
