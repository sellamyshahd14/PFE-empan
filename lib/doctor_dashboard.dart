import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'login_page.dart';
import 'patient_details_screen.dart';
import 'patient_registration_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  void _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showAddPatientDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PatientRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _logout();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            loc.doctorDashboard,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.teal,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _showAddPatientDialog,
              icon: const Icon(Icons.person_add, color: Colors.white),
              tooltip: "Nouveau Patient",
            ),
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddPatientDialog,
          backgroundColor: Colors.teal.shade800,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            "Nouveau Patient",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Liste des Patients",
                style: GoogleFonts.cairo(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal.shade900,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getDoctorPatients(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No patients found. click + to add.",
                          style: GoogleFonts.cairo(),
                        ),
                      );
                    }
  
                    final patients = snapshot.data!.docs;
  
                    return ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient =
                            patients[index].data() as Map<String, dynamic>;
                        final pid = patient['patientIdentifier'] ?? 'No ID';
                        final firstName = patient['firstName'] ?? '';
                        final lastName = patient['lastName'] ?? '';
                        final name = "$firstName $lastName";
                        final docId = patients[index].id;
  
                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.teal,
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName.substring(0, 1).toUpperCase()
                                    : "?",
                                style: GoogleFonts.cairo(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              "ID: $pid",
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.teal,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PatientDetailsScreen(
                                    patientName: name,
                                    patientId: pid,
                                    docId: docId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
