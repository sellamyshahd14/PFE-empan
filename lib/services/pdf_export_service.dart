import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bi_dashboard/analytics_engine.dart';

class PdfExportService {
  static Future<void> exportPatientReport(
    String patientId,
    PatientAnalyticsState state,
  ) async {
    final pdf = pw.Document();

    String globalTrendStr = state.kpiTrends['Global Trend'] ?? '0%';
    if (globalTrendStr == '0%') {
      globalTrendStr = 'Données insuffisantes (≥2 sessions complètes requises)';
    }

    String resumeClinique = "";
    if (state.sortedSessions.isNotEmpty) {
      final latestDate = state.sortedSessions.first;
      final metrics = state.sessionAverages[latestDate];
      if (metrics != null) {
        int count = 0;
        if (metrics['dsmMean'] != null) count++;
        if (metrics['tmtAAvg'] != null) count++;
        if (metrics['do30'] != null) count++;
        if (metrics['empanDirect'] != null || metrics['empanInverse'] != null)
          count++;

        String dsmInfo = "non évalué";
        double? dsm = metrics['dsmMean'];
        if (dsm != null) {
          dsmInfo =
              "${dsm.toStringAsFixed(1)}/48, ce qui est ${dsm >= 40 ? 'au-dessus' : 'en-dessous'} du seuil clinique de 40/48";
        }

        String hadsInfo = "";
        double? hadsA = metrics['hadsA'];
        double? hadsD = metrics['hadsD'];
        if ((hadsA != null && hadsA >= 11) || (hadsD != null && hadsD >= 11)) {
          hadsInfo =
              " Il est à noter qu'une symptomatologie anxio-dépressive significative (score HADS > 10) est présente, nécessitant une attention clinique.";
        }

        resumeClinique =
            "La dernière session du $latestDate montre $count domaines cognitifs évalués. Le score de mémoire de reconnaissance (DSM-48) est de $dsmInfo.$hadsInfo";
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 20),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.teal, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Rapport Clinique & Analytique',
                  style: pw.TextStyle(
                    color: PdfColors.teal,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Date: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.SizedBox(height: 20),
          pw.Text(
            'Dossier Patient ID: $patientId',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Résumé des tendances KPI:',
            style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
          ),
          pw.Bullet(text: "Tendance Globale du Score DSM: $globalTrendStr"),
          pw.Bullet(
            text:
                "Différentiel HADS-A (Anxiété): ${state.kpiTrends['HADS-A Trend'] ?? 'N/A'}",
          ),
          pw.Bullet(
            text:
                "Différentiel HADS-D (Dépression): ${state.kpiTrends['HADS-D Trend'] ?? 'N/A'}",
          ),
          if (state.sortedSessions.isNotEmpty)
            pw.Bullet(
              text:
                  "Fiabilité de la dernière session: ${state.completenessLabels[state.sortedSessions.first]}",
            ),

          pw.SizedBox(height: 20),
          pw.Text(
            'RÉSUMÉ CLINIQUE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Paragraph(
            text: resumeClinique,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey900),
          ),

          pw.SizedBox(height: 30),
          pw.Text(
            'Évolution Longitudinale par Session',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal800,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildScoresTable(state),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Généré automatiquement par l\'application PFE BI',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> exportSessionReport(
    String patientId,
    String date,
    List<QueryDocumentSnapshot> sessionDocs,
  ) async {
    final pdf = pw.Document();

    // Grouping docs by type for easier layout
    Map<String, List<Map<String, dynamic>>> testData = {};
    for (var doc in sessionDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['testType'] ?? 'Inconnu';
      if (!testData.containsKey(type)) testData[type] = [];
      testData[type]!.add(data);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 15),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.teal, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Rapport de Session Clinique',
                      style: pw.TextStyle(
                        color: PdfColors.teal,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'ID Patient: $patientId',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Session du: $date',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.SizedBox(height: 20),
          
          // 1. DO-30 Summary (Requested: Just Score / 30)
          _buildTestSectionHeader("Test de Dénomination DO-30"),
          if (testData.containsKey("DO-30")) 
            ...testData["DO-30"]!.map((d) => pw.Bullet(text: "Score Final: ${d['score']?.toInt() ?? 0} / 30 (Temps: ${d['duration'] ?? 'N/A'})"))
          else 
            pw.Text("Non effectué", style: pw.TextStyle(color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),

          pw.SizedBox(height: 20),

          // 2. DSM-48 Breakdown (Requested: Set 1, 2, 3 and Encoding Time)
          _buildTestSectionHeader("Mémoire de Reconnaissance DSM-48"),
          _buildDsmDetailedTable(testData),

          pw.SizedBox(height: 20),

          // 3. TMT (A, B, C)
          _buildTestSectionHeader("Fonctions Exécutives (TMT)"),
          _buildTmtSummaryTable(testData),

          pw.SizedBox(height: 20),

          // 4. Attention & Affectif (Empan, HADS)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildTestSectionHeader("Attention (Empan)"),
                    _buildEmpanSummary(testData),
                  ],
                ),
              ),
              pw.SizedBox(width: 30),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildTestSectionHeader("Affectif (HADS)"),
                    _buildHadsSummary(testData),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 40),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            "Observations du clinicien :",
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
          ),
          pw.SizedBox(height: 100, child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey200)))),
        ],
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - Application PFE',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildTestSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.teal50,
        border: pw.Border(left: pw.BorderSide(color: PdfColors.teal, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.teal900,
        ),
      ),
    );
  }

  static pw.Widget _buildDsmDetailedTable(Map<String, List<Map<String, dynamic>>> testData) {
    String encTime = "N/A";
    String set1 = "N/A";
    String set2 = "N/A";
    String set3 = "N/A";
    String set1Time = "N/A";
    String set2Time = "N/A";
    String set3Time = "N/A";

    testData.forEach((type, results) {
      if (type.contains("DSM-48")) {
        final data = results.first;
        final score = data['score']?.toInt() ?? 0;
        final duration = data['duration'] ?? 'N/A';

        if (type.contains("Set 1") || type.contains("المجموعة 1")) {
          set1 = "$score / 48";
          set1Time = duration;
        } else if (type.contains("Set 2") || type.contains("المجموعة 2")) {
          set2 = "$score / 48";
          set2Time = duration;
        } else if (type.contains("Set 3") || type.contains("المجموعة 3")) {
          set3 = "$score / 48";
          set3Time = duration;
        }
        
        // Find encoding time if available
        if (data['metadata'] != null && data['metadata']['encodingDuration'] != null) {
          encTime = "${data['metadata']['encodingDuration']}";
        } else if (data['encodingTime'] != null) {
          encTime = "${data['encodingTime']}";
        }
      }
    });

    return pw.TableHelper.fromTextArray(
      headers: ['Phase DSM-48', 'Résultat', 'Temps'],
      data: [
        ['Apprentissage (Encodage)', 'Effectué', encTime],
        ['Reconnaissance Set 1', set1, set1Time],
        ['Reconnaissance Set 2', set2, set2Time],
        ['Reconnaissance Set 3', set3, set3Time],
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
      cellStyle: const pw.TextStyle(fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
      cellHeight: 22,
    );
  }

  static pw.Widget _buildTmtSummaryTable(Map<String, List<Map<String, dynamic>>> testData) {
    List<List<String>> rows = [];
    final tests = ["TMT-A", "TMT-B", "TMT-C"];
    
    for (var t in tests) {
      if (testData.containsKey(t)) {
        final data = testData[t]!.first;
        final meta = data['metadata'] ?? data;
        rows.add([
          t,
          "${meta['totalActions'] ?? 0}",
          "${meta['errors'] ?? meta['mistakes'] ?? 0}",
          "${data['duration'] ?? '00:00'}",
        ]);
      }
    }

    if (rows.isEmpty) return pw.Text("Non effectué", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey600));

    return pw.TableHelper.fromTextArray(
      headers: ['Test', 'Actions', 'Erreurs', 'Temps'],
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
      cellStyle: const pw.TextStyle(fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
      cellHeight: 22,
    );
  }

  static pw.Widget _buildEmpanSummary(Map<String, List<Map<String, dynamic>>> testData) {
    String dir = "N/A";
    String inv = "N/A";

    testData.forEach((type, results) {
      if (type.toLowerCase().contains("empan direct")) dir = "${results.first['score']?.toInt() ?? 0} pts";
      if (type.toLowerCase().contains("empan inverse")) inv = "${results.first['score']?.toInt() ?? 0} pts";
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Empan Direct: $dir", style: const pw.TextStyle(fontSize: 11)),
        pw.Text("Empan Inverse: $inv", style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildHadsSummary(Map<String, List<Map<String, dynamic>>> testData) {
    if (!testData.containsKey("HADS")) return pw.Text("Non effectué", style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic));
    
    final data = testData["HADS"]!.first;
    final scoreA = data['scoreA']?.toInt() ?? 0;
    final scoreD = data['scoreD']?.toInt() ?? 0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text("Anxiété (HADS-A): $scoreA / 21", style: const pw.TextStyle(fontSize: 11)),
        pw.Text("Dépression (HADS-D): $scoreD / 21", style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildScoresTable(PatientAnalyticsState state) {
    if (state.sortedSessions.isEmpty) {
      return pw.Text("Aucune donnée de session disponible.");
    }

    final headers = [
      'Date',
      'DSM Moy.',
      'DO-30',
      'Empan Max',
      'HADS-A',
      'HADS-D',
      'TMT-B',
    ];

    final data = state.sortedSessions.map((session) {
      final metrics = state.sessionAverages[session]!;
      double? eDir = metrics['empanDirect'];
      double? eInv = metrics['empanInverse'];
      double eMax = max(eDir ?? 0, eInv ?? 0);

      return [
        session,
        metrics['dsmMean']?.toStringAsFixed(1) ?? 'N/A',
        metrics['do30']?.toStringAsFixed(1) ?? 'N/A',
        eMax > 0 ? eMax.toStringAsFixed(0) : 'N/A',
        metrics['hadsA']?.toStringAsFixed(0) ?? 'N/A',
        metrics['hadsD']?.toStringAsFixed(0) ?? 'N/A',
        metrics['tmtBAvg']?.toStringAsFixed(0) ?? 'N/A',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.center,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.center,
        6: pw.Alignment.center,
      },
    );
  }
}
