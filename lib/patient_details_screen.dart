import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientName;
  final String patientId; // Display ID (e.g., 123)
  final String docId; // Firestore Document ID

  const PatientDetailsScreen({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.docId,
  });

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  DateTime? _selectedDate;

  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    debugPrint(
      "DETAILS SCREEN: Fetching results for Patient Doc ID: ${widget.docId}",
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientName,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        widget.patientName.isNotEmpty
                            ? widget.patientName[0].toUpperCase()
                            : "?",
                        style: GoogleFonts.cairo(
                          fontSize: 24,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientName,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "ID: ${widget.patientId}",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Test History",
                  style: GoogleFonts.cairo(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, color: Colors.teal),
                  label: Text(
                    _selectedDate == null
                        ? "Filter by Date"
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                    style: GoogleFonts.cairo(color: Colors.teal),
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getPatientResults(widget.docId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var results = [];
                  if (snapshot.hasData) {
                    results = snapshot.data!.docs;
                  }

                  // CLIENT-SIDE FILTERING BY DATE
                  if (_selectedDate != null) {
                    final filterStr =
                        "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
                    results = results.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['dateStr'] == filterStr;
                    }).toList();
                  }

                  // Filter for TMT tests only
                  results = results.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final type = data['testType'] ?? '';
                    return type == 'TMT-A' || type == 'TMT-B';
                  }).toList();

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 60,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _selectedDate == null
                                ? "No TMT tests found."
                                : "No TMT tests found on this date.",
                            style: GoogleFonts.cairo(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width - 32,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.teal.shade50,
                        ),
                        columns: [
                          DataColumn(
                            label: Text(
                              "Date",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Test Name",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Time Spent",
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        rows: results.map((res) {
                          final data = res.data() as Map<String, dynamic>;
                          final testType = data['testType'] ?? 'TMT';
                          final duration = data['duration'] ?? 'N/A';

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  data['dateStr'] ?? 'Unknown',
                                  style: GoogleFonts.cairo(),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    testType,
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  duration,
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
