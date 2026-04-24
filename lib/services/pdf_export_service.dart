import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:math';
import '../widgets/bi_dashboard/analytics_engine.dart'; // Adjust path if necessary

class PdfExportService {
  static Future<void> exportPatientReport(
      String patientId, PatientAnalyticsState state) async {
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
          if (metrics['empanDirect'] != null || metrics['empanInverse'] != null) count++;
          
          String dsmInfo = "non évalué";
          double? dsm = metrics['dsmMean'];
          if (dsm != null) {
             dsmInfo = "${dsm.toStringAsFixed(1)}/48, ce qui est ${dsm >= 36 ? 'au-dessus' : 'en-dessous'} du seuil clinique de 36/48";
          }
          
          String hadsInfo = "";
          double? hadsA = metrics['hadsA'];
          double? hadsD = metrics['hadsD'];
          if ((hadsA != null && hadsA >= 11) || (hadsD != null && hadsD >= 11)) {
             hadsInfo = " Il est à noter qu'une symptomatologie anxio-dépressive significative (score HADS > 10) est présente, nécessitant une attention clinique.";
          }
          
          resumeClinique = "La dernière session du $latestDate montre $count domaines cognitifs évalués. Le score de mémoire de reconnaissance (DSM-48) est de $dsmInfo.$hadsInfo";
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
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Rapport Clinique & Analytique',
                  style: pw.TextStyle(color: PdfColors.teal, fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Date: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) => [
          pw.SizedBox(height: 20),
          pw.Text('Dossier Patient ID: $patientId', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Résumé des tendances KPI:', style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
          pw.Bullet(text: "Tendance Globale du Score DSM: $globalTrendStr"),
          pw.Bullet(text: "Différentiel HADS-A (Anxiété): ${state.kpiTrends['HADS-A Trend'] ?? 'N/A'}"),
          pw.Bullet(text: "Différentiel HADS-D (Dépression): ${state.kpiTrends['HADS-D Trend'] ?? 'N/A'}"),
          if (state.sortedSessions.isNotEmpty)
            pw.Bullet(text: "Fiabilité de la dernière session: ${state.completenessLabels[state.sortedSessions.first]}"),
          
          pw.SizedBox(height: 20),
          pw.Text('RÉSUMÉ CLINIQUE', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
          pw.SizedBox(height: 8),
          pw.Paragraph(text: resumeClinique, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey900)),

          pw.SizedBox(height: 30),
          pw.Text('Évolution Longitudinale par Session', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
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

  static pw.Widget _buildScoresTable(PatientAnalyticsState state) {
    if (state.sortedSessions.isEmpty) {
      return pw.Text("Aucune donnée de session disponible.");
    }

    final headers = ['Date', 'DSM Moy.', 'DO-30', 'Empan Max', 'HADS-A', 'HADS-D', 'TMT-B'];
    
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
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
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
