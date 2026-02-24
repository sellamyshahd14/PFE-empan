import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- Patients ---

  // Add a new Patient (linked to the current doctor)
  Future<void> addPatient({
    required String firstName,
    required String lastName,
    required String patientIdentifier,
    required DateTime birthDate,
  }) async {
    User? doctor = _auth.currentUser;
    if (doctor == null) throw Exception("No doctor logged in");

    debugPrint("ADDING PATIENT: Doctor UID = ${doctor.uid}");

    // Check if ID already exists (Globally or Per Doctor? Usually Per Doctor is safer, but Global avoids confusion)
    final existingParams = await _db
        .collection('patients')
        .where('patientIdentifier', isEqualTo: patientIdentifier)
        .limit(1)
        .get();

    if (existingParams.docs.isNotEmpty) {
      throw Exception("Patient ID '$patientIdentifier' already exists!");
    }

    await _db.collection('patients').add({
      'firstName': firstName,
      'lastName': lastName,
      'patientIdentifier': patientIdentifier, // The ID used for login
      'birthDate': Timestamp.fromDate(birthDate),
      'createdByDoctorId': doctor.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
        .where('createdByDoctorId', isEqualTo: doctor.uid)
        // .orderBy('createdAt', descending: true) // Commented out to debug Index/Ordering issues
        .snapshots();
  }

  // Verify Patient exists by ID (for Patient Login)
  Future<Map<String, dynamic>?> getPatientById(String patientIdentifier) async {
    final snapshot = await _db
        .collection('patients')
        .where('patientIdentifier', isEqualTo: patientIdentifier)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      var data = snapshot.docs.first.data();
      data['docId'] = snapshot.docs.first.id; // Include the DB ID
      return data;
    }
    return null;
  }

  // --- Results ---

  // Save a Test Result
  Future<void> saveTestResult({
    required String patientId, // The DB ID of the patient
    required String patientIdentifier,
    required double score, // Can be -1 or 0 if not applicable for TMT
    required String totalDuration,
    String testType = 'TMT', // Default or specific 'TMT-A', 'TMT-B'
    int errors = 0, // Number of wrong moves
  }) async {
    // We try to find the doctor associated with this patient to link the result
    // (Optional: could verify patient ownership here)

    await _db.collection('results').add({
      'patientId': patientId,
      'patientIdentifier': patientIdentifier,
      'score': score,
      'duration': totalDuration,
      'testType': testType,
      'errors': errors,
      'timestamp': FieldValue.serverTimestamp(),
      'dateStr':
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
    });
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

  // Get All Results for the Doctor (by fetching patients first or storing doctorId on result)
  // For simplicity, we might store doctorId on the specific result if needed.
  // But usually, we view results PER patient.
}
