import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get currentEmail => _auth.currentUser?.email;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Бүртгүүлэх ────────────────────────────────────────────────────────────

  // Firebase user үүсгэж, Firestore-д хадгалах (emailVerified: false)
  static Future<void> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'uid': uid,
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Email баталгаажуулах код ───────────────────────────────────────────────

  // Firebase user болон Firestore doc-г устгах (rollback)
  static Future<void> deleteCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    try {
      if (uid != null) {
        await _db.collection('users').doc(uid).delete();
      }
    } catch (_) {}
    try {
      await _auth.currentUser?.delete();
    } catch (_) {}
  }

  static Future<void> sendVerificationCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    try {
      final res = await http.post(
        Uri.parse('${AppConfig.authEndpoint}/send-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user.email, 'uid': user.uid}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        String errorMsg = 'Код илгээхэд алдаа гарлаа';
        try {
          final body = jsonDecode(res.body);
          errorMsg = body['error'] ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('Connection') ||
          msg.contains('TimeoutException') ||
          msg.contains('Cleartext')) {
        throw Exception('Сервертэй холбогдож чадсангүй. Интернэт холболтоо шалгана уу');
      }
      rethrow;
    }
  }

  static Future<void> verifyEmailCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    final res = await http.post(
      Uri.parse('${AppConfig.authEndpoint}/verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': user.uid, 'code': code}),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Код буруу байна');
    }
  }

  // ── Нэвтрэх ───────────────────────────────────────────────────────────────

  static Future<UserCredential> signInWithEmail(
      String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Email баталгаажсан эсэх шалгах
    final uid = credential.user!.uid;
    final snap = await _db.collection('users').doc(uid).get();
    final verified = snap.data()?['emailVerified'] == true;
    if (!verified) {
      await _auth.signOut();
      throw Exception('email-not-verified');
    }

    return credential;
  }

  // ── Хэрэглэгчийн мэдээлэл ─────────────────────────────────────────────────

  static Future<String?> getUserName() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('users').doc(uid).get();
    return snap.data()?['name'] as String?;
  }

  static Future<void> signOut() => _auth.signOut();
}
