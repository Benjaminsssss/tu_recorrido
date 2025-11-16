import 'package:flutter/material.dart';
import '../../models/estacion.dart';

class InsigniaModal extends StatefulWidget {
  final Estacion estacion;
  final VoidCallback onClose;

  const InsigniaModal({
    super.key,
    required this.estacion,
    required this.onClose,
  });

  @override
  State<InsigniaModal> createState() => _InsigniaModalState();
}

class _InsigniaModalState extends State<InsigniaModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startAnimation() {
    _animationController.forward();
  }

  void _closeModal() {
    widget.onClose();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo negro con desenfoque
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeModal,
              child: Container(
                color: Colors.black.withAlpha((0.8 * 255).round()),
              ),
            ),
          ),

          // Contenido principal - exactamente como en la imagen
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildInsigniaCard(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsigniaCard() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5530), // Color verde oscuro de fondo
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD700), // Borde dorado
          width: 3,
        ),
        boxShadow: [
          // Resplandor dorado como en la imagen
          BoxShadow(
            color: const Color(0xFFFFD700).withAlpha((0.6 * 255).round()),
            blurRadius: 30,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withAlpha((0.5 * 255).round()),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'BARRO LASTARRIA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Insignia circular - exactamente como en la imagen
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700), // Borde dorado
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha((0.4 * 255).round()),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: ClipOval(
              child: widget.estacion.imagenes.isNotEmpty
                  ? Image.network(
                      widget.estacion.imagenes.first['url'] ?? '',
                      fit: BoxFit.cover,
                      width: 200,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.green,
                        child: const Icon(
                          Icons.location_on,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.green,
                      child: const Icon(
                        Icons.location_on,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),

          // Nombre de la estación
          Text(
            widget.estacion.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Ubicación
          const Text(
            'SANTIAGO • CHILE',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Botón de continuar
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: _closeModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              child: const Text(
                '✨ Continuar Aventura ✨',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
