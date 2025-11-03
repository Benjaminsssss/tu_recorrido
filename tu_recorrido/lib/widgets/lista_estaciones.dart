import 'package:flutter/material.dart';
import '../models/estacion_visitada.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/colores.dart';

/// Widget reutilizable para mostrar lista de estaciones visitadas
/// Puede usarse en colección, historial, búsquedas, etc.
class ListaEstaciones extends StatelessWidget {
  final List<EstacionVisitada> estaciones;
  final bool mostrarCodigo;
  final bool mostrarFecha;
  final bool mostrarCheck;
  final Function(EstacionVisitada)? onTap;

  const ListaEstaciones({
    super.key,
    required this.estaciones,
    this.mostrarCodigo = true,
    this.mostrarFecha = true,
    this.mostrarCheck = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: estaciones.length,
      itemBuilder: (context, index) {
        final estacion = estaciones[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Coloressito.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Coloressito.borderLight),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            onTap: onTap != null ? () => onTap!(estacion) : null,
            leading: estacion.badgeImage != null
                ? (estacion.badgeImage!.url != null && estacion.badgeImage!.url!.isNotEmpty
                    ? CircleAvatar(
                        radius: 25,
                        backgroundColor: Coloressito.surfaceDark,
                        backgroundImage: estacion.badgeImage!.imageProvider(),
                      )
                    : (estacion.badgeImage!.path != null && estacion.badgeImage!.path!.isNotEmpty
                        ? FutureBuilder<String>(
                            future: FirebaseStorage.instance
                                .ref(estacion.badgeImage!.path)
                                .getDownloadURL(),
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    gradient: Coloressito.buttonGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const SizedBox.shrink(),
                                );
                              }
                              if (snap.hasError || !snap.hasData) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    gradient: Coloressito.buttonGradient,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Coloressito.textPrimary,
                                    size: 24,
                                  ),
                                );
                              }

                              return CircleAvatar(
                                radius: 25,
                                backgroundColor: Coloressito.surfaceDark,
                                backgroundImage: NetworkImage(snap.data!),
                              );
                            },
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              gradient: Coloressito.buttonGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Coloressito.textPrimary,
                              size: 24,
                            ),
                          )))
                : Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      gradient: Coloressito.buttonGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Coloressito.textPrimary,
                      size: 24,
                    ),
                  ),
            title: Text(
              estacion.estacionNombre,
              style: const TextStyle(
                color: Coloressito.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (mostrarCodigo)
                  Text(
                    'Código: ${estacion.estacionCodigo}',
                    style: const TextStyle(
                      color: Coloressito.textMuted,
                      fontSize: 12,
                    ),
                  ),
                if (mostrarCodigo && mostrarFecha) const SizedBox(height: 2),
                if (mostrarFecha)
                  Text(
                    'Visitada: ${_formatearFecha(estacion.fechaVisita)}',
                    style: const TextStyle(
                      color: Coloressito.textSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: mostrarCheck
                ? const Icon(
                    Icons.check_circle,
                    color: Coloressito.adventureGreen,
                    size: 28,
                  )
                : null,
          ),
        );
      },
    );
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final difference = now.difference(fecha);

    if (difference.inDays == 0) {
      return 'Hoy ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }
}
