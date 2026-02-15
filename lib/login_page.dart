import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'empan.dart';
import 'doctor_dashboard.dart';

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

  void _login() {
    if (_isPatientMode) {
      // Patient Login
      if (_patientIdController.text.isNotEmpty) {
        // Any ID works for now
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StartEmpanPage(patientId: _patientIdController.text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إدخال معرف المريض')),
        );
      }
    } else {
      // Doctor Login
      final id = _doctorIdController.text;
      final pwd = _doctorPasswordController.text;

      if (id == 'admin' && pwd == 'admin') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorDashboard()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "اختبار إمبان",
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
                            "فضاء المريض",
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
                            "فضاء الطبيب",
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
                    labelText: "معرف المريض",
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
                    labelText: "المعرف",
                    labelStyle: GoogleFonts.cairo(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                  ),
                  style: GoogleFonts.cairo(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _doctorPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور",
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
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  _isPatientMode ? "دخول" : "تسجيل الدخول",
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
