import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppTheme.pageGradient),
      child: Stack(
        children: [
          const Positioned(
            top: -140,
            left: -120,
            child: _GlowBlob(
              size: 320,
              color: AppThemeColors.primary,
              opacity: 0.12,
            ),
          ),
          const Positioned(
            top: 80,
            right: -80,
            child: _GlowBlob(
              size: 240,
              color: AppThemeColors.secondary,
              opacity: 0.08,
            ),
          ),
          const Positioned(
            bottom: -120,
            right: -140,
            child: _GlowBlob(
              size: 280,
              color: Colors.white,
              opacity: 0.03,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const _GlowBlob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
        child: SizedBox(width: size, height: size),
      ),
    );
  }
}
