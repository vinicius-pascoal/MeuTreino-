import 'package:flutter/material.dart';

import '../../auth/data/auth_service.dart';
import '../../exercises/presentation/exercise_library_page.dart';
import '../../workouts/presentation/workouts_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout() async {
    await AuthService().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeuTreino+'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Acompanhe seus treinos, cargas e evolução.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            _HomeCard(
              title: 'Meus treinos',
              subtitle: 'Crie treinos separados por dia.',
              icon: Icons.calendar_month,
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const WorkoutsPage()));
              },
            ),
            const SizedBox(height: 12),
            _HomeCard(
              title: 'Biblioteca de exercícios',
              subtitle: 'Veja os exercícios com fotos locais.',
              icon: Icons.photo_library,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ExerciseLibraryPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeCard(
              title: 'Progresso',
              subtitle: 'Veja evolução de cargas e histórico.',
              icon: Icons.show_chart,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF22C55E),
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
