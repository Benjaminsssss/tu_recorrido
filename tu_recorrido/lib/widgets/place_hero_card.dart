import 'package:flutter/material.dart';
import '../models/place.dart';
import 'image_carousel.dart';
import 'place_modal.dart';

class PlaceHeroCard extends StatelessWidget {
  final Place place;
  const PlaceHeroCard({super.key, required this.place});

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
            child: ImageCarousel(images: place.imagenes),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila título + sello circular placeholder
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
                    const SizedBox(width: 10),
                    // Espacio reservado para sello circular (placeholder)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE7EAE4), // outline suave
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.verified,
                        size: 22,
                        color: Color(0xFF6A756E), // mutedText
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
                        place.comuna,
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
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
