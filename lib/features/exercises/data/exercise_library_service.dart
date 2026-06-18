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

  Future<List<Exercise>> getExercisesOnce() async {
    final snapshot = await _collection.orderBy('name').get();

    return snapshot.docs.map((doc) => Exercise.fromFirestore(doc)).toList();
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
    'id': 'crucifixo_halteres',
    'name': 'Crucifixo com halteres',
    'muscleGroup': 'Peito',
    'imageAsset': 'assets/exercises/crucifixo_halteres.jpg',
    'instructions':
        'Abra os braços de forma controlada e retorne contraindo o peitoral.',
  },
  {
    'id': 'peck_deck',
    'name': 'Peck deck',
    'muscleGroup': 'Peito',
    'imageAsset': 'assets/exercises/peck_deck.jpg',
    'instructions':
        'Aproxime os braços à frente do corpo contraindo o peitoral.',
  },
  {
    'id': 'crossover',
    'name': 'Crossover',
    'muscleGroup': 'Peito',
    'imageAsset': 'assets/exercises/crossover.jpg',
    'instructions':
        'Puxe os cabos à frente do corpo mantendo controle durante todo o movimento.',
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
    'id': 'remada_unilateral_halter',
    'name': 'Remada unilateral com halter',
    'muscleGroup': 'Costas',
    'imageAsset': 'assets/exercises/remada_unilateral_halter.jpg',
    'instructions':
        'Apoie uma mão no banco e puxe o halter em direção ao quadril.',
  },
  {
    'id': 'remada_curvada',
    'name': 'Remada curvada',
    'muscleGroup': 'Costas',
    'imageAsset': 'assets/exercises/remada_curvada.jpg',
    'instructions':
        'Incline o tronco, mantenha a coluna estável e puxe a barra em direção ao abdômen.',
  },
  {
    'id': 'pulldown',
    'name': 'Pulldown',
    'muscleGroup': 'Costas',
    'imageAsset': 'assets/exercises/pulldown.jpg',
    'instructions':
        'Mantenha os braços quase estendidos e puxe a barra para baixo contraindo as costas.',
  },
  {
    'id': 'desenvolvimento_halteres',
    'name': 'Desenvolvimento com halteres',
    'muscleGroup': 'Ombro',
    'imageAsset': 'assets/exercises/desenvolvimento_halteres.jpg',
    'instructions':
        'Empurre os halteres acima da cabeça mantendo controle e estabilidade.',
  },
  {
    'id': 'elevacao_lateral',
    'name': 'Elevação lateral',
    'muscleGroup': 'Ombro',
    'imageAsset': 'assets/exercises/elevacao_lateral.jpg',
    'instructions':
        'Eleve os braços lateralmente até próximo da linha dos ombros, com controle.',
  },
  {
    'id': 'elevacao_frontal',
    'name': 'Elevação frontal',
    'muscleGroup': 'Ombro',
    'imageAsset': 'assets/exercises/elevacao_frontal.jpg',
    'instructions': 'Eleve os halteres à frente do corpo com o tronco estável.',
  },
  {
    'id': 'crucifixo_inverso',
    'name': 'Crucifixo inverso',
    'muscleGroup': 'Ombro',
    'imageAsset': 'assets/exercises/crucifixo_inverso.jpg',
    'instructions': 'Abra os braços contraindo a parte posterior dos ombros.',
  },
  {
    'id': 'remada_alta',
    'name': 'Remada alta',
    'muscleGroup': 'Ombro',
    'imageAsset': 'assets/exercises/remada_alta.jpg',
    'instructions':
        'Puxe a barra em direção ao peito mantendo os cotovelos elevados.',
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
    'id': 'rosca_alternada',
    'name': 'Rosca alternada',
    'muscleGroup': 'Bíceps',
    'imageAsset': 'assets/exercises/rosca_alternada.jpg',
    'instructions': 'Flexione um braço por vez controlando a descida.',
  },
  {
    'id': 'rosca_martelo',
    'name': 'Rosca martelo',
    'muscleGroup': 'Bíceps',
    'imageAsset': 'assets/exercises/rosca_martelo.jpg',
    'instructions':
        'Segure os halteres com pegada neutra e flexione os cotovelos.',
  },
  {
    'id': 'rosca_scott',
    'name': 'Rosca Scott',
    'muscleGroup': 'Bíceps',
    'imageAsset': 'assets/exercises/rosca_scott.jpg',
    'instructions':
        'Apoie os braços no banco Scott e faça a flexão dos cotovelos com controle.',
  },
  {
    'id': 'rosca_polia',
    'name': 'Rosca na polia',
    'muscleGroup': 'Bíceps',
    'imageAsset': 'assets/exercises/rosca_polia.jpg',
    'instructions':
        'Flexione os cotovelos usando a polia, mantendo tensão constante no bíceps.',
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
    'id': 'triceps_barra',
    'name': 'Tríceps barra',
    'muscleGroup': 'Tríceps',
    'imageAsset': 'assets/exercises/triceps_barra.jpg',
    'instructions': 'Empurre a barra para baixo mantendo os cotovelos fixos.',
  },
  {
    'id': 'triceps_testa',
    'name': 'Tríceps testa',
    'muscleGroup': 'Tríceps',
    'imageAsset': 'assets/exercises/triceps_testa.jpg',
    'instructions':
        'Flexione e estenda os cotovelos controlando a barra ou halteres.',
  },
  {
    'id': 'triceps_banco',
    'name': 'Tríceps banco',
    'muscleGroup': 'Tríceps',
    'imageAsset': 'assets/exercises/triceps_banco.jpg',
    'instructions':
        'Apoie as mãos no banco e flexione os cotovelos descendo o corpo.',
  },
  {
    'id': 'mergulho_maquina',
    'name': 'Mergulho na máquina',
    'muscleGroup': 'Tríceps',
    'imageAsset': 'assets/exercises/mergulho_maquina.jpg',
    'instructions':
        'Empurre as alavancas para baixo controlando a subida e a descida.',
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
    'id': 'agachamento_livre',
    'name': 'Agachamento livre',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/agachamento_livre.jpg',
    'instructions':
        'Agache mantendo o tronco firme, joelhos alinhados e controle do movimento.',
  },
  {
    'id': 'agachamento_smith',
    'name': 'Agachamento no smith',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/agachamento_smith.jpg',
    'instructions':
        'Agache com a barra guiada, mantendo o controle e a postura estável.',
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
    'id': 'cadeira_abdutora',
    'name': 'Cadeira abdutora',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/cadeira_abdutora.jpg',
    'instructions':
        'Afaste as pernas contra a resistência, mantendo controle no retorno.',
  },
  {
    'id': 'cadeira_adutora',
    'name': 'Cadeira adutora',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/cadeira_adutora.jpg',
    'instructions':
        'Aproxime as pernas contra a resistência, mantendo controle no retorno.',
  },
  {
    'id': 'panturrilha_em_pe',
    'name': 'Panturrilha em pé',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/panturrilha_em_pe.jpg',
    'instructions':
        'Eleve os calcanhares contraindo as panturrilhas e retorne com controle.',
  },
  {
    'id': 'stiff',
    'name': 'Stiff',
    'muscleGroup': 'Pernas',
    'imageAsset': 'assets/exercises/stiff.jpg',
    'instructions':
        'Incline o tronco mantendo a coluna estável e sentindo alongamento posterior.',
  },
  {
    'id': 'abdominal_crunch',
    'name': 'Abdominal crunch',
    'muscleGroup': 'Abdômen',
    'imageAsset': 'assets/exercises/abdominal_crunch.jpg',
    'instructions': 'Eleve o tronco contraindo o abdômen, sem puxar o pescoço.',
  },
  {
    'id': 'prancha',
    'name': 'Prancha',
    'muscleGroup': 'Abdômen',
    'imageAsset': 'assets/exercises/prancha.jpg',
    'instructions':
        'Mantenha o corpo alinhado sustentando a posição com o abdômen contraído.',
  },
  {
    'id': 'elevacao_pernas',
    'name': 'Elevação de pernas',
    'muscleGroup': 'Abdômen',
    'imageAsset': 'assets/exercises/elevacao_pernas.jpg',
    'instructions': 'Eleve as pernas com controle, evitando impulsos.',
  },
  {
    'id': 'abdominal_polia',
    'name': 'Abdominal na polia',
    'muscleGroup': 'Abdômen',
    'imageAsset': 'assets/exercises/abdominal_polia.jpg',
    'instructions':
        'Flexione o tronco contra a resistência da polia, contraindo o abdômen.',
  },
];
