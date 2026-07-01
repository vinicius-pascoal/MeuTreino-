import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserExerciseStatsService {
  UserExerciseStatsService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _userId {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('UsuÃ¡rio nÃ£o autenticado.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _statsCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('exercise_stats');
  }

  Future<double?> getLastUsedWeight({required String exerciseLibraryId}) async {
    final normalizedId = exerciseLibraryId.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final doc = await _statsCollection.doc(normalizedId).get();

    if (!doc.exists) {
      return null;
    }

    final weight = doc.data()?['lastUsedWeight'];

    if (weight is! num) {
      return null;
    }

    return weight.toDouble();
  }
}
