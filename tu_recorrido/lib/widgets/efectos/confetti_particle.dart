import 'dart:math';
import 'package:flutter/material.dart';

/// Widget individual de partícula de confetti
class ConfettiParticle extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;
  final double startX;

  const ConfettiParticle({
    super.key,
    required this.color,
    required this.size,
    required this.duration,
    required this.startX,
  });

  @override
  State<ConfettiParticle> createState() => _ConfettiParticleState();
}

class _ConfettiParticleState extends State<ConfettiParticle>
    with TickerProviderStateMixin {
  late AnimationController _fallController;
  late AnimationController _rotationController;
  late Animation<double> _fallAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  final Random _random = Random();
  late double _horizontalDrift;

  @override
  void initState() {
    super.initState();

    _horizontalDrift = _random.nextDouble() * 100 - 50; // -50 a +50

    // Animación de caída
    _fallController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fallAnimation = Tween<double>(
      begin: -widget.size,
      end: MediaQuery.of(context).size.height + widget.size,
    ).animate(CurvedAnimation(
      parent: _fallController,
      curve: Curves.easeIn,
    ));

    // Animación de rotación
    _rotationController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds ~/ 2),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: _random.nextDouble() * 4 * pi,
    ).animate(_rotationController);

    // Animación de fade out al final
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fallController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _fallController.forward();
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _fallController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fallController, _rotationController]),
      builder: (context, child) {
        return Positioned(
          left: widget.startX + (_horizontalDrift * _fallController.value),
          top: _fallAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withAlpha((0.3 * 255).round()),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget que maneja múltiples partículas de confetti
class ConfettiOverlay extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onComplete;

  const ConfettiOverlay({
    super.key,
    required this.isActive,
    this.onComplete,
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> {
  final List<ConfettiParticle> _particles = [];
  final Random _random = Random();

  final List<Color> _colors = [
    Colors.amber,
    Colors.yellow,
    Colors.orange,
    Colors.deepOrange,
    const Color(0xFFFFD700), // Dorado
    const Color(0xFFB8860B), // Dorado oscuro
  ];

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startConfetti();
    } else if (!widget.isActive && oldWidget.isActive) {
      _stopConfetti();
    }
  }

  void _startConfetti() {
    setState(() {
      _particles.clear();

      // Crear 15-20 partículas
      for (int i = 0; i < 18; i++) {
        _particles.add(ConfettiParticle(
          color: _colors[_random.nextInt(_colors.length)],
          size: _random.nextDouble() * 8 + 4, // 4-12 píxeles
          duration: Duration(
            milliseconds: _random.nextInt(1000) + 2000, // 2-3 segundos
          ),
          startX: _random.nextDouble() * MediaQuery.of(context).size.width,
        ));
      }
    });

    // Llamar onComplete después de que termine la animación más larga
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  void _stopConfetti() {
    setState(() {
      _particles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _particles,
        ),
      ),
    );
  }
}