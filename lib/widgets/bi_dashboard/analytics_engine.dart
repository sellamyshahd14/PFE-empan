import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class PatientAnalyticsState {
  final Map<String, List<QueryDocumentSnapshot>> groupedBySession;
  final List<String> sortedSessions;
  final Map<String, double> latestNormalizedScores;
  final Map<String, String> kpiTrends;
  final Map<String, String> completenessLabels;
  final Map<String, Map<String, dynamic>> sessionAverages;
  final List<Map<String, dynamic>> globalIndexHistory;

  PatientAnalyticsState({
    required this.groupedBySession,
    required this.sortedSessions,
    required this.latestNormalizedScores,
    required this.kpiTrends,
    required this.completenessLabels,
    required this.sessionAverages,
    required this.globalIndexHistory,
  });
}

class AnalyticsEngine {
  static const int expectedTestsPerSession = 8;
  static const int tmtMaxSeconds = 180;
  static const double dsmThreshold = 40.0;

  static PatientAnalyticsState process(List<QueryDocumentSnapshot> rawDocs) {
    // 1. Group by session
    final Map<String, List<QueryDocumentSnapshot>> groupedBySession = {};
    for (var doc in rawDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      final date = timestamp != null
          ? "${timestamp.toDate().day.toString().padLeft(2, '0')}/${timestamp.toDate().month.toString().padLeft(2, '0')}/${timestamp.toDate().year}"
          : "Date inconnue";
          
      if (!groupedBySession.containsKey(date)) {
        groupedBySession[date] = [];
      }
      groupedBySession[date]!.add(doc);
    }

    // Sort dates
    final sortedSessions = groupedBySession.keys.toList()..sort((a, b) {
       if (a == "Date inconnue") return 1;
       if (b == "Date inconnue") return -1;
       try {
         final partsA = a.split('/');
         final partsB = b.split('/');
         final dateA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
         final dateB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
         return dateB.compareTo(dateA); 
       } catch (e) {
         return 0;
       }
    });

    final sessionAverages = <String, Map<String, dynamic>>{};
    final completenessLabels = <String, String>{};
    for (var session in sortedSessions) {
      sessionAverages[session] = _calculateSessionMetrics(groupedBySession[session]!);
      completenessLabels[session] = _evaluateCompleteness(sessionAverages[session]!);
    }

    // 2. Global Cognitive Index
    List<Map<String, dynamic>> globalIndexHistory = [];
    // Sort oldest to newest for chronological trend line
    final chronologicalSessions = sortedSessions.reversed.toList();
    for (var session in chronologicalSessions) {
       double? index = _calculateGlobalCognitiveIndex(sessionAverages[session]!);
       globalIndexHistory.add({
         'date': session,
         'index': index,
       });
    }

    // 3. Normalize Scores for Radar (0-100) on latest session
    Map<String, double> latestNormalized = {
      'Mémoire (DSM)': 0.0,
      'Exécutif (TMT)': 0.0,
      'Langage (DO-30)': 0.0,
      'Attention (Empan)': 0.0,
    };
    
    if (sortedSessions.isNotEmpty) {
      final latestMetrics = sessionAverages[sortedSessions.first]!;
      latestNormalized['Mémoire (DSM)'] = latestMetrics['dsmMean'] != null ? min(100.0, (latestMetrics['dsmMean'] / 48) * 100) : 0.0;
      latestNormalized['Langage (DO-30)'] = latestMetrics['do30'] != null ? min(100.0, (latestMetrics['do30'] / 30) * 100) : 0.0;
      double empanMax = max((latestMetrics['empanDirect'] ?? 0).toDouble(), (latestMetrics['empanInverse'] ?? 0).toDouble());
      latestNormalized['Attention (Empan)'] = empanMax > 0 ? min(100.0, (empanMax / 9) * 100) : 0.0;
      
      if (latestMetrics['tmtBAvg'] != null) {
          final tmtB = latestMetrics['tmtBAvg'] as double;
          latestNormalized['Exécutif (TMT)'] = max(0.0, 100.0 - (tmtB / tmtMaxSeconds) * 100);
      }
    }

    Map<String, String> kpiTrends = {
      'HADS-A Trend': '0',
      'HADS-D Trend': '0',
      'Global Trend': '0%',
    };
    if (sortedSessions.length >= 2) {
       final latest = sessionAverages[sortedSessions[0]]!;
       final previous = sessionAverages[sortedSessions[1]]!;
       
       if (latest['dsmMean'] != null && previous['dsmMean'] != null && previous['dsmMean'] > 0) {
          final diff = ((latest['dsmMean'] - previous['dsmMean']) / previous['dsmMean']) * 100;
          kpiTrends['Global Trend'] = "${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}%";
       }
       
       if (latest['hadsA'] != null && previous['hadsA'] != null) {
          final diffA = latest['hadsA'] - previous['hadsA'];
          kpiTrends['HADS-A Trend'] = "${diffA > 0 ? '+' : ''}${diffA.toInt()} pts";
       }
       if (latest['hadsD'] != null && previous['hadsD'] != null) {
          final diffD = latest['hadsD'] - previous['hadsD'];
          kpiTrends['HADS-D Trend'] = "${diffD > 0 ? '+' : ''}${diffD.toInt()} pts";
       }
    }

    return PatientAnalyticsState(
      groupedBySession: groupedBySession,
      sortedSessions: sortedSessions,
      latestNormalizedScores: latestNormalized,
      kpiTrends: kpiTrends,
      completenessLabels: completenessLabels,
      sessionAverages: sessionAverages,
      globalIndexHistory: globalIndexHistory,
    );
  }

  static Map<String, dynamic> _calculateSessionMetrics(List<QueryDocumentSnapshot> docs) {
    double? dsmSet1;
    double? dsmSet2;
    double? dsmSet3;
    double do30 = 0.0;
    double? empanDirect;
    double? empanInverse;
    double? hadsA;
    double? hadsD;
    double tmtATime = 0.0;
    double tmtBTime = 0.0;
    
    int tmtACount = 0;
    int tmtBCount = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = (data['testType'] ?? '').toString();
      
      if (type.contains("DSM-48")) {
         if (type.contains("Set 1") || type.contains("المجموعة 1")) dsmSet1 = (data['score'] ?? 0.0).toDouble();
         if (type.contains("Set 2") || type.contains("المجموعة 2")) dsmSet2 = (data['score'] ?? 0.0).toDouble();
         if (type.contains("Set 3") || type.contains("المجموعة 3")) dsmSet3 = (data['score'] ?? 0.0).toDouble();
      } else if (type == "DO-30") {
         do30 = max(do30, (data['score'] ?? 0.0).toDouble());
      } else if (type.contains("Empan Direct") || type.contains("إمبان المباشر")) {
         empanDirect = max(empanDirect ?? 0.0, (data['score'] ?? 0.0).toDouble());
      } else if (type.contains("Empan Inverse") || type.contains("إمبان العكسي")) {
         empanInverse = max(empanInverse ?? 0.0, (data['score'] ?? 0.0).toDouble());
      } else if (type == "HADS") {
         hadsA = (data['scoreA'] ?? 0.0).toDouble();
         hadsD = (data['scoreD'] ?? 0.0).toDouble();
      } else if (type == "TMT-A") {
         tmtATime += _parseDuration(data['duration']);
         tmtACount++;
      } else if (type == "TMT-B") {
         tmtBTime += _parseDuration(data['duration']);
         tmtBCount++;
      }
    }

    // DSM Mean
    List<double> availableSets = [];
    if (dsmSet1 != null) availableSets.add(dsmSet1);
    if (dsmSet2 != null) availableSets.add(dsmSet2);
    if (dsmSet3 != null) availableSets.add(dsmSet3);
    
    double? dsmMean;
    if (availableSets.isNotEmpty) {
      dsmMean = availableSets.reduce((a, b) => a + b) / availableSets.length;
    }
    
    // Empan Ratio
    double? empanRatio;
    bool empanMaFlag = false;
    if (empanDirect != null && empanInverse != null && empanDirect > 0) {
       empanRatio = empanInverse / empanDirect;
       if (empanRatio < 0.7 && empanDirect > 3) {
          empanMaFlag = true;
       }
    }

    return {
      'dsmSet1': dsmSet1,
      'dsmSet2': dsmSet2,
      'dsmSet3': dsmSet3,
      'dsmMean': dsmMean,
      'dsmAvailable': [
         if (dsmSet1 != null) 'Set 1',
         if (dsmSet2 != null) 'Set 2',
         if (dsmSet3 != null) 'Set 3',
      ],
      'do30': do30 > 0 ? do30 : null,
      'empanDirect': empanDirect,
      'empanInverse': empanInverse,
      'empanRatio': empanRatio,
      'empanMaFlag': empanMaFlag,
      'hadsA': hadsA,
      'hadsD': hadsD,
      'tmtAAvg': tmtACount > 0 ? tmtATime / tmtACount : null,
      'tmtBAvg': tmtBCount > 0 ? tmtBTime / tmtBCount : null,
    };
  }

  static String _evaluateCompleteness(Map<String, dynamic> metrics) {
    bool hasDsm = metrics['dsmMean'] != null;
    bool hasTmtA = metrics['tmtAAvg'] != null;
    bool hasHadsOrEmpan = (metrics['hadsA'] != null) || (metrics['empanDirect'] != null || metrics['empanInverse'] != null);
    
    int categoriesPresent = 0;
    if (hasDsm) categoriesPresent++;
    if (hasTmtA) categoriesPresent++;
    if (hasHadsOrEmpan) categoriesPresent++;
    // Add DO-30 ? Assume 4 categories generally. But instructions specified:
    // 'Complète': session has both DSM (≥1 set) AND TMT-A AND either HADS or Empan
    // 'Partielle': session has 2-3 of the above categories
    // 'Minimale': session has only 1 test type
    
    if (hasDsm && hasTmtA && hasHadsOrEmpan) {
      return 'Complète';
    } else if (categoriesPresent >= 2) {
      return 'Partielle';
    } else {
      return 'Minimale';
    }
  }

  static double? _calculateGlobalCognitiveIndex(Map<String, dynamic> metrics) {
    double? dsmNorm = metrics['dsmMean'] != null ? (metrics['dsmMean'] / 48) * 100 : null;
    
    double empanMax = max((metrics['empanDirect'] ?? 0).toDouble(), (metrics['empanInverse'] ?? 0).toDouble());
    double? empanNorm = empanMax > 0 ? min(100.0, (empanMax / 9) * 100) : null;
    
    double? do30Norm = metrics['do30'] != null ? min(100.0, (metrics['do30'] / 30) * 100) : null;
    double? tmtNorm = metrics['tmtBAvg'] != null ? max(0.0, 100.0 - (metrics['tmtBAvg'] / tmtMaxSeconds) * 100) : null;
    
    Map<String, Map<String, dynamic>> availableNorms = {};
    if (dsmNorm != null) availableNorms['dsm'] = {'score': dsmNorm, 'weight': 0.35};
    if (empanNorm != null) availableNorms['empan'] = {'score': empanNorm, 'weight': 0.25};
    if (do30Norm != null) availableNorms['do30'] = {'score': do30Norm, 'weight': 0.20};
    if (tmtNorm != null) availableNorms['tmt'] = {'score': tmtNorm, 'weight': 0.20};
    
    if (availableNorms.length < 2) return null; // Insufficient data
    
    double totalWeight = 0;
    availableNorms.forEach((key, val) => totalWeight += val['weight']);
    
    double globalIndex = 0;
    availableNorms.forEach((key, val) {
      double rebalancedWeight = val['weight'] / totalWeight;
      globalIndex += val['score'] * rebalancedWeight;
    });
    
    return globalIndex;
  }

  static double _parseDuration(dynamic durationStr) {
    if (durationStr == null) return 0.0;
    String str = durationStr.toString();
    int seconds = 0;
    if (str.contains('s')) {
      final digits = str.replaceAll(RegExp(r'[^0-9]'), '');
      seconds = int.tryParse(digits) ?? 0;
    } else if (str.contains(':')) {
      final parts = str.split(':');
      if (parts.length >= 2) {
        seconds = ((int.tryParse(parts[0]) ?? 0) * 60) + (int.tryParse(parts[1]) ?? 0);
      }
    } else {
      seconds = int.tryParse(str) ?? 0;
    }
    return seconds.toDouble();
  }
}
