import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/tmt_visualizer.dart';
import 'widgets/bi_dashboard/patient_analytics_dashboard.dart';
import 'services/firestore_service.dart';
import 'localization.dart';
import 'services/pdf_export_service.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientName;
  final String patientId;
  final String docId;

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
  String? _selectedDateFilter;

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    debugPrint(
      "DETAILS SCREEN: Fetching results for Patient Doc ID: ${widget.docId}",
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.patientName,
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.teal.shade100,
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: "Historique", icon: Icon(Icons.history)),
              Tab(text: "Dashboard BI", icon: Icon(Icons.analytics)),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getPatientResults(widget.docId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final bool hasData =
                snapshot.hasData && snapshot.data!.docs.isNotEmpty;

            return Padding(
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
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: History
                        if (!hasData)
                          _buildEmptyState()
                        else
                          Column(
                            children: [
                              _buildDateFilter(snapshot.data!.docs.toList()),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildHistoryList(
                                  snapshot.data!.docs.toList(),
                                ),
                              ),
                            ],
                          ),

                        // Tab 2: Dashboard BI
                        if (!hasData)
                          _buildEmptyState()
                        else
                          PatientAnalyticsDashboard(
                            patientId: widget.patientId,
                            docs: snapshot.data!.docs.toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            "Aucune donnée disponible.",
            style: GoogleFonts.cairo(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter(List<QueryDocumentSnapshot> docs) {
    final Set<String> dates = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['timestamp'] as Timestamp?;
      return ts != null
          ? "${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}"
          : "Inconnu";
    }).toSet();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_view_day, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Text(
            "Filtrer par session : ",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: _selectedDateFilter,
                isExpanded: true,
                hint: Text(
                  "Toutes les sessions",
                  style: GoogleFonts.cairo(fontSize: 13),
                ),
                onChanged: (val) => setState(() => _selectedDateFilter = val),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(
                      "Toutes les sessions",
                      style: GoogleFonts.cairo(fontSize: 13),
                    ),
                  ),
                  ...dates.map(
                    (d) => DropdownMenuItem(
                      value: d,
                      child: Text(d, style: GoogleFonts.cairo(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<QueryDocumentSnapshot> results) {
    results.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final timestampA = dataA['timestamp'] as Timestamp?;
      final timestampB = dataB['timestamp'] as Timestamp?;

      if (timestampA != null && timestampB != null) {
        return timestampB.compareTo(timestampA);
      }
      return 0;
    });

    final Map<String, List<QueryDocumentSnapshot>> groupedResults = {};
    for (var doc in results) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      final date = timestamp != null
          ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}"
          : "Date inconnue";

      if (!groupedResults.containsKey(date)) {
        groupedResults[date] = [];
      }
      groupedResults[date]!.add(doc);
    }

    final sortedDates = groupedResults.keys.where((d) {
      return _selectedDateFilter == null || d == _selectedDateFilter;
    }).toList();

    if (sortedDates.isEmpty) {
      return Center(
        child: Text(
          "Aucun résultat pour cette date.",
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

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
                    const Icon(Icons.calendar_month, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: GoogleFonts.cairo(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          const Icon(Icons.picture_as_pdf, color: Colors.white),
                      tooltip: "Exporter cette session en PDF",
                      onPressed: () => PdfExportService.exportSessionReport(
                        widget.patientId,
                        date,
                        dayResults,
                      ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  dataRowMinHeight: 70,
                  dataRowMaxHeight: 90,
                  headingRowColor: WidgetStateProperty.all(Colors.teal.shade50),
                  columns: [
                    DataColumn(
                      label: Text(
                        "Test Name",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Criteria 1",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Criteria 2",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Actions",
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: dayResults.map((res) {
                    final data = res.data() as Map<String, dynamic>;
                    final testType = data['testType'] ?? 'Empan';
                    final duration = data['duration'] ?? '00:00';
                    final score = data['score'] ?? 0.0;
                    final metadataMap =
                        (data['metadata'] as Map<String, dynamic>?) ?? data;

                    Widget criteria1Widget;
                    Widget criteria2Widget;

                    if (testType == "TMT-A" ||
                        testType == "TMT-B" ||
                        testType == "TMT-C") {
                      final totalActions =
                          metadataMap['totalActions'] ??
                          (metadataMap['path'] as List?)?.length ??
                          0;
                      final mistakes =
                          metadataMap['mistakes'] ?? metadataMap['errors'] ?? 0;
                      final required = testType == "TMT-A"
                          ? 25
                          : (testType == "TMT-B" ? 50 : 16);

                      criteria1Widget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Actions: $totalActions/$required",
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Erreurs: $mistakes/$totalActions",
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      );
                      criteria2Widget = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Temps: ${_formatDuration(duration)}",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    } else if (testType == "HADS") {
                      final scoreA = (data['scoreA'] ?? 0.0).toInt();
                      final scoreD = (data['scoreD'] ?? 0.0).toInt();
                      criteria1Widget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Anxiété: $scoreA",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getHadsLevel(scoreA),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                      criteria2Widget = Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Dépression: $scoreD",
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _getHadsLevel(scoreD),
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              color: Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    } else {
                      criteria1Widget = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Score: $score pts",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
                      criteria2Widget = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Temps: ${_formatDuration(duration)}",
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      );
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
                        DataCell(criteria1Widget),
                        DataCell(criteria2Widget),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (testType.startsWith("TMT") &&
                                  metadataMap['path'] != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () => _showTmtVisualizationDialog(
                                    context,
                                    testType,
                                    metadataMap,
                                  ),
                                ),
                              if (testType.startsWith("DSM-48") ||
                                  testType == "DO-30" ||
                                  testType.toLowerCase().contains('empan'))
                                IconButton(
                                  icon: const Icon(
                                    Icons.list_alt,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showTestDetailsDialog(
                                    context,
                                    testType,
                                    metadataMap,
                                  ),
                                ),
                              if (testType.contains("HADS") &&
                                  metadataMap['hadsFormat'] != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () =>
                                      _showHadsFormDialog(context, metadataMap),
                                  tooltip: "Voir le questionnaire complet",
                                ),
                            ],
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
                    final data = res.data() as Map<String, dynamic>;
                    final testType = data['testType'] ?? '';
                    final durationStr = data['duration'] ?? '00:00';

                    if (testType == "TMT-A" || testType == "TMT-B") {
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
                          final mins = int.tryParse(parts[0]) ?? 0;
                          final secs = int.tryParse(parts[1]) ?? 0;
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
                    final displayMins = (absDiff ~/ 60).toString().padLeft(
                      2,
                      '0',
                    );
                    final displaySecs = (absDiff % 60).toString().padLeft(
                      2,
                      '0',
                    );
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("🧠", style: TextStyle(fontSize: 18)),
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
  }

  void _showTestDetailsDialog(
    BuildContext context,
    String testType,
    Map<String, dynamic> metadata,
  ) {
    final List<dynamic> tableData = metadata['tableFormat'] ?? [];
    final bool isDsm48 = testType.startsWith("DSM-48");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isDsm48 ? "Détails $testType" : "Détails des réponses DO-30",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: tableData.isEmpty
              ? const Text("Données détaillées non disponibles pour ce test.")
              : SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 10,
                    horizontalMargin: 4,
                    columns: [
                      const DataColumn(label: Text("N°")),
                      if (isDsm48) const DataColumn(label: Text("Type")),
                      DataColumn(label: Text(isDsm48 ? "Ex" : "Attendu")),
                      DataColumn(label: Text(isDsm48 ? "Pat" : "Patient")),
                      const DataColumn(label: Text("")),
                    ],
                    rows: tableData.map((item) {
                      final bool isCorrect =
                          item['isCorrect'] ?? item['correct'] ?? false;

                      if (isDsm48) {
                        return DataRow(
                          cells: [
                            DataCell(Text("${item['numero']}")),
                            DataCell(
                              Text(
                                item['categorie'] ?? "",
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                            ),
                            DataCell(Text(item['attendu'] ?? "")),
                            DataCell(Text(item['patient'] ?? "")),
                            DataCell(
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 18,
                              ),
                            ),
                          ],
                        );
                      } else {
                        final String patientValAr = item['reponsePatientAr'] ?? '';
                        final String patientValFr = item['reponsePatientFr'] ?? '';
                        final bool isArabicSession = patientValAr.isNotEmpty;

                        final String expected = isArabicSession
                            ? (item['reponseAttendueAr'] ?? '')
                            : (item['reponseAttendueFr'] ?? '');

                        final String patient =
                            patientValAr.isNotEmpty ? patientValAr : patientValFr;

                        final bool isShortcut =
                            patient.contains("[NE CONNAIT PAS]") ||
                                patient.contains("[OUBLI DU NOM]");

                        return DataRow(
                          cells: [
                            DataCell(Text("${item['numero']}")),
                            DataCell(Text(expected)),
                            DataCell(
                              Text(
                                patient,
                                style: GoogleFonts.cairo(
                                  color: isShortcut ? Colors.red : Colors.black,
                                  fontWeight: isShortcut
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            DataCell(
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 20,
                              ),
                            ),
                          ],
                        );
                      }
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer", style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showHadsFormDialog(
    BuildContext context,
    Map<String, dynamic> metadata,
  ) {
    final List<dynamic> entries = metadata['hadsFormat'] ?? [];
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Questionnaire HADS complet",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 500,
          child: entries.isEmpty
              ? const Text("Données du questionnaire non disponibles.")
              : SingleChildScrollView(
                  child: Column(
                    children: entries.map((item) {
                      final type = item['type'] ?? ''; // A or D
                      final questionText = loc.translate(item['qKey'] ?? '');
                      final answerText = loc.translate(item['aKey'] ?? '');
                      final score = item['score'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: type == 'A'
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: type == 'A'
                                ? Colors.blue.shade700
                                : Colors.orange.shade700,
                            radius: 12,
                            child: Text(
                              type,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            questionText,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            answerText,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 15,
                            child: Text(
                              "$score",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer", style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  void _showTmtVisualizationDialog(
    BuildContext context,
    String testType,
    Map<String, dynamic> metadata,
  ) {
    final List<dynamic> path = metadata['path'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Tracé du patient - $testType",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 500,
          height: 600,
          child: path.isEmpty
              ? const Center(
                  child: Text("Aucun tracé enregistré pour ce test."),
                )
              : Column(
                  children: [
                    Expanded(
                      child: TmtVisualizer(testType: testType, path: path),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "En bleu : tracé suivi. En rouge : sauts/erreurs de séquence.",
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fermer", style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }

  String _formatDuration(String raw) {
    if (raw == '00:00' || raw.isEmpty) return raw;

    // Check if it's already in min s format to avoid double formatting
    if (raw.contains('min')) return raw;

    String clean = raw.replaceAll(' s', '').trim();
    int? totalSeconds = int.tryParse(clean);

    if (totalSeconds == null) return raw;

    if (totalSeconds < 60) {
      return "$totalSeconds s";
    } else {
      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;
      if (seconds == 0) {
        return "$minutes min";
      }
      String secondsStr = seconds < 10 ? "0$seconds" : "$seconds";
      return "$minutes min $secondsStr s";
    }
  }

  String _getHadsLevel(int score) {
    if (score <= 7) return "Normal";
    if (score <= 10) return "Modéré";
    if (score <= 14) return "Moyen";
    return "Sévère";
  }
}
