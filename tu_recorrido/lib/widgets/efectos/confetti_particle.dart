import 'package:flutter/material.dart';

/// Partícula de confeti simple (placeholder).
class ConfettiParticle extends StatelessWidget {
  final Color color;
  final double size;

  const ConfettiParticle({super.key, this.color = Colors.orange, this.size = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
