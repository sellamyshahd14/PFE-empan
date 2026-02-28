import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';

class PatientDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    debugPrint("DETAILS SCREEN: Fetching results for Patient Doc ID: $docId");

    return Scaffold(
      appBar: AppBar(
        title: Text(
          patientName,
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
                        patientName.isNotEmpty
                            ? patientName[0].toUpperCase()
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
                          patientName,
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "ID: $patientId",
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
            Text(
              "Test History",
              style: GoogleFonts.cairo(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getPatientResults(docId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                            "No tests found for this patient.",
                            style: GoogleFonts.cairo(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final results = snapshot.data!.docs.toList();

                  // Sort locally to avoid requiring a composite index in Firestore
                  results.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;

                    final timestampA = dataA['timestamp'] as Timestamp?;
                    final timestampB = dataB['timestamp'] as Timestamp?;

                    if (timestampA != null && timestampB != null) {
                      return timestampB.compareTo(
                        timestampA,
                      ); // Descending order
                    }
                    return 0;
                  });

                  // 1. Group records by date
                  final Map<String, List<DocumentSnapshot>> groupedResults = {};
                  for (var doc in results) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dateStr = data['dateStr'] ?? 'Unknown Date';
                    if (!groupedResults.containsKey(dateStr)) {
                      groupedResults[dateStr] = [];
                    }
                    groupedResults[dateStr]!.add(doc);
                  }

                  // 2. We want to iterate over the dates.
                  // Because 'results' is already sorted by timestamp descending,
                  // the order we first encounter the dates is the correct chronological order of the days.
                  final sortedDates = groupedResults.keys.toList();

                  return ListView.builder(
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final dayResults = groupedResults[date]!;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Date Header
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade700,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    date,
                                    style: GoogleFonts.cairo(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // DataTable
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                  Colors.teal.shade50,
                                ),
                                columns: [
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
                                      "Criteria 1",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      "Criteria 2",
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                                rows: dayResults.map((res) {
                                  final data =
                                      res.data() as Map<String, dynamic>;
                                  final testType = data['testType'] ?? 'Empan';
                                  final duration = data['duration'] ?? '00:00';
                                  final errors = data['errors'] ?? 0;
                                  final score = data['score'] ?? 0.0;

                                  String criteria1 = "";
                                  String criteria2 = "";

                                  if (testType == "TMT-A" ||
                                      testType == "TMT-B") {
                                    criteria1 = "Time: $duration";
                                    criteria2 = "Errors: $errors";
                                  } else {
                                    criteria1 = "Score: $score pts";
                                    criteria2 = "Time: $duration";
                                  }

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Text(
                                          testType,
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            criteria1,
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            criteria2,
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),

                            // Flexibilité Mentale Calculation Footer
                            Builder(
                              builder: (context) {
                                int tmtASeconds = -1;
                                int tmtBSeconds = -1;

                                for (var res in dayResults) {
                                  final data =
                                      res.data() as Map<String, dynamic>;
                                  final testType = data['testType'] ?? '';
                                  final durationStr =
                                      data['duration'] ?? '00:00';

                                  if (testType == "TMT-A" ||
                                      testType == "TMT-B") {
                                    int seconds = 0;
                                    if (durationStr.contains('s')) {
                                      final digits = durationStr.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );
                                      seconds = int.tryParse(digits) ?? 0;
                                    } else if (durationStr.contains(':')) {
                                      final parts = durationStr.split(':');
                                      if (parts.length == 2) {
                                        final mins =
                                            int.tryParse(parts[0]) ?? 0;
                                        final secs =
                                            int.tryParse(parts[1]) ?? 0;
                                        seconds = (mins * 60) + secs;
                                      }
                                    } else {
                                      seconds = int.tryParse(durationStr) ?? 0;
                                    }

                                    if (testType == "TMT-A") {
                                      tmtASeconds = seconds;
                                    } else {
                                      tmtBSeconds = seconds;
                                    }
                                  }
                                }

                                if (tmtASeconds >= 0 && tmtBSeconds >= 0) {
                                  final diffSeconds = tmtBSeconds - tmtASeconds;
                                  final isPositive = diffSeconds >= 0;
                                  final absDiff = diffSeconds.abs();
                                  final displayMins = (absDiff ~/ 60)
                                      .toString()
                                      .padLeft(2, '0');
                                  final displaySecs = (absDiff % 60)
                                      .toString()
                                      .padLeft(2, '0');
                                  final sign = isPositive ? "" : "-";

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      border: Border(
                                        top: BorderSide(
                                          color: Colors.teal.shade100,
                                          width: 1,
                                        ),
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "🧠",
                                          style: TextStyle(fontSize: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Flexibilité Mentale : ",
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                        Text(
                                          "$sign$displayMins:$displaySecs",
                                          style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          " (TMT B - TMT A)",
                                          style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
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
    );
  }
}
