import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'localization.dart';
import 'doctor_dashboard.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _doctorIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _register() async {
    final loc = AppLocalizations.of(context);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.registerDoctor(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          doctorId: _doctorIdController.text.trim(),
        );

        if (user != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(loc.accountCreated)));
          // Go to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDashboard()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${loc.sttError} $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.teal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          loc.createAccount,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      loc.loginAction,
                      style: GoogleFonts.cairo(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: loc.firstName,
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? loc.requiredField : null,
                    ),
                    const SizedBox(height: 15),

                    // Last Name
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: loc.lastName,
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? loc.requiredField : null,
                    ),
                    const SizedBox(height: 15),

                    // Doctor ID
                    TextFormField(
                      controller: _doctorIdController,
                      decoration: InputDecoration(
                        labelText: loc.doctorIdLabel,
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? loc.requiredField : null,
                    ),
                    const SizedBox(height: 15),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: loc.email,
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          !val!.contains('@') ? loc.invalidLogin : null,
                    ),
                    const SizedBox(height: 15),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: loc.password,
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (val) =>
                          val!.length < 6 ? loc.requiredField : null,
                    ),
                    const SizedBox(height: 30),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                loc.createAccount,
                                style: GoogleFonts.cairo(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
