import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _cachedUser;

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) {
        _cachedUser = null;
        return null;
      }
      return await _getUserFromFirestore(fbUser.uid);
    });
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = UserModel.fromMap(doc.data()!);
        return _cachedUser;
      }
    } catch (e) {
      print('Error getting user from Firestore: $e');
    }
    return null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    if (_cachedUser != null && _cachedUser!.uid == fbUser.uid) {
      return _cachedUser;
    }
    return await _getUserFromFirestore(fbUser.uid);
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        return await _getUserFromFirestore(credential.user!.uid);
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to sign in');
    }
    return null;
  }

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String studentId,
    required String department,
    required UserRole role,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser != null) {
        final newUser = UserModel(
          uid: fbUser.uid,
          name: name,
          email: email,
          studentId: role == UserRole.student ? studentId : '',
          department: role == UserRole.student ? department : '',
          role: role,
        );
        
        // Save to Firestore
        await _firestore.collection('users').doc(fbUser.uid).set(newUser.toMap());
        _cachedUser = newUser;
        return newUser;
      }
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Failed to register user');
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _cachedUser = null;
  }
}
