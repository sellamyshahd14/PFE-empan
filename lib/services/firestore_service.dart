import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'security_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getAllDoctors() {
    return _db.collection('doctors').snapshots();
  }

  // --- Patients ---

  // Add a new Patient (linked to the current doctor)
  Future<void> addPatient({
    required String firstName,
    required String lastName,
    required String patientIdentifier,
    required DateTime birthDate,
    String? gender,
    String? address,
    String? phone,
    String? insurance,
    String? educationLevel,
    String? maritalStatus,
    String? mainCaregiver,
    Map<String, dynamic>? antecedents,
  }) async {
    User? doctor = _auth.currentUser;
    if (doctor == null) throw Exception("No doctor logged in");

    debugPrint("ADDING PATIENT: Doctor UID = ${doctor.uid}");

    // Check if ID already exists (Check both hashed and plain text for collision safety)
    final hashedId = SecurityService.hashIdentifier(patientIdentifier);
    final existingHashed = await _db
        .collection('patients')
        .where('patientIdentifier', isEqualTo: hashedId)
        .limit(1)
        .get();

    final existingPlain = await _db
        .collection('patients')
        .where('patientIdentifier', isEqualTo: patientIdentifier)
        .limit(1)
        .get();

    if (existingHashed.docs.isNotEmpty || existingPlain.docs.isNotEmpty) {
      throw Exception("Patient ID '$patientIdentifier' already exists!");
    }

    final Map<String, dynamic> patientData = {
      'firstName': firstName,
      'lastName': lastName,
      'patientIdentifier': hashedId, // The ID used for login (Hashed)
      'patientDisplayId': SecurityService.encryptIdentifier(patientIdentifier), // The ID for doctors (Encrypted)
      'birthDate': Timestamp.fromDate(birthDate),
      'gender': gender,
      'address': address,
      'phone': phone,
      'insurance': insurance,
      'educationLevel': educationLevel,
      'maritalStatus': maritalStatus,
      'mainCaregiver': mainCaregiver,
      'antecedents': antecedents,
      'createdByDoctorId': doctor.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'isSecure': true, // System flag for decryption logic
    };

    await _db.collection('patients').add(patientData);
    debugPrint("PATIENT ADDED SUCCESSFULLY");
  }

  // Get Patients created by the current doctor
  Stream<QuerySnapshot> getDoctorPatients() {
    User? doctor = _auth.currentUser;
    if (doctor == null) {
      debugPrint("GET PATIENTS: No doctor logged in!");
      return const Stream.empty();
    }

    debugPrint("FETCHING PATIENTS FOR DOCTOR UID: ${doctor.uid}");

    return _db
        .collection('patients')
        // .where('createdByDoctorId', isEqualTo: doctor.uid) // Removed for central database visibility
        .snapshots();
  }

  // Verify Patient exists by ID (for Patient Login)
  Future<Map<String, dynamic>?> getPatientById(String patientIdentifier) async {
    final hashed = SecurityService.hashIdentifier(patientIdentifier);

    // 1. First, try searching for the secure Hashed ID
    var snapshot = await _db
        .collection('patients')
        .where('patientIdentifier', isEqualTo: hashed)
        .limit(1)
        .get();

    // 2. If not found, fall back to Plain Text (Backward compatibility for existing clinical data)
    if (snapshot.docs.isEmpty) {
      debugPrint("Patient not found by hash, falling back to plain text lookup...");
      snapshot = await _db
          .collection('patients')
          .where('patientIdentifier', isEqualTo: patientIdentifier)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();
      data['docId'] = snapshot.docs.first.id; // Include the DB ID

      // For old data, the 'patientDisplayId' won't exist.
      // We ensure the app has a decrypted string to work with.
      if (data['patientDisplayId'] != null) {
        data['resolvedDisplayId'] = SecurityService.decryptIdentifier(data['patientDisplayId']);
      } else {
        data['resolvedDisplayId'] = data['patientIdentifier']; // Old plain text
      }

      return data;
    }
    return null;
  }

  // --- Results ---

  // Save a Test Result
  Future<String> saveTestResult({
    String? docId, // Add this
    required String patientDocId, // The DB ID of the patient
    required String patientIdentifier,
    double? score,
    double? scoreA, // HADS Anxiety
    double? scoreD, // HADS Depression
    String totalDuration = "N/A",
    String testType = 'Empan', // Default for retro-compatibility
    int errors = 0,
    String? testName,
    Map<String, dynamic>? metadata,
  }) async {
    // If testName is passed, it overrides testType
    String finalTestType = testName ?? testType;

    // We try to find the doctor associated with this patient to link the result
    // (Optional: could verify patient ownership here)

    final Map<String, dynamic> data = {
      'patientId': patientDocId,
      'patientIdentifier': SecurityService.hashIdentifier(
        patientIdentifier,
      ), // Store hash in results for consistency
      'duration': totalDuration,
      'testType': finalTestType,
      'errors': errors,
      'timestamp': FieldValue.serverTimestamp(),
      'dateStr':
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
    };

    if (score != null) data['score'] = score;
    if (scoreA != null) data['scoreA'] = scoreA;
    if (scoreD != null) data['scoreD'] = scoreD;
    if (metadata != null) data.addAll(metadata);

    if (docId != null) {
      await _db.collection('results').doc(docId).set(data);
      return docId;
    } else {
      DocumentReference docRef = await _db.collection('results').add(data);
      return docRef.id;
    }
  }

  // Get Results for a specific Patient
  Stream<QuerySnapshot> getPatientResults(String patientId) {
    debugPrint("QUERY RESULTS: patientId=$patientId");
    return _db
        .collection('results')
        .where('patientId', isEqualTo: patientId)
        // .orderBy('timestamp', descending: true) // Commented out for now
        .snapshots();
  }

  // --- Backup ---
  Future<Map<String, dynamic>> getAllDataForBackup() async {
    final patients = await _db.collection('patients').get();
    final results = await _db.collection('results').get();

    Map<String, dynamic> docToData(DocumentSnapshot d) {
      final data = d.data() as Map<String, dynamic>? ?? {};
      final Map<String, dynamic> result = Map.from(data);
      result.forEach((key, value) {
        if (value is Timestamp) {
          result[key] = value.toDate().toIso8601String();
        }
      });
      result['_docId'] = d.id;
      return result;
    }

    return {
      'patients': patients.docs.map(docToData).toList(),
      'results': results.docs.map(docToData).toList(),
      'backupDate': DateTime.now().toIso8601String(),
    };
  }
}
