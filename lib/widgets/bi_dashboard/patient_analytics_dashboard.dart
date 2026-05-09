import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'analytics_engine.dart';
import '../../services/pdf_export_service.dart';

// Styling Constants
final BoxDecoration _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: Colors.grey.shade200),
);

class PatientAnalyticsDashboard extends StatefulWidget {
  final String patientId;
  final List<QueryDocumentSnapshot> docs;

  const PatientAnalyticsDashboard({super.key, required this.patientId, required this.docs});

  @override
  State<PatientAnalyticsDashboard> createState() => _PatientAnalyticsDashboardState();
}

class _PatientAnalyticsDashboardState extends State<PatientAnalyticsDashboard> {
  late PatientAnalyticsState _state;
  String? _selectedSession;

  @override
  void initState() {
    super.initState();
    _state = AnalyticsEngine.process(widget.docs);
    if (_state.sortedSessions.isNotEmpty) {
      _selectedSession = _state.sortedSessions.first;
    }
  }

  void _onSessionSelected(String? session) {
    if (session != null) {
      setState(() {
        _selectedSession = session;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.docs.isEmpty || _state.sortedSessions.isEmpty) {
      return Center(
        child: Text(
          "Aucune donnée analytique disponible.",
          style: GoogleFonts.cairo(color: Colors.grey),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ZONE 1: ALERTS
            ClinicalAlertBanner(state: _state, session: _selectedSession!),
            
            // ZONE 2: SESSION SELECTOR
            SessionSelectorBar(
              state: _state, 
              selectedSession: _selectedSession!, 
              onChanged: _onSessionSelected,
              patientId: widget.patientId,
            ),
            const SizedBox(height: 20),

            // ZONE 3: COGNITIVE PROFILE & HADS
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                   return Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(flex: 5, child: CognitiveDomainCards(state: _state, session: _selectedSession!)),
                       const SizedBox(width: 20),
                       Expanded(flex: 3, child: HadsDualGauge(state: _state, session: _selectedSession!)),
                     ],
                   );
                } else {
                   return Column(
                     children: [
                       CognitiveDomainCards(state: _state, session: _selectedSession!),
                       const SizedBox(height: 20),
                       HadsDualGauge(state: _state, session: _selectedSession!),
                     ],
                   );
                }
              }
            ),
            const SizedBox(height: 20),

            // ZONE 4: LONGITUDINAL TREND
            LongitudinalTrendChart(state: _state, onSessionTap: _onSessionSelected),
            const SizedBox(height: 20),

            // ZONE 5: DSM & TMT CHARTS
            LayoutBuilder(
              builder: (context, constraints) {
                 if (constraints.maxWidth > 800) {
                   return Row(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Expanded(child: DsmComparisonChart(state: _state, selectedDate: _selectedSession)),
                       const SizedBox(width: 20),
                       Expanded(child: TmtFlexibilityChart(state: _state)),
                     ],
                   );
                 } else {
                   return Column(
                     children: [
                       DsmComparisonChart(state: _state, selectedDate: _selectedSession),
                       const SizedBox(height: 20),
                       TmtFlexibilityChart(state: _state),
                     ],
                   );
                 }
              }
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 1: ALERTS BANNER
// -----------------------------------------------------------------------------
class ClinicalAlertBanner extends StatelessWidget {
  final PatientAnalyticsState state;
  final String session;
  
  const ClinicalAlertBanner({super.key, required this.state, required this.session});

  @override
  Widget build(BuildContext context) {
    final metrics = state.sessionAverages[session];
    if (metrics == null) return const SizedBox.shrink();

    List<String> alerts = [];
    if (metrics['dsmMean'] != null && metrics['dsmMean'] < 40) alerts.add("Score DSM-48 inférieur au seuil critique (< 40/48)");
    if (metrics['hadsA'] != null && metrics['hadsA'] >= 11) alerts.add("Symptomatologie anxieuse significative (HADS-A ≥ 11)");
    if (metrics['hadsD'] != null && metrics['hadsD'] >= 11) alerts.add("Symptomatologie dépressive significative (HADS-D ≥ 11)");
    if (metrics['tmtBAvg'] != null && metrics['tmtBAvg'] > 180) alerts.add("Déficit exécutif sévère (TMT B > 180s)");
    
    double empanMax = max((metrics['empanDirect'] ?? 0).toDouble(), (metrics['empanInverse'] ?? 0).toDouble());
    if (empanMax < 2) alerts.add("Indice d'attention sévère (Empan < 2)");
    if (metrics['empanMaFlag'] == true) alerts.add("Ratio Empan Inverse/Direct < 0.7 (Signe MA)");

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: const Border(left: BorderSide(color: Color(0xFFFF6B35), width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B35)),
              const SizedBox(width: 8),
              Text("Attention clinique requise", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ...alerts.map((a) => Padding(
            padding: const EdgeInsets.only(left: 32.0, bottom: 4),
            child: Text("• $a", style: GoogleFonts.cairo(fontSize: 14)),
          )),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 32.0),
            child: Text("Cette session justifie une réévaluation approfondie.", style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 2: SESSION SELECTOR
// -----------------------------------------------------------------------------
class SessionSelectorBar extends StatelessWidget {
  final PatientAnalyticsState state;
  final String selectedSession;
  final ValueChanged<String?> onChanged;
  final String patientId;

  const SessionSelectorBar({
    super.key, required this.state, required this.selectedSession, required this.onChanged, required this.patientId
  });

  bool _hasAlert(String session) {
    final m = state.sessionAverages[session];
    if (m == null) return false;
    if (m['dsmMean'] != null && m['dsmMean'] < 40) return true;
    if (m['hadsA'] != null && m['hadsA'] >= 11) return true;
    if (m['hadsD'] != null && m['hadsD'] >= 11) return true;
    if (m['tmtBAvg'] != null && m['tmtBAvg'] > 180) return true;
    double empanMax = max((m['empanDirect'] ?? 0).toDouble(), (m['empanInverse'] ?? 0).toDouble());
    if (empanMax < 2) return true;
    if (m['empanMaFlag'] == true) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    String completeness = state.completenessLabels[selectedSession] ?? 'Inconnue';
    Color compColor = completeness == 'Complète' ? Colors.green : (completeness == 'Partielle' ? Colors.orange : Colors.red);

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text("Session analysée : ", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedSession,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.teal),
                style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                onChanged: onChanged,
                items: state.sortedSessions.map((session) {
                  bool complete = state.completenessLabels[session] == 'Complète';
                  bool alert = _hasAlert(session);
                  return DropdownMenuItem<String>(
                    value: session,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: alert ? Colors.orange : (complete ? Colors.green : Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(session),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Row(
            children: [
              Chip(
                label: Text(completeness, style: GoogleFonts.cairo(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                backgroundColor: compColor,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => PdfExportService.exportPatientReport(patientId, state),
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                label: Text("Exporter PDF", style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 3A: COGNITIVE DOMAIN CARDS
// -----------------------------------------------------------------------------
class CognitiveDomainCards extends StatelessWidget {
  final PatientAnalyticsState state;
  final String session;

  const CognitiveDomainCards({super.key, required this.state, required this.session});

  @override
  Widget build(BuildContext context) {
    final metrics = state.sessionAverages[session];
    if (metrics == null) return const SizedBox.shrink();

    // 1. DMS-48
    double? dsm = metrics['dsmMean'];
    Color dsmColor = dsm == null ? Colors.grey : (dsm >= 40 ? Colors.green : Colors.red);
    String dsmVal = dsm == null ? "Non évalué" : "${dsm.toStringAsFixed(1)} / 48";
    
    // 2. Empan
    double? eDir = metrics['empanDirect'];
    double? eInv = metrics['empanInverse'];
    double eMax = max(eDir ?? 0.0, eInv ?? 0.0);
    
    Color empanColor = eMax >= 2.0 
        ? Colors.green 
        : (eMax >= 1.0 ? Colors.orange : Colors.red);
        
    String eStatus = eMax >= 2.0 
        ? "Normal" 
        : (eMax >= 1.0 ? "Fragilité" : "Sévère");
        
    String eVal = "";
    if (eDir != null && eInv != null) eVal = "D: ${eDir.toInt()} | I: ${eInv.toInt()}";
    else if (eDir != null) eVal = "D: ${eDir.toInt()}";
    else if (eInv != null) eVal = "I: ${eInv.toInt()}";
    else eVal = "Non évalué";
    
    bool eAlert = metrics['empanMaFlag'] == true || eMax < 2.0;

    // 3. DO-30
    double? do30 = metrics['do30'];
    Color doColor = do30 == null ? Colors.grey : (do30 >= 27 ? Colors.green : (do30 >= 20 ? Colors.orange : Colors.red));
    String doVal = do30 == null ? "Non évalué" : "${do30.toInt()} / 30";

    // 4. TMT Flex
    double? tmtA = metrics['tmtAAvg'];
    double? tmtB = metrics['tmtBAvg'];
    String tmtVal = "Non évalué";
    Color tmtColor = Colors.grey;
    if (tmtA != null && tmtB != null) {
      double diff = tmtB - tmtA;
      tmtVal = "Δ ${diff.toInt()} s";
      tmtColor = diff < 60 ? Colors.green : (diff <= 120 ? Colors.orange : Colors.red);
    } else if (tmtA != null) {
      tmtVal = "A: ${tmtA.toInt()}s (Index inc.)";
    } else if (tmtB != null) {
      tmtVal = "B: ${tmtB.toInt()}s (Index inc.)";
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCard("Mémoire (DSM-48)", "Mémoire de reconnaissance visuelle", dsmVal, Icons.grid_view_rounded, Colors.teal, dsmColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildCard("Attention (Empan)", "Attention — État : $eStatus", eVal, Icons.graphic_eq, Colors.blue, empanColor, alertBadge: eAlert ? "Alerte CLINIQUE ⚠" : null)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildCard("Langage (DO-30)", "Dénomination d'objets", doVal, Icons.record_voice_over_outlined, Colors.purple, doColor)),
            const SizedBox(width: 16),
            Expanded(child: _buildCard("Exécutif (TMT)", "Flexibilité mentale (TMT B - A)", tmtVal, Icons.timeline_rounded, Colors.green, tmtColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(String title, String subLabel, String value, IconData icon, Color iconBase, Color statusDot, {String? alertBadge}) {
    return Container(
      height: 120,
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: iconBase.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: iconBase, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(title, style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
                ],
              ),
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: statusDot)),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(value, style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (alertBadge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                  child: Text(alertBadge, style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                ),
              ]
            ],
          ),
          Text(subLabel, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 3B: HADS GAUGES
// -----------------------------------------------------------------------------
class HadsDualGauge extends StatelessWidget {
  final PatientAnalyticsState state;
  final String session;
  const HadsDualGauge({super.key, required this.state, required this.session});

  String _getLevelText(double score) {
    if (score < 8) return "Normal";
    if (score <= 10) return "Limite";
    return "Significatif";
  }
  Color _getLevelColor(double score) {
    if (score < 8) return Colors.green;
    if (score <= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final metrics = state.sessionAverages[session];
    double? aScore = metrics?['hadsA'];
    double? dScore = metrics?['hadsD'];

    // Find previous session for trend
    int idx = state.sortedSessions.indexOf(session);
    double? prevA, prevD;
    String? prevDate;
    if (idx != -1 && idx + 1 < state.sortedSessions.length) {
      prevDate = state.sortedSessions[idx + 1];
      final pMetrics = state.sessionAverages[prevDate];
      if (pMetrics != null) {
        prevA = pMetrics['hadsA'];
        prevD = pMetrics['hadsD'];
      }
    }

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HADS — Dernière Session", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
          Text("Session du $session", style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          if (aScore == null && dScore == null)
            const SizedBox(
              height: 180,
              child: Center(child: Text("Non évalué")),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (aScore != null) Expanded(child: _buildSfGauge("Anxiété (A)", aScore, prevA, prevDate)),
                  if (dScore != null) Expanded(child: _buildSfGauge("Dépression (D)", dScore, prevD, prevDate)),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Center(
            child: Text("Score > 10 sur l'une ou l'autre sous-échelle requiert une attention clinique", 
              style: GoogleFonts.cairo(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSfGauge(String label, double score, double? prevScore, String? prevDate) {
    Color gaugeColor = _getLevelColor(score);
    String trendStr = "";
    Color trendCol = Colors.grey;
    if (prevScore != null && prevDate != null) {
       double diff = score - prevScore;
       if (diff < 0) { trendStr = "▼ ${diff.abs().toInt()} pts depuis $prevDate"; trendCol = Colors.green; }
       else if (diff > 0) { trendStr = "▲ ${diff.toInt()} pts depuis $prevDate"; trendCol = Colors.red; }
       else { trendStr = "− Stable depuis $prevDate"; trendCol = Colors.grey; }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 90,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: 21,
                showLabels: false,
                showTicks: false,
                axisLineStyle: AxisLineStyle(
                  thickness: 0.15,
                  cornerStyle: CornerStyle.bothCurve,
                  color: Colors.grey.withOpacity(0.2),
                  thicknessUnit: GaugeSizeUnit.factor,
                ),
                pointers: <GaugePointer>[
                  RangePointer(
                    value: score,
                    cornerStyle: CornerStyle.bothCurve,
                    width: 0.15,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: gaugeColor,
                  )
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    positionFactor: 0.1,
                    widget: Text(
                      score.toInt().toString(),
                      style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.bold, color: gaugeColor),
                    )
                  )
                ]
              )
            ],
          ),
        ),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
        Text(_getLevelText(score), style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: gaugeColor)),
        if (trendStr.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(trendStr, style: GoogleFonts.cairo(fontSize: 10, color: trendCol)),
          )
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 4: LONGITUDINAL TREND CHART
// -----------------------------------------------------------------------------
class LongitudinalTrendChart extends StatelessWidget {
  final PatientAnalyticsState state;
  final ValueChanged<String?> onSessionTap;

  const LongitudinalTrendChart({super.key, required this.state, required this.onSessionTap});

  @override
  Widget build(BuildContext context) {
    if (state.sortedSessions.length < 2) {
      return const SizedBox.shrink(); // Need 2+ points
    }

    final chronological = state.sortedSessions.reversed.toList();
    List<FlSpot> dsmSpots = [];
    List<FlSpot> doSpots = [];
    List<FlSpot> empanSpots = [];
    List<FlSpot> globalSpots = [];

    int i = 0;
    for (String s in chronological) {
      final m = state.sessionAverages[s];
      if (m != null) {
        if (m['dsmMean'] != null) dsmSpots.add(FlSpot(i.toDouble(), (m['dsmMean'] / 48.0) * 100));
        if (m['do30'] != null) doSpots.add(FlSpot(i.toDouble(), (m['do30'] / 30.0) * 100));
        if (m['empanDirect'] != null) empanSpots.add(FlSpot(i.toDouble(), (m['empanDirect'] / 9.0) * 100));
      }
      final g = state.globalIndexHistory.firstWhere((element) => element['date'] == s, orElse: () => {});
      if (g.isNotEmpty && g['index'] != null) globalSpots.add(FlSpot(i.toDouble(), g['index']));
      i++;
    }

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Évolution Longitudinale des Profils", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minY: 0, maxY: 100,
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (!event.isInterestedForInteractions || response == null || response.lineBarSpots == null) return;
                    int index = response.lineBarSpots!.first.x.toInt();
                    if (index >= 0 && index < chronological.length) {
                       onSessionTap(chronological[index]);
                    }
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                         String label = "";
                         if (spot.barIndex == 0) label = "DSM";
                         else if (spot.barIndex == 1) label = "DO30";
                         else if (spot.barIndex == 2) label = "Empan";
                         else if (spot.barIndex == 3) label = "Index Global";
                         return LineTooltipItem("$label: ${spot.y.toStringAsFixed(1)}%", GoogleFonts.cairo(color: Colors.white));
                      }).toList();
                    }
                  )
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 50, color: Colors.transparent) // Anchor for band
                  ],
                  extraLinesOnTop: false,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 40,
                      getTitlesWidget: (val, meta) {
                        int idx = val.toInt();
                        if (idx >= 0 && idx < chronological.length) {
                           Widget w = Text(chronological[idx], style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600]));
                           if (chronological.length > 5) {
                             return Transform.rotate(angle: -0.5, child: Padding(padding: const EdgeInsets.only(top: 12.0), child: w));
                           }
                           return Padding(padding: const EdgeInsets.only(top: 8.0), child: w);
                        }
                        return const SizedBox.shrink();
                      }
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true, reservedSize: 40,
                      getTitlesWidget: (val, meta) => Text("${val.toInt()}%", style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600]))
                    )
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(spots: dsmSpots, color: Colors.teal, barWidth: 2.5, isCurved: true, dotData: FlDotData(show: false)),
                  LineChartBarData(spots: doSpots, color: Colors.purple, barWidth: 2.5, isCurved: true, dotData: FlDotData(show: false)),
                  LineChartBarData(spots: empanSpots, color: Colors.blue, barWidth: 2, isCurved: true, isStrokeCapRound: true, dashArray: [5, 5], dotData: FlDotData(show: false)),
                  LineChartBarData(spots: globalSpots, color: Colors.black54, barWidth: 3, isCurved: true, dotData: FlDotData(show: true)),
                ],
                betweenBarsData: [
                  // Zone à risque (y=0 to y=50) using custom solution since we don't have filled range
                  // Let's rely on a backdrop or extra components if needed.
                ]
              )
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem(Colors.teal, "DSM"), const SizedBox(width: 16),
              _legendItem(Colors.purple, "DO-30"), const SizedBox(width: 16),
              _legendItem(Colors.blue, "Empan Dir."), const SizedBox(width: 16),
              _legendItem(Colors.black54, "Index Global"),
            ],
          )
        ],
      ),
    );
  }

  Widget _legendItem(Color c, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: c),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.cairo(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 5A: TMT FLEXIBILITY CHART (Fixed)
// -----------------------------------------------------------------------------
class TmtFlexibilityChart extends StatelessWidget {
  final PatientAnalyticsState state;
  const TmtFlexibilityChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final chronological = state.sortedSessions.reversed.toList();
    List<FlSpot> spots = [];
    List<String> labels = [];
    
    int index = 0;
    for (String session in chronological) {
       final metrics = state.sessionAverages[session];
       if (metrics != null && metrics['tmtAAvg'] != null && metrics['tmtBAvg'] != null) {
          double diff = metrics['tmtBAvg'] - metrics['tmtAAvg'];
          spots.add(FlSpot(index.toDouble(), diff));
          labels.add(session);
          index++;
       }
    }

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Flexibilité Mentale (TMT B - A)", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800])),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: spots.isEmpty ? Center(child: Text("Pas de données TMT", style: GoogleFonts.cairo(color: Colors.grey))) : LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                       return touchedSpots.map((spot) {
                          int idx = spot.x.toInt();
                          String interp = spot.y <= 60 ? "Normal" : (spot.y <= 120 ? "Modéré" : "Sévère");
                          return LineTooltipItem(
                            "${labels[idx]}\n${spot.y.toInt()} s ($interp)",
                            GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)
                          );
                       }).toList();
                    }
                  )
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 30),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(y: 60, color: Colors.orange.withOpacity(0.5), strokeWidth: 1, label: HorizontalLineLabel(show: true, labelResolver: (l)=>"Zone Modérée", style: GoogleFonts.cairo(fontSize: 10, color: Colors.orange))),
                    HorizontalLine(y: 120, color: Colors.red.withOpacity(0.5), strokeWidth: 1),
                  ]
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < labels.length) {
                           Widget w = Text(labels[idx], style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600]));
                           if (labels.length > 4) {
                             return Transform.rotate(angle: -0.5, child: Padding(padding: const EdgeInsets.only(top: 8.0), child: w));
                           }
                           return Padding(padding: const EdgeInsets.only(top: 8.0), child: w);
                        }
                        return const SizedBox.shrink();
                      }
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text("${value.toInt()}s", style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey[600])),
                    )
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                  )
                ]
              )
            )
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ZONE 5B: DSM-48 BAR CHART (Fixed)
// -----------------------------------------------------------------------------
class DsmComparisonChart extends StatelessWidget {
  final PatientAnalyticsState state;
  final String? selectedDate;
  const DsmComparisonChart({super.key, required this.state, this.selectedDate});

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> barGroups = [];
    double? dsmMean;
    bool hasData = false;
    
    double? s1, s2, s3;
    
    if (selectedDate != null) {
      final metrics = state.sessionAverages[selectedDate];
      if (metrics != null) {
         dsmMean = metrics['dsmMean'];
         s1 = metrics['dsmSet1'];
         s2 = metrics['dsmSet2'];
         s3 = metrics['dsmSet3'];
         if (s1 != null || s2 != null || s3 != null) hasData = true;
      }
    }

    if (hasData) {
       barGroups = [
         _buildBarGroup(0, s1),
         _buildBarGroup(1, s2),
         _buildBarGroup(2, s3),
       ];
    }

    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text("Focus DSM-48", style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]))),
              Text(dsmMean != null ? "Moy.: ${dsmMean.toStringAsFixed(1)}/48" : "Non évalué cette session", style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: dsmMean != null ? Colors.teal[700] : Colors.grey))
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: !hasData ? Center(child: Text("Pas de données DSM-48", style: GoogleFonts.cairo(color: Colors.grey))) : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 48,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (rod.toY == 0.1) return BarTooltipItem("Set ${group.x + 1} non évalué", GoogleFonts.cairo(color: Colors.white, fontSize: 12));
                      return BarTooltipItem("Set ${group.x + 1}\nScore: ${rod.toY.toInt()}", GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold));
                    }
                  )
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(padding: const EdgeInsets.only(top: 8.0), child: Text("Set ${value.toInt() + 1}", style: GoogleFonts.cairo(fontSize: 12, color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold))),
                      reservedSize: 32,
                    )
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: GoogleFonts.cairo(fontSize: 10, color: Colors.grey.shade500)),
                      reservedSize: 28,
                    )
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 12),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 36, // CLINICAL THRESHOLD
                      color: Colors.redAccent.withOpacity(0.7),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(show: true, labelResolver: (line) => "Seuil clinique (36/48)", style: GoogleFonts.cairo(color: Colors.redAccent, fontSize: 10))
                    )
                  ]
                )
              )
            ),
          ),
          const SizedBox(height: 16),
          if (hasData)
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 _chipBadge("Set 1", s1 != null),
                 const SizedBox(width: 12),
                 _chipBadge("Set 2", s2 != null),
                 const SizedBox(width: 12),
                 _chipBadge("Set 3", s3 != null),
               ],
             )
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double? score) {
    bool missing = (score == null);
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: missing ? 0.1 : score, 
          color: missing ? Colors.grey.shade300 : Colors.teal.shade300, 
          width: 24, 
          borderRadius: BorderRadius.circular(4)
        )
      ]
    );
  }

  Widget _chipBadge(String set, bool done) {
     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
       decoration: BoxDecoration(color: done ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
       child: Text("$set ${done ? '✓' : '—'}", style: GoogleFonts.cairo(fontSize: 12, color: done ? Colors.green.shade800 : Colors.grey.shade600, fontWeight: FontWeight.bold)),
     );
  }
}
