import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Partículas doradas que orbitan alrededor de la insignia
class OrbitingParticles extends StatefulWidget {
  final bool isActive;
  final int particleCount;
  final double orbitRadius;
  final Widget child;

  const OrbitingParticles({
    super.key,
    required this.isActive,
    required this.child,
    this.particleCount = 8,
    this.orbitRadius = 130.0,
  });

  @override
  State<OrbitingParticles> createState() => _OrbitingParticlesState();
}

class _OrbitingParticlesState extends State<OrbitingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(OrbitingParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // Las partículas orbitando
        if (widget.isActive)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: List.generate(widget.particleCount, (index) {
                  final angle = (2 * math.pi * index / widget.particleCount) +
                      (_controller.value * 2 * math.pi);
                  final x = math.cos(angle) * widget.orbitRadius;
                  final y = math.sin(angle) * widget.orbitRadius;
                  
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFD700),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        // El widget hijo (insignia) en el centro
        widget.child,
      ],
    );
  }
}

/// Efecto de shake (temblor) épico
class ShakeEffect extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final int shakeCount;
  final double shakeOffset;

  const ShakeEffect({
    super.key,
    required this.child,
    required this.isActive,
    this.shakeCount = 3,
    this.shakeOffset = 5.0,
  });

  @override
  State<ShakeEffect> createState() => _ShakeEffectState();
}

class _ShakeEffectState extends State<ShakeEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_controller);
    
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ShakeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calculateShakeOffset(double value) {
    final shakePhase = value * widget.shakeCount * math.pi;
    return math.sin(shakePhase) * widget.shakeOffset * (1 - value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;
    
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_calculateShakeOffset(_shakeAnimation.value), 0),
          child: widget.child,
        );
      },
    );
  }
}

/// Texto con efecto dorado y brillo
class EpicGoldenText extends StatefulWidget {
  final String text;
  final TextStyle? baseStyle;
  final bool isAnimated;

  const EpicGoldenText({
    super.key,
    required this.text,
    this.baseStyle,
    this.isAnimated = true,
  });

  @override
  State<EpicGoldenText> createState() => _EpicGoldenTextState();
}

class _EpicGoldenTextState extends State<EpicGoldenText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isAnimated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    
    final style = widget.baseStyle ?? defaultStyle;
    
    if (!widget.isAnimated) {
      return Text(
        widget.text,
        style: style.copyWith(
          shadows: [
            Shadow(
              color: const Color(0xFFFFD700),
              blurRadius: 10,
            ),
            Shadow(
              color: const Color(0xFFB8860B),
              blurRadius: 20,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      );
    }
    
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Text(
          widget.text,
          style: style.copyWith(
            shadows: [
              Shadow(
                color: const Color(0xFFFFD700).withOpacity(_glowAnimation.value),
                blurRadius: 10 * _glowAnimation.value,
              ),
              Shadow(
                color: const Color(0xFFB8860B).withOpacity(_glowAnimation.value * 0.7),
                blurRadius: 20 * _glowAnimation.value,
              ),
              Shadow(
                color: Colors.orange.withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 30 * _glowAnimation.value,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }
}