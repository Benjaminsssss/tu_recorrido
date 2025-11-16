import 'package:flutter/material.dart';

/// Efecto de pulso y glow reutilizable
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double glowRadius;

  const PulseGlow({super.key, required this.child, this.duration = const Duration(seconds: 2), this.glowRadius = 12});

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: widget.duration)..repeat(reverse: true);
  late final Animation<double> _anim = Tween(begin: 0.0, end: widget.glowRadius).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withAlpha((0.25 * 255).round()),
                blurRadius: _anim.value,
                spreadRadius: _anim.value / 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Wrapper para un resplandor dorado más intenso
class GoldenGlow extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final double intensity;

  const GoldenGlow({super.key, required this.child, this.isActive = true, this.intensity = 1.0});

  @override
  Widget build(BuildContext context) {
    return PulseGlow(
      duration: const Duration(milliseconds: 1200),
      glowRadius: 20.0 * intensity,
      child: child,
    );
  }
}
