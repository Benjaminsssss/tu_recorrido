import 'package:flutter/material.dart';
import 'album.dart';
import '../components/bottom_nav_bar.dart';
import 'explore_tab.dart';
import 'following_tab.dart';

/// Nuevo Home: buscador, avatar, lista/carrusel de lugares y barra inferior.
/// Ahora con TabBar: Explorar | Siguiendo
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchCtrl = TextEditingController();
  int _currentIndex = 0; // 0: Inicio, 1: Colección, 2: Mapa
  
  late TabController _tabController;

  // Filtros
  String? _selectedCountry;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Listener para ocultar buscador y filtros en tab "Siguiendo"
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedCountry = null;
      _selectedCity = null;
    });
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
    final isExploreTab = _tabController.index == 0;
    
    // Calcular altura del AppBar dinámicamente
    // Explorar: padding(24) + searchBar(48) + TabBar(48) = 120
    // Siguiendo: imagen(60) + TabBar(48) = 108
    final double appBarHeight = isExploreTab ? 120 : 108;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: SafeArea(
          child: Column(
            children: [
              // Header con búsqueda y avatar
              if (isExploreTab)
                Container(
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
                              color: (_selectedCountry != null ||
                                      _selectedCity != null)
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
                              color: (_selectedCountry != null ||
                                      _selectedCity != null)
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
                          child: Icon(Icons.person,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Header con imagen del cóndor para tab "Siguiendo"
                Stack(
                  children: [
                    // Imagen del cóndor de fondo
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/img/condorHeader.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    // Gradiente oscuro para mejorar contraste
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withAlpha((0.3 * 255).round()),
                            Colors.black.withAlpha((0.1 * 255).round()),
                          ],
                        ),
                      ),
                    ),
                    
                    // Botón de búsqueda (solo icono) en la esquina superior derecha
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: const Color(0xFFD4A136), // Amarillo mostaza
                        borderRadius: BorderRadius.circular(12),
                        elevation: 3,
                        child: InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, '/user-search');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_search,
                              size: 26,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              // TabBar
              Container(
                height: 48,
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF156A79),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF156A79),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.map_outlined, size: 20),
                      text: 'Explorar',
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                    Tab(
                      icon: Icon(Icons.people, size: 20),
                      text: 'Siguiendo',
                      iconMargin: EdgeInsets.only(bottom: 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Chips de filtros activos (solo en tab Explorar)
          if (isExploreTab &&
              (_selectedCountry != null || _selectedCity != null))
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
          // TabBarView con los dos tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Deshabilitar swipe entre tabs
              children: [
                // Tab 1: Explorar lugares
                ExploreTab(
                  searchController: _searchCtrl,
                  selectedCountry: _selectedCountry,
                  selectedCity: _selectedCity,
                ),
                // Tab 2: Feed social
                const FollowingTab(),
              ],
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
