import 'package:flutter/material.dart';

/// Widget que crea un efecto de resplandor pulsante alrededor de un widget hijo
class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double maxGlowRadius;
  final Duration pulseDuration;
  final bool isActive;

  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFFFD700), // Dorado por defecto
    this.maxGlowRadius = 20.0,
    this.pulseDuration = const Duration(milliseconds: 1500),
    this.isActive = true,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.glowColor
                    .withAlpha(((0.3 * _glowAnimation.value) * 255).round()),
                blurRadius: widget.maxGlowRadius * _glowAnimation.value,
                spreadRadius:
                    (widget.maxGlowRadius * 0.3) * _glowAnimation.value,
              ),
              BoxShadow(
                color: widget.glowColor
                    .withAlpha(((0.1 * _glowAnimation.value) * 255).round()),
                blurRadius: (widget.maxGlowRadius * 1.5) * _glowAnimation.value,
                spreadRadius:
                    (widget.maxGlowRadius * 0.5) * _glowAnimation.value,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Widget de resplandor dorado más intenso para momentos especiales
class GoldenGlow extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final double intensity;

  const GoldenGlow({
    super.key,
    required this.child,
    this.isActive = true,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return PulseGlow(
      isActive: isActive,
      glowColor: const Color(0xFFFFD700),
      maxGlowRadius: 25.0 * intensity,
      pulseDuration: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}
