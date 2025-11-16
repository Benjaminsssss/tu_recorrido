import 'package:flutter/material.dart';
import '../../models/estacion.dart';

class InsigniaModalClean extends StatefulWidget {
  final Estacion estacion;
  final VoidCallback onClose;

  const InsigniaModalClean({
    super.key,
    required this.estacion,
    required this.onClose,
  });

  @override
  State<InsigniaModalClean> createState() => _InsigniaModalCleanState();
}

class _InsigniaModalCleanState extends State<InsigniaModalClean>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withAlpha((0.8 * 255).round()),
      body: GestureDetector(
        onTap: _closeModal,
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: GestureDetector(
                    onTap:
                        () {}, // Evita que se cierre cuando tocas la insignia
                    child: _buildInsigniaCard(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInsigniaCard() {
    return Container(
      width: 320,
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
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
              '🏆 ¡INSIGNIA DESBLOQUEADA!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Insignia
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: widget.estacion.imagenes.isNotEmpty
                  ? Image.network(
                      widget.estacion.imagenes.first['url'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.green,
                        child: const Icon(
                          Icons.location_on,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.green,
                      child: const Icon(
                        Icons.location_on,
                        size: 60,
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
              color: Colors.black87,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // Mensaje
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xFFFFD700).withAlpha((0.3 * 255).round()),
                width: 1,
              ),
            ),
            child: const Text(
              '¡Felicitaciones! Has completado esta parada de tu recorrido por Santiago',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Botón de continuar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _closeModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              child: const Text(
                '✨ Continuar Aventura ✨',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
