import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tu_recorrido/services/infra/firestore_service.dart';
import '../models/place.dart';
import 'package:tu_recorrido/widgets/modales/place_modal.dart';
import 'package:tu_recorrido/widgets/carousels/follow_suggestions_carousel.dart';

/// Tab "Explorar" - Muestra lugares para descubrir (código del home original)
class ExploreTab extends StatefulWidget {
  final TextEditingController searchController;
  final String? selectedCountry;
  final String? selectedCity;

  const ExploreTab({
    super.key,
    required this.searchController,
    this.selectedCountry,
    this.selectedCity,
  });

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  // Número aleatorio para definir en qué posición aparecerá el carrusel de sugerencias
  late int _suggestionPosition;
  
  @override
  void initState() {
    super.initState();
    // TEMPORAL: Posición fija en 2 para pruebas (luego volver a aleatorio)
    _suggestionPosition = 2;
    debugPrint('🎯 ExploreTab: Carrusel aparecerá en posición $_suggestionPosition');
  }
  
  /// Calcula el número total de items incluyendo el carrusel de sugerencias
  int _calculateItemCount(int placesCount) {
    // Si hay suficientes lugares, agregar 1 item para el carrusel
    if (placesCount > _suggestionPosition) {
      return placesCount + 1;
    }
    return placesCount;
  }
  
  /// Convierte un documento de Firestore al modelo Place
  Place _convertToPlace(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();

    // Preferir la lista 'imagenes' si existe (admin uploads)
    final images = <PlaceImage>[];
    final imgsRaw = d['imagenes'] as List<dynamic>?;
    if (imgsRaw != null && imgsRaw.isNotEmpty) {
      try {
        for (final e in imgsRaw) {
          if (e is Map<String, dynamic>) {
            images.add(PlaceImage.fromJson(e));
          } else if (e is Map) {
            images.add(PlaceImage.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      } catch (_) {}
    }

    // Fallback a imageUrl (legacy) si no hay 'imagenes'
    if (images.isEmpty) {
      final imageUrl = d['imageUrl']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(PlaceImage(
            url: imageUrl, alt: d['name']?.toString() ?? 'Imagen del lugar'));
      }
    }

    // Si no hay imagen, usar una por defecto
    if (images.isEmpty) {
      images.add(PlaceImage(url: null, alt: 'Sin imagen'));
    }

    return Place(
      id: doc.id,
      nombre: d['nombre']?.toString() ?? d['name']?.toString() ?? 'Sin nombre',
      region: d['country']?.toString() ?? d['region']?.toString() ?? 'Chile',
      comuna:
          d['city']?.toString() ?? d['comuna']?.toString() ?? 'Sin ubicación',
      shortDesc: d['shortDesc']?.toString() ?? d['category']?.toString() ?? '',
      descripcion: d['descripcion']?.toString() ??
          d['description']?.toString() ??
          'Sin descripción disponible.',
      mejorMomento: d['bestTime']?.toString() ??
          d['mejorMomento']?.toString() ??
          'Todo el año',
      badge: PlaceBadge(
        nombre:
            d['badge']?.toString() ?? d['category']?.toString() ?? 'General',
        tema: d['theme']?.toString() ??
            d['tema']?.toString() ??
            d['category']?.toString() ??
            'Cultura',
      ),
      imagenes: images,
      lat:
          (d['lat'] as num?)?.toDouble() ?? (d['latitude'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble() ??
          (d['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreService.instance.watchEstaciones(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final all = snap.data?.docs ?? [];

        // Aplicar filtros
        var filtered = all;

        // Filtro por país
        if (widget.selectedCountry != null) {
          filtered = filtered.where((d) {
            final data = d.data();
            final country =
                (data['country'] ?? data['region'] ?? data['pais'])
                    ?.toString();
            return country == widget.selectedCountry;
          }).toList();
        }

        // Filtro por ciudad/comuna
        if (widget.selectedCity != null) {
          filtered = filtered.where((d) {
            final data = d.data();
            final city = (data['city'] ?? data['comuna'])?.toString();
            return city == widget.selectedCity;
          }).toList();
        }

        // Filtro por texto de búsqueda
        final q = widget.searchController.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          filtered = filtered.where((d) {
            final name = (d.data()['nombre'] ?? d.data()['name'] ?? '')
                .toString()
                .toLowerCase();
            return name.contains(q);
          }).toList();
        }

        if (filtered.isEmpty) {
          return const Center(
            child: Text('No hay lugares que coincidan con los filtros'),
          );
        }

        // Construir lista con carrusel de sugerencias intercalado
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: _calculateItemCount(filtered.length),
          itemBuilder: (context, i) {
            // Si es la posición del carrusel, mostrar el widget de sugerencias
            // El widget se ocultará automáticamente si no hay sugerencias
            if (i == _suggestionPosition && filtered.length > _suggestionPosition) {
              debugPrint('🎨 Insertando FollowSuggestionsCarousel en posición $i');
              // Sin padding, el widget maneja su propio margen
              return const FollowSuggestionsCarousel();
            }
            
            // Calcular el índice real en la lista de lugares
            // Si ya pasamos el carrusel, ajustar el índice
            final placeIndex = i > _suggestionPosition ? i - 1 : i;
            
            // Verificar que no excedamos la lista
            if (placeIndex >= filtered.length) {
              return const SizedBox.shrink();
            }
            
            final doc = filtered[placeIndex];
            final d = doc.data();

            // Convertir documento Firestore a Place
            final place = _convertToPlace(doc);

            final name = place.nombre.isNotEmpty
                ? place.nombre
                : (d['nombre'] ?? d['name'] ?? '—').toString();
            final imageUrl = (place.imagenes.isNotEmpty
                    ? place.imagenes[0].url
                    : null) ??
                d['imageUrl']?.toString();

            String? subtitle;
            final city = place.comuna.isNotEmpty
                ? place.comuna
                : (d['city'] ?? d['comuna'])?.toString();
            final country = place.region.isNotEmpty
                ? place.region
                : (d['country'] ?? d['region'])?.toString();
            final category = d['category']?.toString() ?? '';

            if (city != null && country != null) {
              subtitle = '$city, $country';
            } else if (city != null) {
              subtitle = city;
            } else if (country != null) {
              subtitle = country;
            } else if (category.isNotEmpty) {
              subtitle = category;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PlaceCard(
                title: name,
                subtitle: subtitle,
                imageUrl: imageUrl,
                place: place,
                onDetails: () {
                  // Mostrar modal con detalles
                  try {
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
                  } catch (e) {
                    debugPrint('Error al mostrar modal: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al abrir detalles'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Widget de tarjeta de lugar
class _PlaceCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Place place;
  final VoidCallback onDetails;

  const _PlaceCard({
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.place,
    required this.onDetails,
  });

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carrusel de imágenes
          SizedBox(
            height: 220,
            child: widget.place.imagenes.isNotEmpty
                ? Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        physics: const PageScrollPhysics(),
                        dragStartBehavior: DragStartBehavior.down,
                        allowImplicitScrolling: true,
                        itemCount: widget.place.imagenes.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          final img = widget.place.imagenes[index];
                          final provider = img.imageProvider();
                          return GestureDetector(
                            onTap: widget.onDetails,
                            child: Image(
                              image: provider,
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 48),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Indicadores de página
                      if (widget.place.imagenes.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.place.imagenes.length,
                              (i) {
                                final active = i == _currentPage;
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  width: active ? 10 : 6,
                                  height: active ? 10 : 6,
                                  decoration: BoxDecoration(
                                    color:
                                        active ? Colors.white : Colors.white54,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  )
                : InkWell(
                    onTap: widget.onDetails,
                    child: Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.place, size: 48),
                      ),
                    ),
                  ),
          ),
          // Información
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        widget.place.badge.nombre,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor:
                          const Color(0xFF156A79).withAlpha((0.1 * 255).round()),
                      labelStyle: const TextStyle(
                        color: Color(0xFF156A79),
                        fontWeight: FontWeight.w500,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Spacer(),
                    // Botón "Ver detalles"
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFDAA520), // Amarillo mostaza
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton.icon(
                        onPressed: widget.onDetails,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text(
                          'Ver detalles',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF424242), // Gris oscuro para texto e icono
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
