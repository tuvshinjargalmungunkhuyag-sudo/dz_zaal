import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  // Firebase-с ирсэн +97688001234 → 88001234 болгоно
  static String? get currentPhone {
    final p = _auth.currentUser?.phoneNumber;
    if (p == null) return null;
    final digits = p.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 ? digits.substring(digits.length - 8) : digits;
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Хэрэглэгчийн нэрийг Firestore-оос татах
  static Future<String?> getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final phone = currentPhone ?? user.uid;
    final snap = await _db.collection('users').doc(phone).get();
    return snap.data()?['name'] as String?;
  }

  // Хэрэглэгчийн нэрийг хадгалах (эхний нэвтрэлтэд)
  static Future<void> saveUserName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Нэвтрээгүй байна');

    // Phone: +97689773009 → 89773009 (сүүлийн 8 орон)
    final phone = currentPhone ?? user.uid;
    await _db.collection('users').doc(phone).set({
      'name': name,
      'phone': phone,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Утасны дугаар баталгаажуулах OTP илгээх
  static Future<void> verifyPhone({
    required String phone, // 8 оронтой: 88001234
    required void Function(PhoneAuthCredential) onAutoVerified,
    required void Function(FirebaseAuthException) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+976$phone',
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // OTP баталгаажуулж нэвтрэх
  static Future<UserCredential> signInWithOtp(
      String verificationId, String smsCode) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(credential);
  }

  static Future<void> signOut() => _auth.signOut();
}
