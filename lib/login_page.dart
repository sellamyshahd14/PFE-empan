import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patient_home_page.dart';
import 'doctor_dashboard.dart';
import 'localization.dart';
import 'main.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Toggle state: true = Patient, false = Doctor
  bool _isPatientMode = true;

  // Controllers
  final TextEditingController _patientIdController = TextEditingController();
  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _doctorPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  void _login() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    if (_isPatientMode) {
      // Patient Login by ID
      final pid = _patientIdController.text.trim();
      if (pid.isNotEmpty) {
        try {
          final patientData = await _firestoreService.getPatientById(pid);
          if (patientData != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PatientHomePage(
                  patientDocId: patientData['docId'],
                  patientIdentifier: patientData['patientIdentifier'] ?? "Unknown",
                ),
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Patient ID not found. ask your Doctor."),
              ),
            );
          }
        } catch (e) {
          debugPrint("Login Error: $e");
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.patientIdHint)));
      }
    } else {
      // Doctor Login
      final id = _doctorIdController.text
          .trim(); // We treat this as Email for now or need lookup
      final pwd = _doctorPasswordController.text.trim();

      // NOTE: For now, I will assume the user enters EMAIL in the ID field for simplicity with Firebase Auth,
      // OR we can query Firestore to find the email associated with the 'DoctorID'.
      // Let's stick to Email for login to be standard.

      try {
        final user = await _authService.signIn(id, pwd);
        if (user != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Login Failed. Check Email/Password.")),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: currentLocale.languageCode,
              icon: const Icon(Icons.language, color: Colors.teal),
              underline: Container(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  MainApp.setLocale(context, Locale(newValue));
                }
              },
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.loginTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 40),

                // Toggle Buttons
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPatientMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: _isPatientMode
                                  ? Colors.teal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              loc.patientSpace,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: _isPatientMode
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: _isPatientMode
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPatientMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            decoration: BoxDecoration(
                              color: !_isPatientMode
                                  ? Colors.teal
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              loc.doctorSpace,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: !_isPatientMode
                                    ? Colors.white
                                    : Colors.black54,
                                fontWeight: !_isPatientMode
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Forms
                if (_isPatientMode) ...[
                  TextFormField(
                    controller: _patientIdController,
                    decoration: InputDecoration(
                      labelText: loc.patientIdLabel,
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                ] else ...[
                  TextFormField(
                    controller: _doctorIdController,
                    decoration: InputDecoration(
                      labelText: loc.doctorIdLabel,
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(
                        Icons.admin_panel_settings_outlined,
                      ),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _doctorPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: loc.doctorPwdLabel,
                      labelStyle: GoogleFonts.cairo(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    style: GoogleFonts.cairo(),
                  ),
                ],

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isPatientMode ? loc.loginBtn : loc.loginAction,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                if (!_isPatientMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: Text(
                        "Create new Doctor Account",
                        style: GoogleFonts.cairo(color: Colors.teal),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
