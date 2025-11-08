// auth/data/repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../domain/entities/user_entity.dart';
import '../domain/repositories/repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserEntity?> signUp(String name, String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user?.uid;
      if (userId == null) {
        return null;
      }

      await _firestore.collection('users').doc(userId).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return UserEntity(id: userId, email: email, name: name);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = credential.user?.uid;
      if (userId == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null) {
        return null;
      }

      return UserEntity(id: userId, email: email, name: data['name'] ?? '');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      debugPrint('getCurrentUser called, user: ${user?.uid}');
      if (user == null) {
         debugPrint('No current user found');
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data == null) {
        return null;
      }

      return UserEntity(
        id: user.uid,
        email: user.email ?? '',
        name: data['name'] ?? '',
      );
    } catch (e) {
       debugPrint('Error in getCurrentUser: $e');
       rethrow;
    }
  }
}
