import 'package:flutter/material.dart';

import '../data/auth_service.dart';
import 'register_page.dart';
import 'widgets/auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao entrar: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _goToRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Treino organizado,\nprogresso claro.',
      subtitle:
          'Entre para acompanhar sua rotina com uma interface mais limpa e focada no essencial.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Senha'),
            obscureText: true,
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('Entrar'),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _goToRegister,
              child: const Text('Criar conta'),
            ),
          ),
        ],
      ),
    );
  }
}
