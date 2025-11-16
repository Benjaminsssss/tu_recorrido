import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/estacion_visitada.dart';
import '../efectos/pulse_glow.dart';

/// Modal simple y épico que solo muestra la insignia con efectos
class SimpleInsigniaModal extends StatefulWidget {
  final EstacionVisitada estacion;

  const SimpleInsigniaModal({
    super.key,
    required this.estacion,
  });

  @override
  State<SimpleInsigniaModal> createState() => _SimpleInsigniaModalState();
}

class _SimpleInsigniaModalState extends State<SimpleInsigniaModal>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _showGlow = false;

  // Variables para la rotación 3D
  double _rotationX = 0.0; // Rotación vertical (arriba/abajo)
  double _rotationY = 0.0; // Rotación horizontal (izquierda/derecha)

  @override
  void initState() {
    super.initState();

    // Vibración háptica al abrir
    HapticFeedback.mediumImpact();

    // Animación de escala
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Animación de fade
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Controller para animaciones de rotación suave
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _startAnimations();
  }

  void _startAnimations() async {
    // Fade in
    _fadeController.forward();

    // Pausa
    await Future.delayed(const Duration(milliseconds: 300));

    // Zoom in
    _scaleController.forward();

    // Activar glow
    setState(() => _showGlow = true);
  }

  void _closeModal() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  /// Animación para volver la insignia al centro suavemente
  void _returnToCenter() {
    final startX = _rotationX;
    final startY = _rotationY;

    final animationX = Tween<double>(
      begin: startX,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    final animationY = Tween<double>(
      begin: startY,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeOut,
    ));

    _rotationController.addListener(() {
      setState(() {
        _rotationX = animationX.value;
        _rotationY = animationY.value;
      });
    });

    _rotationController.reset();
    _rotationController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black87,
        child: Stack(
          children: [
            // Área táctil para cerrar
            GestureDetector(
              onTap: _closeModal,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
              ),
            ),

            // La insignia en el centro con rotación 3D
            Center(
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    // Convertir movimiento del dedo a rotación 3D
                    _rotationY +=
                        details.delta.dx * 0.01; // Sensibilidad horizontal
                    _rotationX -= details.delta.dy *
                        0.01; // Sensibilidad vertical (invertida)

                    // Limitar rotación para que no se vea muy extrema
                    _rotationX = _rotationX.clamp(-0.5, 0.5);
                    _rotationY = _rotationY.clamp(-0.5, 0.5);
                  });
                },
                onPanEnd: (details) {
                  // Vibración ligera al soltar
                  HapticFeedback.lightImpact();

                  // Animación de retorno suave a la posición original
                  _returnToCenter();
                },
                child: AnimatedBuilder(
                  animation:
                      Listenable.merge([_scaleAnimation, _fadeAnimation]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspectiva 3D
                          ..rotateX(_rotationX) // Rotación vertical
                          ..rotateY(_rotationY) // Rotación horizontal
                          ..multiply(Matrix4.diagonal3Values(
                              _scaleAnimation.value,
                              _scaleAnimation.value,
                              _scaleAnimation.value)),
                        child: GoldenGlow(
                          isActive: _showGlow,
                          intensity: 2.0,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFFD700),
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withAlpha((0.5 * 255).round()),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFFD700)
                                      .withAlpha((0.3 * 255).round()),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: widget.estacion.badgeImage != null
                                  ? Image(
                                      image: widget.estacion.badgeImage!
                                          .imageProvider(),
                                      fit: BoxFit.cover,
                                      width: 250,
                                      height: 250,
                                    )
                                  : Container(
                                      color: const Color(0xFF1A472A),
                                      child: const Icon(
                                        Icons.location_on,
                                        size: 100,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
