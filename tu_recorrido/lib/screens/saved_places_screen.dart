import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place.dart';
import 'package:tu_recorrido/widgets/modales/place_modal.dart';
import 'package:tu_recorrido/services/saved/saved_places_notifier.dart';

class SavedPlacesScreen extends StatelessWidget {
  const SavedPlacesScreen({super.key});

  // Paleta solicitada
  static const Color oliveDark = Color(0xFF3E4C3A); // verde oliva muy oscuro
  static const Color militaryBrown = Color(0xFF6B5B3E); // marrón militar
  static const Color terracotta = Color(0xFFB3502D); // rojo óxido / terracota
  static const Color honeyGold = Color(0xFFC88400); // mostaza/miel dorado
  static const Color skyBlue = Color(0xFF66B7F0); // celeste claro / azul cielo

  String _formatLocation(Place p) {
    final parts = <String>[];
    if (p.comuna.isNotEmpty) parts.add(p.comuna);
    if (p.region.isNotEmpty) parts.add(p.region);
    return parts.join(', ');
  }

  Future<void> _deletePlace(BuildContext context, String placeId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_places')
          .doc(placeId)
          .delete();

      // Notificar que el lugar fue eliminado
      SavedPlacesNotifier().notifyPlaceChanged(placeId, false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lugar eliminado de guardados'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PlaceModal(place: place),
    );
  }

  Place _convertToPlace(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convertir imageUrl a lista de PlaceImage
    final imageUrl = data['imageUrl']?.toString();
    final images = <PlaceImage>[];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      images.add(PlaceImage(
        url: imageUrl,
        alt: data['nombre']?.toString() ?? 'Imagen del lugar',
      ));
    }

    // Si no hay imagen, usar una por defecto
    if (images.isEmpty) {
      images.add(PlaceImage(
        url: null,
        alt: 'Sin imagen',
      ));
    }

    return Place(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      region: data['region'] ?? '',
      comuna: data['comuna'] ?? '',
      shortDesc: data['shortDesc'] ?? '',
      descripcion: data['descripcion'] ?? 'Sin descripción disponible.',
      mejorMomento: data['mejorMomento'] ?? 'Todo el año',
      badge: PlaceBadge(
        nombre: data['badge']?.toString() ?? 'General',
        tema: data['tema']?.toString() ?? 'Cultura',
      ),
      imagenes: images,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lugares Guardados'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Debes iniciar sesión para ver tus lugares guardados'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F2),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Lugares Guardados',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ).copyWith(color: oliveDark),
        ),
        backgroundColor: Colors.white,
        foregroundColor: oliveDark,
        elevation: 0,
        iconTheme: IconThemeData(color: oliveDark),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_places')
            // Sin orderBy para soportar documentos antiguos con distintos campos
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Copia mutable para ordenar localmente por saved_at o savedAt (desc)
          final List<QueryDocumentSnapshot> docs =
              List<QueryDocumentSnapshot>.from(snapshot.data?.docs ?? []);

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTs = (aData['saved_at'] ?? aData['savedAt']);
            final bTs = (bData['saved_at'] ?? bData['savedAt']);
            DateTime aDate;
            DateTime bDate;
            if (aTs is Timestamp) {
              aDate = aTs.toDate();
            } else if (aTs is DateTime) {
              aDate = aTs;
            } else {
              aDate = DateTime.fromMillisecondsSinceEpoch(0);
            }
            if (bTs is Timestamp) {
              bDate = bTs.toDate();
            } else if (bTs is DateTime) {
              bDate = bTs;
            } else {
              bDate = DateTime.fromMillisecondsSinceEpoch(0);
            }
            return bDate.compareTo(aDate); // Descendente
          });

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes lugares guardados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explora lugares y guarda tus favoritos tocando el icono\nde bookmark',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Explorar lugares'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B6B7F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final place = _convertToPlace(doc);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: oliveDark.withValues(alpha: 0.08)),
                ),
                child: InkWell(
                  onTap: () => _showPlaceDetails(context, place),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagen
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: place.imagenes.isNotEmpty &&
                                  place.imagenes[0].url != null
                              ? Image.network(
                                  place.imagenes[0].url!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: const Color(0xFFE9ECE3),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: militaryBrown,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9ECE3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.place,
                                    color: militaryBrown,
                                    size: 40,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        // Información
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.nombre.isEmpty
                                    ? 'Sin nombre'
                                    : place.nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: oliveDark,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: militaryBrown,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _formatLocation(place),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getBadgeColor(place.badge.tema),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  place.badge.tema,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botón eliminar
                        IconButton(
                          icon: const Icon(Icons.bookmark_rounded),
                          color: honeyGold,
                          onPressed: () => _deletePlace(context, place.id),
                          tooltip: 'Eliminar de guardados',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getBadgeColor(String tema) {
    switch (tema.toLowerCase()) {
      case 'cultura':
        return skyBlue; // azul cielo
      case 'naturaleza':
        return oliveDark; // oliva
      case 'aventura':
        return terracotta; // terracota
      case 'historia':
        return militaryBrown; // marrón militar
      case 'gastronomía':
      case 'gastronomia':
        return honeyGold; // miel dorado
      case 'playa':
        return skyBlue; // azul cielo
      default:
        return Colors.grey;
    }
  }
}
