import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/place.dart';
import '../widgets/place_modal.dart';
import '../services/saved_places_notifier.dart';
import 'album.dart';
import '../components/bottom_nav_bar.dart';

/// Nuevo Home: buscador, avatar, lista/carrusel de lugares y barra inferior.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _currentIndex = 0; // 0: Inicio, 1: Colección, 2: Mapa

  // Filtros
  String? _selectedCountry;
  String? _selectedCity;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedCountry = null;
      _selectedCity = null;
    });
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

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        initialCountry: _selectedCountry,
        initialCity: _selectedCity,
        onApply: (country, city) {
          setState(() {
            _selectedCountry = country;
            _selectedCity = city;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Botón de filtro - IZQUIERDA
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showFilterSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color:
                            (_selectedCountry != null || _selectedCity != null)
                                ? const Color(0xFF156A79)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color:
                            (_selectedCountry != null || _selectedCity != null)
                                ? Colors.white
                                : const Color(0xFF156A79),
                        size: 24,
                      ),
                    ),
                  ),
                ),
                // Buscador
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Busca aqui',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Avatar / Perfil
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/perfil'),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.colorScheme.primary),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chips de filtros activos
          if (_selectedCountry != null || _selectedCity != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(
                      _selectedCity != null
                          ? '$_selectedCountry - $_selectedCity'
                          : _selectedCountry!,
                      style: const TextStyle(fontSize: 13),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: _clearFilters,
                    backgroundColor: Colors.blue.shade50,
                    deleteIconColor: Colors.blue.shade700,
                  ),
                ],
              ),
            ),
          // Lista de lugares
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreService.instance.watchEstaciones(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final all = snap.data?.docs ?? [];

                // DEBUG: listar ids y campos claves para diagnosticar por qué
                // una estación creada no aparece en el scroll.
                try {
                  debugPrint('Home: snapshot total=${all.length} docs');
                  for (final doc in all) {
                    final d = doc.data();
                    final id = doc.id;
                    final nombre = d['nombre'] ?? d['name'];
                    final createdAt = d['createdAt'] ?? d['fechaCreacion'];
                    final lat = d['lat'] ?? d['latitud'];
                    final lng = d['lng'] ?? d['longitud'];
                    debugPrint(
                        '  doc: $id  nombre=$nombre  createdAt=$createdAt  lat=$lat  lng=$lng');
                  }
                } catch (e) {
                  debugPrint('Home: error debug print snapshot: $e');
                }

                // Aplicar filtros
                var filtered = all;

                // Filtro por país (compatibilidad: country, region, pais)
                if (_selectedCountry != null) {
                  filtered = filtered.where((d) {
                    final data = d.data();
                    final country =
                        (data['country'] ?? data['region'] ?? data['pais'])
                            ?.toString();
                    return country == _selectedCountry;
                  }).toList();
                }

                // Filtro por ciudad/comuna (compatibilidad: city, comuna)
                if (_selectedCity != null) {
                  filtered = filtered.where((d) {
                    final data = d.data();
                    final city = (data['city'] ?? data['comuna'])?.toString();
                    return city == _selectedCity;
                  }).toList();
                }

                // Filtro por texto de búsqueda
                final q = _searchCtrl.text.trim().toLowerCase();
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

                // Lista principal: renderizamos los documentos filtrados como cards.
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final doc = filtered[i];
                    final d = doc.data();

                    // Convertir documento Firestore a Place (view-model)
                    final place = _convertToPlace(doc);

                    // Usar los valores ya normalizados en el view-model para evitar
                    // discrepancias entre 'd' y 'place' (nombre/descripcion vacíos)
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
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
                            debugPrint('Error al convertir lugar: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Error al cargar detalles de "$name"'),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onChanged: (idx) {
          if (idx == 2) {
            // ir a Mapa (manteniendo el estado del Home en el stack)
            Navigator.pushNamed(context, '/menu');
          } else if (idx == 1) {
            // abrir Colección (Album)
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AlbumScreen()));
          } else {
            setState(() => _currentIndex = idx);
          }
        },
      ),
    );
  }
}

class _PlaceCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onDetails;
  final Place place;

  const _PlaceCard({
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.onDetails,
    required this.place,
  });

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  bool _isSaved = false;
  bool _isLoading = false;
  final _notifier = SavedPlacesNotifier();
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _notifier.addListener(_onSavedPlacesChanged);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _notifier.removeListener(_onSavedPlacesChanged);
    try {
      _pageController.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _onSavedPlacesChanged() {
    // Re-verificar si el lugar está guardado cuando hay cambios
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_places')
          .doc(widget.place.id)
          .get();

      if (mounted) {
        setState(() {
          _isSaved = doc.exists;
        });
      }
    } catch (e) {
      debugPrint('Error checking if place is saved: $e');
    }
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Debes iniciar sesión para guardar lugares')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_places')
          .doc(widget.place.id);

      if (_isSaved) {
        await docRef.delete();
        if (mounted) {
          setState(() => _isSaved = false);
          // Notificar que el lugar fue eliminado
          _notifier.notifyPlaceChanged(widget.place.id, false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${widget.place.nombre} eliminado de guardados')),
          );
        }
      } else {
        await docRef.set({
          'placeId': widget.place.id,
          'nombre': widget.place.nombre,
          'comuna': widget.place.comuna,
          'region': widget.place.region,
          'shortDesc': widget.place.shortDesc,
          'descripcion': widget.place.descripcion,
          'mejorMomento': widget.place.mejorMomento,
          'tema': widget.place.badge.tema,
          'badge': widget.place.badge.nombre,
          'imageUrl': widget.place.imagenes.isNotEmpty
              ? widget.place.imagenes[0].url
              : null,
          'lat': widget.place.lat,
          'lng': widget.place.lng,
          'saved_at': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() => _isSaved = true);
          // Notificar que el lugar fue guardado
          _notifier.notifyPlaceChanged(widget.place.id, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${widget.place.nombre} guardado')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar el lugar')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Muestra un visor a pantalla completa que permite deslizar entre imágenes y hacer zoom.
  void _showImageViewer(BuildContext context, List<PlaceImage> images,
      {int initialIndex = 0}) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) =>
          _FullScreenImageViewer(images: images, initialIndex: initialIndex),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen superior con botón de guardar
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: widget.place.imagenes.isNotEmpty
                        ? Stack(
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: widget.place.imagenes.length,
                                onPageChanged: (p) =>
                                    setState(() => _currentPage = p),
                                itemBuilder: (context, idx) {
                                  final img = widget.place.imagenes[idx];
                                  final provider = img.imageProvider();
                                  return GestureDetector(
                                    onTap: () => _showImageViewer(
                                        context, widget.place.imagenes,
                                        initialIndex: idx),
                                    child: Image(
                                      image: provider,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFF0F0F0),
                                        child: const Center(
                                          child: Icon(Icons.image_not_supported,
                                              size: 48, color: Colors.black38),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (widget.place.imagenes.length > 1)
                                Positioned(
                                  bottom: 8,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                        widget.place.imagenes.length, (i) {
                                      final active = i == _currentPage;
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        width: active ? 10 : 6,
                                        height: active ? 10 : 6,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? Colors.white
                                              : Colors.white54,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          )
                        : Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Center(
                              child: Icon(Icons.image,
                                  size: 48, color: Colors.black38),
                            ),
                          ),
                  ),
                ),
                // Botón de guardar en la esquina superior derecha
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _isLoading ? null : _toggleSave,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Icon(
                                _isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: _isSaved
                                    ? const Color(0xFFC88400)
                                    : Colors.black54,
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                ),
                // (badge overlay removed per UX request) top-left area reserved for admin images only
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color:
                          Color(0xFFB57A00), // similar al dorado de la maqueta
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place,
                            size: 16, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text(widget.subtitle!,
                            style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: widget.onDetails,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Ver detalles'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDAA520),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Replaced the local private BottomNav with the reusable `BottomNavBar`

class _FullScreenImageViewer extends StatefulWidget {
  final List<PlaceImage> images;
  final int initialIndex;

  const _FullScreenImageViewer({required this.images, this.initialIndex = 0});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (p) => setState(() => _current = p),
              itemBuilder: (context, idx) {
                final img = widget.images[idx];
                final provider = img.imageProvider();
                return Center(
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image(
                      image: provider,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image,
                          size: 120, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Page indicator
            if (widget.images.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.images.length, (i) {
                    final active = i == _current;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 10 : 6,
                      height: active ? 10 : 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget del BottomSheet de filtros
class _FilterBottomSheet extends StatefulWidget {
  final String? initialCountry;
  final String? initialCity;
  final Function(String?, String?) onApply;

  const _FilterBottomSheet({
    this.initialCountry,
    this.initialCity,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  String? _selectedCountry;
  String? _selectedCity;

  // Lista de países y ciudades
  final Map<String, List<String>> _countriesAndCities = {
    'Chile': [
      'Santiago',
      'Valparaíso',
      'Concepción',
      'La Serena',
      'Antofagasta',
      'Temuco',
      'Viña del Mar'
    ],
    'Argentina': [
      'Buenos Aires',
      'Córdoba',
      'Rosario',
      'Mendoza',
      'La Plata',
      'Tucumán'
    ],
    'Perú': ['Lima', 'Cusco', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura'],
    'Colombia': [
      'Bogotá',
      'Medellín',
      'Cali',
      'Barranquilla',
      'Cartagena',
      'Cúcuta'
    ],
    'México': [
      'Ciudad de México',
      'Guadalajara',
      'Monterrey',
      'Puebla',
      'Tijuana',
      'Cancún'
    ],
    'Brasil': [
      'São Paulo',
      'Río de Janeiro',
      'Brasilia',
      'Salvador',
      'Fortaleza',
      'Belo Horizonte'
    ],
    'España': [
      'Madrid',
      'Barcelona',
      'Valencia',
      'Sevilla',
      'Zaragoza',
      'Málaga'
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.initialCountry;
    _selectedCity = widget.initialCity;
  }

  List<String> get _availableCities {
    if (_selectedCountry == null) return [];
    return _countriesAndCities[_selectedCountry] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtrar Lugares',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // País
            const Text(
              'País',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCountry,
                  hint: const Text('Selecciona un país'),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos los países'),
                    ),
                    ..._countriesAndCities.keys.map((country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                      // Resetear ciudad si cambia el país
                      if (_selectedCity != null &&
                          !_availableCities.contains(_selectedCity)) {
                        _selectedCity = null;
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Ciudad
            const Text(
              'Ciudad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedCountry == null
                      ? Colors.grey.shade200
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedCity,
                  hint: Text(
                    _selectedCountry == null
                        ? 'Primero selecciona un país'
                        : 'Selecciona una ciudad',
                    style: TextStyle(
                      color: _selectedCountry == null
                          ? Colors.grey.shade400
                          : Colors.black54,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  borderRadius: BorderRadius.circular(12),
                  items: _selectedCountry == null
                      ? []
                      : [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todas las ciudades'),
                          ),
                          ..._availableCities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }),
                        ],
                  onChanged: _selectedCountry == null
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedCountry = null;
                        _selectedCity = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_selectedCountry, _selectedCity);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF156A79),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Aplicar Filtros',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
