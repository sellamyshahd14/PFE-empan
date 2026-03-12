import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../localization.dart';
import 'dsm48_encodage.dart';
import 'dsm48_set1.dart';
import 'dsm48_set2.dart';
import 'dsm48_set3.dart';

class Dsm48MenuPage extends StatelessWidget {
  final String patientId;

  const Dsm48MenuPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          loc.dsm48Title,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.chooseTest,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 40),
            _buildTestButton(
              context,
              loc.dsm48MenuEncodage,
              Icons.visibility,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Dsm48EncodagePage(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.dsm48MenuSet1,
              Icons.quiz,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Dsm48Set1Page(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.dsm48MenuSet2,
              Icons.quiz_outlined,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Dsm48Set2Page(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.dsm48MenuSet3,
              Icons.quiz_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Dsm48Set3Page(patientId: patientId),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 15),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledButton(BuildContext context, String title) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Bientôt disponible / قريبا",
              style: GoogleFonts.cairo(),
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 28),
          const SizedBox(width: 15),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
