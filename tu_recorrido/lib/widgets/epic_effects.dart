import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget que crea un efecto de explosión estelar desde el centro
class StarburstEffect extends StatefulWidget {
  final bool isActive;
  final Color color;
  final int rayCount;
  final double maxRadius;

  const StarburstEffect({
    super.key,
    required this.isActive,
    this.color = const Color(0xFFFFD700),
    this.rayCount = 12,
    this.maxRadius = 150.0,
  });

  @override
  State<StarburstEffect> createState() => _StarburstEffectState();
}

class _StarburstEffectState extends State<StarburstEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _radiusAnimation = Tween<double>(
      begin: 0.0,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));
    
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StarburstEffect oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.maxRadius * 2, widget.maxRadius * 2),
          painter: _StarburstPainter(
            radius: _radiusAnimation.value,
            opacity: _opacityAnimation.value,
            color: widget.color,
            rayCount: widget.rayCount,
          ),
        );
      },
    );
  }
}

class _StarburstPainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Color color;
  final int rayCount;

  _StarburstPainter({
    required this.radius,
    required this.opacity,
    required this.color,
    required this.rayCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < rayCount; i++) {
      final angle = (2 * math.pi * i) / rayCount;
      final start = Offset(
        center.dx + math.cos(angle) * (radius * 0.3),
        center.dy + math.sin(angle) * (radius * 0.3),
      );
      final end = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Efecto de anillo en expansión
class RingExpansion extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double maxRadius;

  const RingExpansion({
    super.key,
    required this.isActive,
    this.color = const Color(0xFFFFD700),
    this.maxRadius = 120.0,
  });

  @override
  State<RingExpansion> createState() => _RingExpansionState();
}

class _RingExpansionState extends State<RingExpansion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _radiusAnimation = Tween<double>(
      begin: 50.0,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));
    
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(RingExpansion oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.maxRadius * 2, widget.maxRadius * 2),
          painter: _RingPainter(
            radius: _radiusAnimation.value,
            opacity: _opacityAnimation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Color color;

  _RingPainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}