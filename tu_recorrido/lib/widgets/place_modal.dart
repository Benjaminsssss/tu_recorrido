import 'package:flutter/material.dart';
import '../models/place.dart';
import 'image_carousel.dart';

class PlaceModal extends StatelessWidget {
  final Place place;

  const PlaceModal({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar para indicar que es deslizable
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carrusel de imágenes
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ImageCarousel(images: place.imagenes),
                ),

                const SizedBox(height: 20),

                // Header con título (sin botón guardar)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      place.nombre,
                      style: const TextStyle(
                        fontFamily: 'Pacifico',
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Color(0xFFC88400), // mostaza
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Ubicación
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF66B7F0), // celeste
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            place.comuna,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF7B8063), // oliva
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Badge/Tema
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7EAE4), // fondo suave
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF1A4D5C).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: Color(0xFFC88400),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        place.badge.tema,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A4D5C),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Descripción corta
                if (place.shortDesc.isNotEmpty) ...[
                  Text(
                    place.shortDesc,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF4B5563),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Descripción completa
                const Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A4D5C),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.descripcion,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF4B5563),
                  ),
                ),

                const SizedBox(height: 20),

                // Mejor momento para visitar
                if (place.mejorMomento.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6), // amarillo suave
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC88400).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.wb_sunny_outlined,
                          color: Color(0xFFC88400),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mejor momento para visitar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A4D5C),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                place.mejorMomento,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Botón de cerrar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3E4C3A), // oliva oscuro
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ], // fin de children del Column interno
            ), // fin del Column interno
          ), // fin del SingleChildScrollView
        ), // fin del Expanded
      ], // fin de children del Column externo
    ); // fin del Column externo
  }
}
