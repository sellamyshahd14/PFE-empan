import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  void _register() async {
    final loc = AppLocalizations.of(context);
    setState(() => _isLoading = true);
    try {
      await _authService.registerDoctor(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        doctorId: _doctorIdController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.registrationSuccess)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.registrationFailed)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = loc.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.registerTitle, style: GoogleFonts.cairo()),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: loc.firstName,
                  labelStyle: GoogleFonts.cairo(),
                ),
                style: GoogleFonts.cairo(),
              ),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: loc.lastName,
                  labelStyle: GoogleFonts.cairo(),
                ),
                style: GoogleFonts.cairo(),
              ),
              TextField(
                controller: _doctorIdController,
                decoration: InputDecoration(
                  labelText: loc.workId,
                  labelStyle: GoogleFonts.cairo(),
                ),
                style: GoogleFonts.cairo(),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: loc.emailLabel,
                  labelStyle: GoogleFonts.cairo(),
                ),
                style: GoogleFonts.cairo(),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc.doctorPwdLabel,
                  labelStyle: GoogleFonts.cairo(),
                ),
                style: GoogleFonts.cairo(),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        loc.registerBtn,
                        style: GoogleFonts.cairo(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
