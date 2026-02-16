import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tests/empan/empan.dart';
import 'tests/tmt/tmt_a_page.dart';
import 'tests/tmt/tmt_b_page.dart';

class PatientHomePage extends StatelessWidget {
  final String patientId;

  const PatientHomePage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "فضاء المريض",
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
              "اختر الاختبار",
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
              "اختبار إمبان",
              Icons.graphic_eq,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StartEmpanPage(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              "اختبار TMT-A",
              Icons.timeline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TmtAPage(patientId: patientId),
                ),
              ),
            ),
            _buildTestButton(
              context,
              "اختبار TMT-B",
              Icons.timeline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TmtBPage(patientId: patientId),
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
}
