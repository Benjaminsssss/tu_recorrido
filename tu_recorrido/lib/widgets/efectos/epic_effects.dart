import 'package:flutter/material.dart';

/// Conjunto de efectos épicos reutilizables (placeholder)
class EpicEffects extends StatelessWidget {
  final Widget child;

  const EpicEffects({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Efectos visuales de fondo
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.06,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50]),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
