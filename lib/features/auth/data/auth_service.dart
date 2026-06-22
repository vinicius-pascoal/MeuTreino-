import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../home_widgets/data/app_home_widget_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  User? get currentUser => _auth.currentUser;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Não foi possível criar o usuário.');
    }

    await user.updateDisplayName(name.trim());

    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() async {
    await AppHomeWidgetService().clearTodayWorkoutWidget();
    await _auth.signOut();
  }
}
