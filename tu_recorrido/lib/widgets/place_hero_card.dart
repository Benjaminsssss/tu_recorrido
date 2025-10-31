import 'package:flutter/material.dart';
import '../models/place.dart';
import 'image_carousel.dart';
import 'place_modal.dart';

class PlaceHeroCard extends StatelessWidget {
  final Place place;
  const PlaceHeroCard({super.key, required this.place});

  // Selección temporal de sello por tema; si no existe el asset, cae al fallback (insignia).
  String _stampForPlace(Place p) {
    const mapping = {
      'Historia': 'assets/img/sellos/sello1.png',
      'Arte': 'assets/img/sellos/sello2.png',
      'Naturaleza': 'assets/img/sellos/sello3.png',
      'Arquitectura': 'assets/img/sellos/sello4.png',
      'Cultura': 'assets/img/sellos/sello5.png',
    };
    return mapping[p.badge.tema] ?? 'assets/img/sellos/sello1.png';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2, // elevation sutil
      borderRadius: BorderRadius.circular(16),
      color: const Color(0xFFFFFFFF), // surface blanco
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                ImageCarousel(images: place.imagenes),
                // Sello grande, visible y superpuesto en la imagen
                Positioned(
                  top: 10,
                  right: 10,
                  child: _StampCircle(
                    assetPath: _stampForPlace(place),
                    size: 64, // más grande para que se vea mejor
                    contentScale:
                        1.2, // zoom para compensar márgenes transparentes
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila título (el sello ahora va sobre la imagen)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título en miel/mostaza
                    Expanded(
                      child: Text(
                        place.nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Pacifico',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                          color: Color(0xFFC88400), // miel/mostaza
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Fila ubicación
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF66B7F0), // celeste
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        // Mostrar región + comuna (dirección breve). Si falta alguno, mostrar lo disponible.
                        ( (place.region.isNotEmpty ? place.region : '') +
                          (place.region.isNotEmpty && place.comuna.isNotEmpty ? ', ' : '') +
                          (place.comuna.isNotEmpty ? place.comuna : (place.shortDesc.isNotEmpty ? place.shortDesc : 'Sin ubicación'))
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7B8063), // oliva grisado
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOut,
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: FractionallySizedBox(
                              heightFactor: 0.92,
                              child: Material(
                                color: Colors.white,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(32)),
                                child: PlaceModal(place: place),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFE0A013), // miel claro arriba
                            Color(0xFFC88400), // mostaza abajo
                          ],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33C88400), // mostaza @ 20%
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ver detalles',
                            style: TextStyle(
                              color: Color(0xFF0F1411), // casi negro
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF0F1411), // casi negro
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StampCircle extends StatelessWidget {
  final String assetPath;
  final double size;
  final double
      contentScale; // permite hacer zoom a la imagen para alinearla al borde
  const _StampCircle(
      {required this.assetPath, this.size = 36, this.contentScale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE7EAE4), // fondo por si falla la imagen
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFF1A4D5C), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Transform.scale(
          scale: contentScale,
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) {
              // Fallback: usa la insignia existente si no hay asset
              return Transform.scale(
                scale: contentScale,
                child: Image.asset(
                  'assets/img/insiginia.png',
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
