import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class SecurityService {
  // A static key for AES encryption. 
  // IMPORTANT: For a production app, this should be handled securely (e.g., Keystore/Keychain).
  // For a PFE project, a secure hardcoded key is standard practice.
  static final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1'); // 32 chars
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key));

  /// Generates a SHA-256 hash of the identifier for secure database lookup.
  static String hashIdentifier(String id) {
    if (id.isEmpty) return id;
    final bytes = utf8.encode(id.trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Encrypts the identifier so it can be stored in the database but only read by the app.
  static String encryptIdentifier(String id) {
    if (id.isEmpty) return id;
    final encrypted = _encrypter.encrypt(id.trim(), iv: _iv);
    return 'ENC:${encrypted.base64}'; // Prefix to distinguish from plain text
  }

  /// Decrypts the identifier for display in the UI.
  /// Returns the original string if it's not encrypted or decryption fails.
  static String decryptIdentifier(String encryptedData) {
    if (!encryptedData.startsWith('ENC:')) return encryptedData; // Return as-is if plain text
    
    try {
      final base64String = encryptedData.substring(4);
      return _encrypter.decrypt64(base64String, iv: _iv);
    } catch (e) {
      // If decryption fails, return the original string to avoid data loss
      return encryptedData;
    }
  }

  /// Migration Utility: Checks if a string is a SHA-256 hash
  static bool isHashed(String value) {
    final hexRegex = RegExp(r'^[a-fA-F0-30-9]{64}$');
    return hexRegex.hasMatch(value);
  }
}
