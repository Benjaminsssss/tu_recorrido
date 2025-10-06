import 'package:flutter/material.dart';
import '../utils/colores.dart';
import '../models/estacion.dart';

/// Widget para el marco de escaneo QR con animación
class MarcoEscaneo extends StatelessWidget {
  final bool escaneando;
  final Animation<double> pulseAnimation;

  const MarcoEscaneo({
    super.key,
    required this.escaneando,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(
          color: escaneando
              ? Coloressito.adventureGreen
              : Coloressito.borderLight,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Esquinas del marco
          ..._buildEsquinas(),

          // Icono central con animación
          if (escaneando)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: pulseAnimation.value,
                  child: Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Coloressito.adventureGreen,
                  ),
                );
              },
            )
          else
            Icon(Icons.qr_code_2, size: 80, color: Coloressito.textMuted),
        ],
      ),
    );
  }

  List<Widget> _buildEsquinas() {
    return [
      _buildEsquina(top: 8, left: 8, isTopLeft: true),
      _buildEsquina(top: 8, right: 8, isTopRight: true),
      _buildEsquina(bottom: 8, left: 8, isBottomLeft: true),
      _buildEsquina(bottom: 8, right: 8, isBottomRight: true),
    ];
  }

  Widget _buildEsquina({
    double? top,
    double? left,
    double? bottom,
    double? right,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    BorderSide borderSide = BorderSide(
      color: Coloressito.adventureGreen,
      width: 3,
    );

    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: (isTopLeft || isTopRight) ? borderSide : BorderSide.none,
            left: (isTopLeft || isBottomLeft) ? borderSide : BorderSide.none,
            bottom: (isBottomLeft || isBottomRight)
                ? borderSide
                : BorderSide.none,
            right: (isTopRight || isBottomRight) ? borderSide : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Widget para el texto instructivo del escáner
class TextoInstructivo extends StatelessWidget {
  final bool escaneando;
  final bool validando;

  const TextoInstructivo({
    super.key,
    required this.escaneando,
    required this.validando,
  });

  @override
  Widget build(BuildContext context) {
    String texto;
    Color color;

    if (escaneando) {
      texto = 'Escaneando código QR...';
      color = Coloressito.adventureGreen;
    } else if (validando) {
      texto = 'Validando código...';
      color = Coloressito.textSecondary;
    } else {
      texto = 'Apunta la cámara al código QR\nde la estación patrimonial';
      color = Coloressito.textSecondary;
    }

    return Text(
      texto,
      textAlign: TextAlign.center,
      style: TextStyle(color: color, fontSize: 16, height: 1.4),
    );
  }
}

/// Widget para el botón de escaneo con estados
class BotonEscaneo extends StatelessWidget {
  final bool escaneando;
  final bool validando;
  final VoidCallback? onPressed;

  const BotonEscaneo({
    super.key,
    required this.escaneando,
    required this.validando,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    bool deshabilitado = escaneando || validando;

    return ElevatedButton(
      onPressed: deshabilitado ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Coloressito.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ).copyWith(backgroundColor: WidgetStateProperty.all(Colors.transparent)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          gradient: deshabilitado ? null : Coloressito.buttonGradient,
          color: deshabilitado ? Coloressito.textMuted : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: deshabilitado
              ? []
              : [
                  BoxShadow(
                    color: Coloressito.glowColor,
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deshabilitado)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Coloressito.textPrimary,
                  ),
                  strokeWidth: 2,
                ),
              )
            else
              Icon(
                Icons.qr_code_scanner,
                color: Coloressito.textPrimary,
                size: 20,
              ),
            const SizedBox(width: 8),
            Text(
              _getTextoBoton(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Coloressito.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTextoBoton() {
    if (escaneando) return 'Escaneando...';
    if (validando) return 'Validando...';
    return 'Escanear QR';
  }
}

/// Widget para mostrar la última estación visitada
class UltimaEstacionVisitada extends StatelessWidget {
  final Estacion estacion;

  const UltimaEstacionVisitada({super.key, required this.estacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Coloressito.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Coloressito.adventureGreen),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: Coloressito.adventureGreen, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Última estación visitada:',
            style: TextStyle(color: Coloressito.textSecondary, fontSize: 12),
          ),
          Text(
            estacion.nombre,
            style: const TextStyle(
              color: Coloressito.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
