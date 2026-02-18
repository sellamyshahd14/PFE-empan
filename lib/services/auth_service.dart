import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign In
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Auth Error: ${e.message}");
      rethrow;
    }
  }

  // Sign Up (Doctor)
  Future<User?> registerDoctor({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String doctorId,
  }) async {
    try {
      // 1. Create User in Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 2. Create Doctor Document in Firestore
        await _firestore.collection('doctors').doc(user.uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'doctorId': doctorId,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Registration Error: ${e.message}");
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
