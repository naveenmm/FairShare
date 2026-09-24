import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      return _auth.signInWithPopup(GoogleAuthProvider());
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw StateError('Google sign-in was cancelled.');
    }

    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

class BillCloudRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _bills(String uid) {
    return _firestore.collection('users').doc(uid).collection('bills');
  }

  Future<List<SavedBill>> fetchBills(String uid) async {
    final snapshot = await _bills(uid).orderBy('date', descending: true).get();
    return snapshot.docs
        .map((document) => SavedBill.fromJson(document.data()))
        .toList();
  }

  Future<void> saveBill(String uid, SavedBill bill) {
    return _bills(uid).doc(bill.id).set(bill.toJson());
  }

  Future<void> deleteBill(String uid, String billId) {
    return _bills(uid).doc(billId).delete();
  }
}
