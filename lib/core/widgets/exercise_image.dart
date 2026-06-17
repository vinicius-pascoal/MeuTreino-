import 'package:flutter/material.dart';

class ExerciseImage extends StatelessWidget {
  final String imageAsset;
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const ExerciseImage({
    super.key,
    required this.imageAsset,
    this.height = 160,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  Widget build(BuildContext context) {
    if (imageAsset.isEmpty) {
      return _fallback();
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        imageAsset,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fallback();
        },
      ),
    );
  }

  Widget _fallback() {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: borderRadius,
      ),
      child: const Icon(Icons.fitness_center, size: 48, color: Colors.white70),
    );
  }
}
