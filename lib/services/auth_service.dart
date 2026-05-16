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

      User? user = result.user;
      if (user != null) {
        // Liste d'exception pour les médecins déjà actifs
        List<String> legacyDoctors = [
          'mariem-dammak@test.com',
          'nouha.farhat15@gmail.com'
        ];

        if (!user.emailVerified && !legacyDoctors.contains(user.email)) {
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message:
                'Veuillez vérifier votre boîte mail avant de vous connecter.',
          );
        }
      }
      return user;
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
          'isAdmin': false, // Default role for safety
          'createdAt': FieldValue.serverTimestamp(),
          'uid': user.uid,
        });

        // 3. Send Email Verification
        await user.sendEmailVerification();
      }
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint("Registration Error: ${e.message}");
      rethrow;
    }
  }

  // Check if current user is Admin (Cached check or quick fetch)
  Future<bool> isCurrentUserAdmin() async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('doctors').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isAdmin'] == true;
      }
    } catch (e) {
      debugPrint("Error checking admin status: $e");
    }
    return false;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
