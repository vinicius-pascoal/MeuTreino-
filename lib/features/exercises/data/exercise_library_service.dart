import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/exercise.dart';

class ExerciseLibraryService {
  ExerciseLibraryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection('exercise_library');
  }

  Stream<List<Exercise>> watchExercises() {
    return _collection
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList(),
        );
  }

  Future<void> seedDefaultExercises() async {
    final batch = _firestore.batch();

    for (final exercise in _defaultExercises) {
      final docRef = _collection.doc(exercise['id'] as String);

      batch.set(docRef, {
        'name': exercise['name'],
        'muscleGroup': exercise['muscleGroup'],
        'imageAsset': exercise['imageAsset'],
        'instructions': exercise['instructions'],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}

final List<Map<String, dynamic>> _defaultExercises = [
  {
    'id': 'supino_reto_halteres',
    'name': 'Supino reto com halteres',
    'muscleGroup': 'Peito',
    'imageAsset': 'assets/exercises/supino_reto_halteres.jpg',
    'instructions':
        'Deite no banco, mantenha os pés firmes no chão e empurre os halteres para cima controlando a descida.',
  },
  {
    'id': 'supino_inclinado_halteres',
    'name': 'Supino inclinado com halteres',
    'muscleGroup': 'Peito',
    'imageAsset': 'assets/exercises/supino_inclinado_halteres.jpg',
    'instructions':
        'Use o banco inclinado, mantenha os ombros estabilizados e controle o movimento.',
  },
  {
    'id': 'puxada_frente',
    'name': 'Puxada frente',
    'muscleGroup': 'Costas',
    'imageAsset': 'assets/exercises/puxada_frente.jpg',
    'instructions':
        'Puxe a barra em direção à parte superior do peito, mantendo o tronco firme.',
  },
  {
    'id': 'remada_baixa',
    'name': 'Remada baixa',
    'muscleGroup': 'Costas',
    'imageAsset': 'assets/exercises/remada_baixa.jpg',
    'instructions':
        'Puxe o cabo em direção ao abdômen, aproximando as escápulas no final do movimento.',
  },
  {
    'id': 'leg_press',
    'name': 'Leg press',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/leg_press.jpg',
    'instructions':
        'Posicione os pés na plataforma e empurre sem travar completamente os joelhos.',
  },
  {
    'id': 'cadeira_extensora',
    'name': 'Cadeira extensora',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/cadeira_extensora.jpg',
    'instructions':
        'Estenda os joelhos de forma controlada e evite impulsos durante o movimento.',
  },
  {
    'id': 'mesa_flexora',
    'name': 'Mesa flexora',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/mesa_flexora.jpg',
    'instructions':
        'Flexione os joelhos controlando a subida e a descida do peso.',
  },
  {
    'id': 'triceps_corda',
    'name': 'Tríceps corda',
    'muscleGroup': 'Tríceps',
    'imageAsset': 'assets/exercises/triceps_corda.jpg',
    'instructions':
        'Mantenha os cotovelos próximos ao corpo e estenda os braços até o final.',
  },
  {
    'id': 'rosca_direta',
    'name': 'Rosca direta',
    'muscleGroup': 'Bíceps',
    'imageAsset': 'assets/exercises/rosca_direta.jpg',
    'instructions':
        'Flexione os cotovelos mantendo o tronco estável e evitando balanço.',
  },
  {
    'id': 'elevacao_lateral',
    'name': 'Elevação lateral',
    'muscleGroup': 'Ombro',
    'imageAsset': 'assets/exercises/elevacao_lateral.jpg',
    'instructions':
        'Eleve os braços lateralmente até próximo da linha dos ombros, com controle.',
  },
];
