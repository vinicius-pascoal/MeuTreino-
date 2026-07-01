import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AppSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(subtitle, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
