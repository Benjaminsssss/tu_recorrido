import 'package:flutter/material.dart';

/// Efectos orbitantes sencillos para decorar la UI
class OrbitalEffects extends StatelessWidget {
  final Widget child;

  const OrbitalEffects({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // círculos orbitantes (placeholder)
        Positioned(
          left: 20,
          top: 40,
          child: _dot(24, Colors.pink.withAlpha((0.12 * 255).round())),
        ),
        Positioned(
          right: 20,
          bottom: 40,
          child: _dot(40, Colors.blue.withAlpha((0.08 * 255).round())),
        ),
        child,
      ],
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
