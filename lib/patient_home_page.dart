import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'localization.dart';
import 'tests/empan_direct.dart';
import 'tests/empan_inverse.dart';
import 'tests/tmt_a_page.dart';
import 'tests/tmt_b_page.dart';
import 'tests/hads.dart';
import 'tests/dsm48_menu.dart';

class PatientHomePage extends StatelessWidget {
  final String patientId;

  const PatientHomePage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          loc.patientSpace,
          style: GoogleFonts.cairo(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
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
              loc.empanTest,
              Icons.graphic_eq,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EmpanDirect(patientName: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.empanInverseTest,
              Icons.sync_alt, // Represents inversed action
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EmpanInverseDirect(patientName: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.hadsTestTitle,
              Icons.psychology,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TestHADS(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.tmtATitle,
              Icons.timeline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TmtAPage(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.tmtBTitle,
              Icons.timeline,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TmtBPage(patientId: patientId),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTestButton(
              context,
              loc.dsm48Title,
              Icons.grid_view,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Dsm48MenuPage(patientId: patientId),
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
