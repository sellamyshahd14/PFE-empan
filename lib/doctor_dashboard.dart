import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'services/security_service.dart';
import 'login_page.dart';
import 'patient_details_screen.dart';
import 'patient_registration_screen.dart';
import 'register_page.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  String _searchQuery = "";
  String? _selectedDoctorId; // null = "Tous", otherwise UID
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _selectedDoctorId = _authService.currentUser?.uid;
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _authService.isCurrentUserAdmin();
    if (mounted) {
      setState(() => _isAdmin = isAdmin);
    }
  }

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

  Future<void> _performBackup() async {
    try {
      // 1. Fetch data
      final data = await _firestoreService.getAllDataForBackup();
      final jsonString = jsonEncode(data);

      if (kIsWeb) {
        // For Web, we can't easily write to local disk without dart:html
        // We will show the JSON in a dialog or suggest printing/copying for now
        // if the user is truly in a browser.
        _showBackupDataDialog(jsonString);
        return;
      }

      // 2. Desktop logic (Windows/Mac/Linux)
      // Use getApplicationDocumentsDirectory which is more reliable on Desktop
      final directory = await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/empan_backup_$timestamp.json');

      // 3. Write file
      await file.writeAsString(jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sauvegarde réussie ! Fichier : empan_backup_$timestamp.json dans vos Documents.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showBackupDataDialog(String json) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Données de Sauvegarde (Web)"),
        content: SingleChildScrollView(child: SelectableText(json)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showAddPatientDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PatientRegistrationScreen(),
      ),
    );
  }

  void _showRegisterPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterPage()),
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
            // Admin only: Backup and Add doctor
            if (_isAdmin) ...[
              IconButton(
                icon: const Icon(Icons.save_alt, color: Colors.white),
                tooltip: "Sauvegarde de Sécurité",
                onPressed: _performBackup,
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _showRegisterPage,
                icon: const Icon(
                  Icons.person_add_alt_1,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  loc.translate('add_doctor'),
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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

              // --- Search and Filter Bar ---
              Row(
                children: [
                  // Search Bar
                  Expanded(
                    flex: 2,
                    child: TextField(
                      onChanged: (val) =>
                          setState(() => _searchQuery = val.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Rechercher (Nom ou ID)...",
                        hintStyle: GoogleFonts.cairo(fontSize: 14),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.teal,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal.shade100),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.teal.shade50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Doctor Filter
                  Expanded(
                    flex: 1,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getAllDoctors(),
                      builder: (context, snapshot) {
                        List<DropdownMenuItem<String?>> items = [
                          DropdownMenuItem(
                            value: null,
                            child: Text(
                              "Tous",
                              style: GoogleFonts.cairo(fontSize: 13),
                            ),
                          ),
                        ];

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final name =
                                "Dr. ${data['firstName'] ?? ''} ${data['lastName'] ?? ''}";
                            final uid = data['uid'];

                            // Check if this is the current doctor to label it "Mes patients"
                            final label = (uid == _authService.currentUser?.uid)
                                ? "Mes patients"
                                : name;

                            items.add(
                              DropdownMenuItem(
                                value: uid,
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 13),
                                ),
                              ),
                            );
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade100),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedDoctorId,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.filter_list,
                                color: Colors.teal,
                                size: 20,
                              ),
                              onChanged: (val) =>
                                  setState(() => _selectedDoctorId = val),
                              items: items,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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

                    final allPatients = snapshot.data!.docs;

                    // Filter logic
                    final patients = allPatients.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      // 1. Doctor Filter
                      if (_selectedDoctorId != null &&
                          data['createdByDoctorId'] != _selectedDoctorId) {
                        return false;
                      }

                      // 2. Search Query
                      if (_searchQuery.isNotEmpty) {
                        final firstName = (data['firstName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final lastName = (data['lastName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final pidRaw = (data['patientDisplayId'] ?? data['patientIdentifier'] ?? '')
                            .toString();
                        final pid = SecurityService.decryptIdentifier(pidRaw)
                            .toLowerCase();
                        final fullName = "$firstName $lastName";

                        return fullName.contains(_searchQuery) ||
                            pid.contains(_searchQuery);
                      }

                      return true;
                    }).toList();

                    if (patients.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? "Aucun patient trouvé."
                              : "Aucun résultat pour '$_searchQuery'",
                          style: GoogleFonts.cairo(),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient =
                            patients[index].data() as Map<String, dynamic>;
                        final pidRaw = patient['patientDisplayId'] ?? patient['patientIdentifier'] ?? 'No ID';
                        final pid = SecurityService.decryptIdentifier(pidRaw);
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
