import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/widgets/app_background.dart';

class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBackButton) ...[
                      IconButton(
                        tooltip: 'Voltar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppThemeColors.outline),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 18,
                            color: AppThemeColors.primaryStrong,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'MeuTreino+',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(title, style: theme.textTheme.displaySmall),
                    const SizedBox(height: 10),
                    Text(subtitle, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppThemeColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppThemeColors.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 28,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
