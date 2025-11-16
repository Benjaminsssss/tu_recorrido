import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/place.dart';

class PlaceSearchBar extends StatefulWidget {
  final List<Place> allPlaces;
  final Function(Place?) onPlaceSelected;
  final Function(String)?
      onSearchChanged; // Callback para filtrado en tiempo real

  const PlaceSearchBar({
    super.key,
    required this.allPlaces,
    required this.onPlaceSelected,
    this.onSearchChanged,
  });

  @override
  State<PlaceSearchBar> createState() => _PlaceSearchBarState();
}

class _PlaceSearchBarState extends State<PlaceSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Place> _filteredPlaces = [];
  bool _showSuggestions = false;
  final List<Place> _recentPlaces = [];
  Timer? _debounce;
  static const int _debounceMs = 250;
  VoidCallback? _focusListener;
  bool _isFocused = false;

  @override
  void dispose() {
    _debounce?.cancel();
    if (_focusListener != null) {
      _focusNode.removeListener(_focusListener!);
    }
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusListener = () {
      _isFocused = _focusNode.hasFocus;
      if (_focusNode.hasFocus) {
        // Si el campo está vacío, mostrar recientes (si hay)
        if (_searchController.text.isEmpty) {
          setState(() {
            _showSuggestions = _recentPlaces.isNotEmpty;
          });
        }
      } else {
        setState(() {
          _showSuggestions = false;
        });
      }
    };
    _focusNode.addListener(_focusListener!);
  }

  void _filterPlaces(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPlaces = [];
        // Si está vacío, no filtramos; la visibilidad la maneja el foco/recientes
        _showSuggestions = _focusNode.hasFocus && _recentPlaces.isNotEmpty;
      });
      // Notificar que se limpió la búsqueda - mostrar todos los lugares
      widget.onSearchChanged?.call('');
      return;
    }

    setState(() {
      _filteredPlaces = widget.allPlaces
          .where((place) =>
              place.nombre.toLowerCase().contains(query.toLowerCase()) ||
              place.comuna.toLowerCase().contains(query.toLowerCase()) ||
              place.region.toLowerCase().contains(query.toLowerCase()))
          .toList();
      _showSuggestions = _filteredPlaces.isNotEmpty;
    });

    // Notificar el filtrado en tiempo real
    widget.onSearchChanged?.call(query);
  }

  void _selectPlace(Place place) {
    _searchController.text = place.nombre;
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
    // Registrar en recientes (evitar duplicados por nombre+comuna)
    final key = '${place.nombre.toLowerCase()}|${place.comuna.toLowerCase()}';
    _recentPlaces.removeWhere(
        (p) => '${p.nombre.toLowerCase()}|${p.comuna.toLowerCase()}' == key);
    _recentPlaces.insert(0, place);
    // Limitar tamaño del historial
    if (_recentPlaces.length > 6) {
      _recentPlaces.removeRange(6, _recentPlaces.length);
    }
    widget.onPlaceSelected(place);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredPlaces = [];
      _showSuggestions = _focusNode.hasFocus && _recentPlaces.isNotEmpty;
    });
    _focusNode.unfocus();
    widget.onPlaceSelected(null); // Mostrar todos
    widget.onSearchChanged?.call(''); // Notificar que se limpió la búsqueda
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Barra de búsqueda clara tipo pill con borde suave
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _isFocused
                  ? const Color(0xFFC88400)
                  : const Color(0xFFE8EAE4), // mostaza al focus, neutro normal
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000), // elevation 1 sutil
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: Color(0xFF4E5338), // oliva oscuro
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: (value) {
                    setState(() {});
                    _debounce?.cancel();
                    _debounce =
                        Timer(const Duration(milliseconds: _debounceMs), () {
                      _filterPlaces(value);
                    });
                    if (value.isEmpty) {
                      setState(() {
                        _showSuggestions =
                            _focusNode.hasFocus && _recentPlaces.isNotEmpty;
                      });
                    }
                  },
                  onSubmitted: (value) {
                    // Al presionar Enter, cerrar dropdown y mantener el filtro actual
                    setState(() => _showSuggestions = false);
                    _focusNode.unfocus();
                    // El filtro ya está aplicado por onSearchChanged
                  },
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Buscar lugares...',
                    hintStyle: TextStyle(
                      color: Color(0xB81A1A1A), // #1A1A1A @ 72%
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: _clearSearch,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0x146A756E), // mutedText @ 8%
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF6A756E),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Sugerencias dropdown - posicionado absolutamente
        if (_showSuggestions)
          Positioned(
            top: 56, // Altura de la barra de búsqueda (48) + margen (8)
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF), // surface
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8EAE4), // neutro cálido
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000), // elevation 2
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Builder(
                  builder: (context) {
                    final List<Place> suggestions =
                        _searchController.text.isEmpty
                            ? _recentPlaces
                            : _filteredPlaces;
                    if (suggestions.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: Color(0xFFE8EAE4), // neutro cálido
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final place = suggestions[index];
                        return InkWell(
                          onTap: () => _selectPlace(place),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                  color: Color(0xFF2F6B5F), // supportGreen
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        place.nombre,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A), // onSurface
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${place.region}, ${place.comuna}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6A756E), // mutedText
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Color(0xFF6A756E), // mutedText
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
