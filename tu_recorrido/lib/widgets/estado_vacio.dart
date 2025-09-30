import 'package:flutter/material.dart';
import '../utils/colores.dart';

/// Widget reutilizable
/// Se puede usar en diferentes vistas
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final String? textoBoton;
  final String? rutaBoton;
  final VoidCallback? onBotonPresionado;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    this.textoBoton,
    this.rutaBoton,
    this.onBotonPresionado,
  });

  /// Constructor específico para colección vacía
  const EstadoVacio.coleccionVacia({
    super.key,
    this.rutaBoton = '/menu',
    this.onBotonPresionado,
  }) : icono = Icons.explore_off,
        titulo = 'Aún no has visitado ninguna estación',
        descripcion = 'Ve al mapa y busca estaciones patrimoniales cerca de ti. ¡Escanea los códigos QR para agregarlas a tu colección!',
        textoBoton = 'Ir al Mapa';

  /// Constructor para lista vacía 
  const EstadoVacio.listaVacia({
    super.key,
    required this.titulo,
    required this.descripcion,
    this.icono = Icons.inbox_outlined,
    this.textoBoton,
    this.rutaBoton,
    this.onBotonPresionado,
  });

  /// Constructor para búsqueda sin resultados
  const EstadoVacio.sinResultados({
    super.key,
    this.titulo = 'No se encontraron resultados',
    this.descripcion = 'Intenta con otros términos de búsqueda',
    this.icono = Icons.search_off,
    this.textoBoton,
    this.rutaBoton,
    this.onBotonPresionado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Coloressito.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            icono,
            size: 64,
            color: Coloressito.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Coloressito.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Coloressito.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (textoBoton != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBotonPresionado ?? (rutaBoton != null 
                  ? () => Navigator.of(context).pushReplacementNamed(rutaBoton!)
                  : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: Coloressito.adventureGreen,
                foregroundColor: Coloressito.textPrimary,
              ),
              child: Text(textoBoton!),
            ),
          ],
        ],
      ),
    );
  }
}