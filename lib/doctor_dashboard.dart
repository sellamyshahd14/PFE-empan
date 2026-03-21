import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'localization.dart';
import 'services/firestore_service.dart';
import 'services/auth_service.dart';
import 'login_page.dart';
import 'patient_details_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final lastNameController = TextEditingController();
    final idController = TextEditingController();

    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc.addPatientTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: loc.firstName),
            ),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(labelText: loc.lastName),
            ),
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: loc.patientIdLogin),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  idController.text.isNotEmpty) {
                try {
                  await _firestoreService.addPatient(
                    firstName: nameController.text,
                    lastName: lastNameController.text,
                    patientIdentifier: idController.text,
                    birthDate: DateTime.now(),
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll("Exception: ", "")),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(loc.addBtn),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isRtl = loc.locale.languageCode == 'ar';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
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
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddPatientDialog,
          backgroundColor: Colors.teal,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.yourPatients,
                style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: loc.searchPatientHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getDoctorPatients(),
                  builder: (context, patientSnapshot) {
                    if (patientSnapshot.hasError) return Center(child: Text("${loc.errorLabel}: ${patientSnapshot.error}"));
                    if (patientSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    // We need to fetch ALL results to know who took DO30
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('results').where('testName', isEqualTo: 'DO30').snapshots(),
                      builder: (context, resultsSnapshot) {
                        if (resultsSnapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                        final results = resultsSnapshot.data?.docs ?? [];
                        
                        // Create a map of latest results per patientId
                        final Map<String, Map<String, dynamic>> latestResults = {};
                        for (var doc in results) {
                          final data = doc.data() as Map<String, dynamic>;
                          final String patientDocId = data['patientId'] ?? '';
                          final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                          
                          if (patientDocId.isNotEmpty) {
                            if (!latestResults.containsKey(patientDocId) || 
                                (timestamp != null && (latestResults[patientDocId]!['timestamp'] as Timestamp).compareTo(timestamp) < 0)) {
                              latestResults[patientDocId] = data;
                            }
                          }
                        }

                        // Filter patients: Must be created by doctor AND have a DO30 result
                        final filteredPatients = patientSnapshot.data!.docs.where((pDoc) {
                          final pData = pDoc.data() as Map<String, dynamic>;
                          final docId = pDoc.id;
                          final patientIdentifier = (pData['patientIdentifier'] ?? '').toString().toLowerCase();
                          final search = _searchController.text.toLowerCase();
                          
                          // Correct check: Do we have a DO30 result for this Firestore docId?
                          return latestResults.containsKey(docId) && patientIdentifier.contains(search);
                        }).toList();

                        if (filteredPatients.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                _searchController.text.isEmpty
                                    ? (isRtl ? "لم يقم أي مريض بهذا الاختبار بعد" : "Aucun patient n'a fait ce test encore")
                                    : "${loc.noMatchFound} '${_searchController.text}'",
                                style: GoogleFonts.cairo(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredPatients.length,
                          itemBuilder: (context, index) {
                            final pDoc = filteredPatients[index];
                            final patient = pDoc.data() as Map<String, dynamic>;
                            final docId = pDoc.id;
                            // final result = latestResults[docId]; // Removed per user request

                            final pid = patient['patientIdentifier'] ?? loc.unknownLabel;
                            final firstName = patient['firstName'] ?? '';
                            final lastName = patient['lastName'] ?? '';
                            final name = "$firstName $lastName";
                            
                            // final score = result?['score'] ?? 0; // Removed per user request
                            // final time = result?['timeSpent'] ?? "--"; // Removed per user request

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : "?",
                                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                  ),
                                ),
                                title: Text(name, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Text(
                                  "${loc.idLabel}: $pid",
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: Icon(isRtl ? Icons.arrow_back_ios : Icons.arrow_forward_ios, color: Colors.teal, size: 16),
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
