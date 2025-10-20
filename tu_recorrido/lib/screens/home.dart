import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../components/bottom_pill_nav.dart';
import '../widgets/place_search_bar.dart';
import '../widgets/welcome_banner.dart';
import './perfil.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import '../services/place_service.dart';
import '../models/place.dart';
import '../widgets/places_showcase.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _userDataLoaded = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;
  double _elevT = 0; // 0.0 (top) -> 1.0 (scrolled)
  List<Place>? _places;
  List<Place>? _filteredPlaces; // Lugares filtrados por búsqueda
  bool _loadingPlaces = true;
  String? _avatarBase64; // Imagen del avatar en base64

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final o = _scrollController.offset;
      final t = (o / 48.0).clamp(0.0, 1.0);
      if ((t - _elevT).abs() > 0.05) {
        setState(() => _elevT = t);
      }
    });
    // Medir altura del header tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureHeaderHeight();
      _loadUserAvatar(); // Cargar avatar al iniciar
    });
    // Cargar lugares una sola vez
    _loadPlaces();
  }

  Future<void> _loadUserAvatar() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        final doc = await ProfileService.getUserProfile(user.uid);
        if (doc != null && doc.exists && mounted) {
          final data = doc.data();
          if (data != null) {
            final base64 = data['photoBase64'] as String?;
            if (base64 != null && base64.isNotEmpty && mounted) {
              setState(() {
                _avatarBase64 = base64;
              });
            }
          }
        }
      } catch (e) {
        // Error silencioso, el avatar mostrará el ícono por defecto
      }
    }
  }

  Future<void> _loadPlaces() async {
    try {
      final places = await PlaceService.loadPlacesFromJson();
      if (mounted) {
        setState(() {
          _places = places;
            _filteredPlaces = places; // Inicialmente mostrar todos
          _loadingPlaces = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _places = [];
            _filteredPlaces = [];
          _loadingPlaces = false;
        });
      }
    }
  }

    void _handlePlaceSearch(Place? selectedPlace) {
      setState(() {
        if (selectedPlace == null) {
          // Mostrar todos los lugares
          _filteredPlaces = _places;
        } else {
          // Mostrar solo el lugar seleccionado
          _filteredPlaces = [selectedPlace];
        }
      });
      // Scroll al top para ver el resultado
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

  void _measureHeaderHeight() {
    final ctx = _headerKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject() as RenderBox?;
      if (box != null) {
        final h = box.size.height;
        if (h > 0 && (_headerHeight - h).abs() > 0.5) {
          setState(() => _headerHeight = h + 12); // margen superior más pequeño
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-medimos cuando cambian dependencias por si cambian textos/estilos
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeaderHeight());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snap) {
        final user = snap.data;
        final userState = Provider.of<UserState>(context);
        final nombre = userState.nombre;
        final uid = user?.uid ?? '';
  final double headerSpace = _headerHeight > 0 ? _headerHeight : 110; // espacio según medida
        
        // Cargar datos del usuario desde Firestore solo una vez
        if (user != null && !_userDataLoaded) {
          _userDataLoaded = true;
          ProfileService.getUserProfile(user.uid).then((doc) async {
            if (doc != null && doc.exists && mounted) {
              final data = doc.data();
              if (data != null) {
                // Actualizar nombre desde Firestore
                final firestoreName = data['displayName'] as String?;
                if (firestoreName != null && firestoreName.isNotEmpty) {
                  await userState.setNombre(firestoreName);
                } else if (user.displayName != null && user.displayName!.isNotEmpty) {
                  await userState.setNombre(user.displayName!);
                }
                
                // Cargar avatar desde Firestore (por si acaso no se cargó en initState)
                final base64 = data['photoBase64'] as String?;
                if (base64 != null && base64.isNotEmpty && mounted) {
                  if (_avatarBase64 != base64) {
                    setState(() {
                      _avatarBase64 = base64;
                    });
                  }
                }
              }
            }
          });
        }
        
        // Resetear flag si el usuario cierra sesión
        if (user == null && _userDataLoaded) {
          _userDataLoaded = false;
          if (_avatarBase64 != null) {
            setState(() {
              _avatarBase64 = null;
            });
          }
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFFFAFBF8), // Fondo claro #FAFBF8
          body: SafeArea(
            child: Stack(
              children: [
                // Contenido scrolleable bajo el header fijo
                ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(overscroll: false, scrollbars: false),
                  child: ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(16, headerSpace, 16, 100),
                    physics: const ClampingScrollPhysics(),
                    children: [
                    WelcomeBanner(
                      nombre: nombre,
                      uid: uid,
                    ),
                    const SizedBox(height: 16),
                    if (_loadingPlaces)
                      const Center(child: CircularProgressIndicator())
                      else if (_filteredPlaces == null || _filteredPlaces!.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No se encontraron lugares',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                    else
                        PlacesShowcase(places: _filteredPlaces!),
                  ],
                ),
              ),
                // Header flotante: solo Row, sin fondo, padding horizontal 16, altura 80
                Positioned(
                  left: 0,
                  right: 0,
                  top: 12,
                  child: RepaintBoundary(
                    key: _headerKey,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      height: 80,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Barra de búsqueda expandida
                          Expanded(
                            child: PlaceSearchBar(
                              allPlaces: _places ?? [],
                              onPlaceSelected: _handlePlaceSearch,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Avatar: círculo blanco 48px con imagen o ícono, borde verde
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => SizedBox(
                                  height: MediaQuery.of(context).size.height,
                                  child: Perfil(),
                                ),
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF2F6B5F), // verde soporte
                                  width: 2,
                                ),
                                image: _avatarBase64 != null && _avatarBase64!.isNotEmpty
                                    ? DecorationImage(
                                        image: MemoryImage(base64Decode(_avatarBase64!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: _avatarBase64 == null || _avatarBase64!.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 26,
                                      color: Color(0xFF66B7F0), // celeste
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // SIN FAB: se elimina el floatingActionButton
          bottomNavigationBar: BottomPillNav(
            currentIndex: _tab,
            onTap: (i) {
              setState(() => _tab = i);
              if (i == 1) {
                Navigator.pushNamed(context, '/mapa');
              }
            },
          ),
        );
      },
    );
  }
}
