import 'package:flutter/material.dart';
import '../../utils/colores.dart';

/// Widget para el encabezado de crear estación
class EncabezadoEstacion extends StatelessWidget {
  const EncabezadoEstacion({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Coloressito.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.location_on, size: 48, color: Coloressito.adventureGreen),
          const SizedBox(height: 8),
          const Text(
            'Nueva Estación Patrimonial',
            style: TextStyle(
              color: Coloressito.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Crea puntos de interés histórico para que los usuarios puedan visitar',
            textAlign: TextAlign.center,
            style: TextStyle(color: Coloressito.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar información de ubicación GPS
class InfoUbicacion extends StatelessWidget {
  final dynamic ubicacion;

  const InfoUbicacion({super.key, required this.ubicacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Coloressito.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Row(
        children: [
          Icon(
            ubicacion != null ? Icons.gps_fixed : Icons.gps_off,
            color: ubicacion != null
                ? Coloressito.adventureGreen
                : Coloressito.badgeRed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
        ubicacion != null
          ? 'Ubicación: ${ubicacion.latitude.toStringAsFixed(6)}, ${ubicacion.longitude.toStringAsFixed(6)}'
          : 'Obteniendo ubicación GPS...',
              style: TextStyle(
                color: ubicacion != null
                    ? Coloressito.textPrimary
                    : Coloressito.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para campos de texto del formulario
class CampoFormulario extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?) validator;
  final int maxLines;

  const CampoFormulario({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Coloressito.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Coloressito.textSecondary),
        hintText: hint,
        hintStyle: const TextStyle(color: Coloressito.textMuted),
        filled: true,
        fillColor: Coloressito.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Coloressito.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Coloressito.adventureGreen,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }
}

/// Widget para botón de acción con gradiente
class BotonAccion extends StatelessWidget {
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  const BotonAccion({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: cargando ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Coloressito.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ).copyWith(backgroundColor: WidgetStateProperty.all(Colors.transparent)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: cargando ? null : Coloressito.buttonGradient,
          color: cargando ? Coloressito.textMuted : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: cargando
              ? []
              : [
                  BoxShadow(
                    color: Coloressito.glowColor,
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: cargando
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Coloressito.textPrimary,
                  ),
                  strokeWidth: 2,
                ),
              )
            : Text(
                texto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Coloressito.textPrimary,
                ),
              ),
      ),
    );
  }
}
