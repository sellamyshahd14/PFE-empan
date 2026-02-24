import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'tmt_a_page.dart';
import 'tmt_b_page.dart';

class TestSelectionPage extends StatelessWidget {
  final String patientId;
  final String patientIdentifier;
  final String patientName;

  const TestSelectionPage({
    super.key,
    required this.patientId,
    required this.patientIdentifier,
    this.patientName = '',
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("TEST SELECTION: Identifier = $patientIdentifier");
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.selectTestTitle,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${loc.welcomeMsg}$patientName",
              textDirection: TextDirection.rtl,
              style:
                  GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 10),
            _buildTestButton(
              context,
              loc.tmtABtn,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TmtAPage(
                    patientId: patientId,
                    patientIdentifier: patientIdentifier,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.tmtBBtn,
              Colors.teal,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TmtBPage(
                    patientId: patientId,
                    patientIdentifier: patientIdentifier,
                  ),
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
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
