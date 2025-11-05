import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import 'package:tu_recorrido/models/lugares.dart';
import 'package:tu_recorrido/services/estamayrai.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';


class Mapita extends StatefulWidget {
  const Mapita({super.key});

  @override
  State<Mapita> createState() => _MapitaState();
}

class _MapitaState extends State<Mapita> with TickerProviderStateMixin {
  // Controlador para la animación de latido
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  static const String googleApiKeyInline =
      "AIzaSyBZ2j2pQXkUQXnkKlNkheNi-1utBPc2Vqk";

  // ⭐ Paleta de colores personalizada
  static const Color colorAmarillo = Color(0xFFF7DF3E);
  static const Color colorVerdeOliva = Color(0xFFA2AD4E);
  static const Color colorVerdeEsmeralda = Color(0xFF43A78A);
  static const Color colorAzulPetroleo = Color(0xFF264E59);
  static const Color colorGrisCarbon = Color(0xFF2E2F32);

  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription<Position>? _positionStreamSubscription;

  static const double _cardHeight = 140;
  static const double _cardWidth = 480;

  final PageController _pageController = PageController(viewportFraction: 0.90);
  int _currentPage = 0;

  // Servicios
  final EstacionesService _estacionesService = EstacionesService();
  StreamSubscription<List<PlaceResult>>? _estacionesSubscription;
  

  // Estado del mapa
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-33.4489, -70.6693), // Santiago, Chile
    zoom: 12,
  );
  final Set<Marker> _markers = {};
  Marker? _userMarker;
  List<PlaceResult> _lugares = [];
  final Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  LatLng? _currentDestination;

  // Variables de estado
  static const double _arrivalToleranceMeters = 20000.0; // 20 km de rango para mostrar el botón de rating
  bool _isRouteActive = false;
  bool _arrivalHandled = false;

  // Lugares
  PlaceResult? _destinationPlace;

  // Configuración
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 3,
  );

  final LocationSettings _oneTimeLocationSettings = const LocationSettings(
    accuracy: LocationAccuracy.best,
  );

  BitmapDescriptor? _customMarkerIcon;

  Future<void> _createCustomMarker() async {
    final recoder = ui.PictureRecorder();
    final canvas = Canvas(recoder);
    // Dibujar el círculo de fondo
    final paint = Paint()
      ..color = const ui.Color.fromARGB(255, 223, 233, 232)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(24, 24), 24, paint);

    // Dibujar el icono de cámara
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.camera_alt.codePoint),
      style: TextStyle(
        fontSize: 30,
        fontFamily: Icons.camera_alt.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(9, 9));

    final picture = recoder.endRecording();
    final image = await picture.toImage(48, 48);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    setState(() {
      _customMarkerIcon = BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
    });
  }

  Future<void> _initializeMap() async {
    await _createCustomMarker();
    _determinePositionAndStartListening();
    _cargarEstaciones();
  }

  @override
  void initState() {
    super.initState();
    
    // Inicializar el mapa y los marcadores
    _initializeMap();
    
    // Inicializar el controlador de la animación de latido
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Hacer que la animación se repita indefinidamente
    _pulseController.repeat(reverse: true);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.addListener(_pageControllerListener);
      }
    });
  }

  @override
  void dispose() {
    _estacionesSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    _pageController.removeListener(_pageControllerListener);
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _cargarEstaciones() {
    print('🔍 Intentando cargar estaciones desde Firestore...');
    _estacionesSubscription = _estacionesService.obtenerEstaciones().listen(
      (estaciones) {
        print('📍 Estaciones recibidas de Firestore: ${estaciones.length}');
        if (!mounted) return;
        
        setState(() {
          _lugares = estaciones;
          _markers.clear();
          
          // Agregar los lugares de Firestore
          for (final estacion in estaciones) {
            _markers.add(
              Marker(
                markerId: MarkerId(estacion.placeId),
                position: estacion.ubicacion,
                icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(200.0),
                infoWindow: InfoWindow(
                  title: estacion.nombre,
                  snippet: estacion.rating != null 
                      ? '⭐ ${estacion.rating!.toStringAsFixed(1)}'
                      : 'Sin calificación',
                ),
              ),
            );
          }
          
          // Si no hay lugares en Firestore, mostramos un mensaje
          if (estaciones.isEmpty) {
            print('⚠️ No hay estaciones en Firestore');
            _showSnackBar('No hay estaciones disponibles');
          }
          
          // Siempre agregamos el marcador del usuario si existe
          if (_userMarker != null) {
            _markers.add(_userMarker!);
          }
        });
      },
      onError: (e) {
        print('❌ Error al cargar estaciones de Firestore: $e');
        if (mounted) {
          setState(() {
            _markers.clear();
            if (_userMarker != null) {
              _markers.add(_userMarker!);
            }
          });
          _showSnackBar('Error al cargar estaciones');
        }
      },
    );
  }
    
  PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKeyInline);

  void _pageControllerListener() {
    if (_pageController.page != null) {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
          if (!_isRouteActive) _polylines.clear();
        });
        if (next >= 0 && next < _lugares.length) {
          _goToPosition(_lugares[next].ubicacion, zoom: 17.0);
        }
      }
    }
  }

  void _filterPlacesByDistance() {
    if (_currentPosition == null) return;

    const double maxDistanceMeters = 5000;
    // Filtrar las estaciones que ya tenemos cargadas de Firestore
    final List<PlaceResult> nearbyPlaces = _lugares.where((estacion) {
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        estacion.ubicacion.latitude,
        estacion.ubicacion.longitude,
      );
      return d <= maxDistanceMeters;
    }).toList();

    nearbyPlaces.sort((a, b) {
      final da = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.ubicacion.latitude,
        a.ubicacion.longitude,
      );
      final db = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.ubicacion.latitude,
        b.ubicacion.longitude,
      );
      return da.compareTo(db);
    });

    setState(() {
      _lugares = nearbyPlaces;
      _markers.clear();

      if (_userMarker != null) _markers.add(_userMarker!);

      for (final estacion in nearbyPlaces) {
        _markers.add(
          Marker(
            markerId: MarkerId(estacion.placeId),
            position: estacion.ubicacion,
            icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(220.0),
            infoWindow: InfoWindow(
              title: estacion.nombre,
              snippet: estacion.rating != null
                  ? '⭐ ${estacion.rating!.toStringAsFixed(1)}'
                  : 'Sin calificar',
            ),
            onTap: () {
              final index =
                  _lugares.indexWhere((p) => p.placeId == estacion.placeId);
              if (index != -1 && _pageController.hasClients) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _goToPosition(estacion.ubicacion, zoom: 17.0);
              }
            },
          ),
        );
      }

      if (_pageController.hasClients) {
        final newPage = _currentPage < _lugares.length ? _currentPage : 0;
        _pageController.jumpToPage(newPage);
        _currentPage = newPage;
      }
    });
  }

  Future<void> _determinePositionAndStartListening() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('⚠️ Los servicios de ubicación están deshabilitados. Por favor, actívalos.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('❌ Los permisos de ubicación fueron denegados. El mapa funcionará con funcionalidad limitada.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(
            '❌ Permisos denegados permanentemente. Por favor, actívalos en Configuración > Permisos.');
        return;
      }

      print('✅ Permisos de ubicación concedidos');
    } catch (e) {
      print('❌ Error al verificar permisos: $e');
      _showSnackBar('❌ Error al verificar permisos de ubicación');
    }

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('No se pudo obtener la ubicación a tiempo.');
      });

      if (!mounted) return;

      setState(() {
        _currentPosition =
            LatLng(initialPosition.latitude, initialPosition.longitude);
        _initialCameraPosition =
            CameraPosition(target: _currentPosition!, zoom: 16.0);
      });

      _filterPlacesByDistance();
      _listenForRealTimeUpdates();
    } catch (e) {
      dev.log("❌ Error al obtener la ubicación inicial: $e");
      if (mounted && _lugares.isNotEmpty) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: _lugares.first.ubicacion,
            zoom: 14.0,
          );
        });
      }
      _showSnackBar(
          'No se pudo obtener la ubicación inicial. Usando ubicación por defecto.');
    }
  }

  void _listenForRealTimeUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) async {
      if (!mounted) return;

      if (position.accuracy > 20.0) {
        dev.log(
            '⚠️ Precisión baja (${position.accuracy.toStringAsFixed(1)}m), ignorando lectura.');
        return;
      }

      final newLatLng = LatLng(position.latitude, position.longitude);

      if (_currentPosition?.latitude != newLatLng.latitude ||
          _currentPosition?.longitude != newLatLng.longitude) {
        setState(() {
          _currentPosition = newLatLng;

          _userMarker = Marker(
            markerId: const MarkerId('current_location'),
            position: newLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: '📍 Tú Estás Aquí'),
          );

          _markers.removeWhere((m) => m.markerId.value == 'current_location');
          _markers.add(_userMarker!);
        });

        _filterPlacesByDistance();

        if (_isRouteActive && _currentDestination != null) {
          final distToDest = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _currentDestination!.latitude,
            _currentDestination!.longitude,
          );

          dev.log(
              '📍 Distancia: ${distToDest.toStringAsFixed(1)}m | Precisión: ${position.accuracy.toStringAsFixed(1)}m | _arrivalHandled: $_arrivalHandled');

          if (distToDest <= _arrivalToleranceMeters && !_arrivalHandled) {
            dev.log(
                '🎉 LLEGADA CONFIRMADA (dentro de ${_arrivalToleranceMeters}m)');
            _arrivalHandled = true;

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _onArrivedAtDestination();
              }
            });
          }
        }
      }
    }, onError: (e) {
      dev.log("❌ Error en el stream de ubicación: $e");
      _showSnackBar('❌ No se puede actualizar la ubicación en tiempo real.');
    });
  }

  void _cancelRoute() {
    setState(() {
      _polylines.clear();
      _isRouteActive = false;
      _currentDestination = null;
      _destinationPlace = null;
      _arrivalHandled = false;
    });
    _showSnackBar('🚫 Ruta cancelada.');
  }

  void _onArrivedAtDestination() {
    if (!mounted) return;

    dev.log('🎯 Mostrando modal de llegada');

    setState(() {
      _polylines.clear();
      _isRouteActive = false;
      _currentDestination = null;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: colorVerdeEsmeralda,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Felicidades!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: colorGrisCarbon,
                ),
              ),
            ],
          ),
          content: const Text(
            'Has llegado al lugar de destino.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: colorAzulPetroleo),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAmarillo,
                  foregroundColor: colorGrisCarbon,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Aceptar',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRatingDialog(PlaceResult place) async {
    double currentRating = 0.0;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void setStateDialog(VoidCallback fn) {
              setState(fn);
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorVerdeEsmeralda.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: colorVerdeEsmeralda,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Calificar ${place.nombre}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: colorGrisCarbon,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StreamBuilder<double?>(
                      stream: _estacionesService.obtenerPromedioRatings(place.placeId),
                      builder: (context, snapshot) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                snapshot.hasData ? Icons.star : Icons.star_border,
                                color: snapshot.hasData ? Colors.amber : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                snapshot.hasData
                                    ? 'Promedio: ${snapshot.data!.toStringAsFixed(1)}'
                                    : 'Sin calificaciones',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: snapshot.hasData ? Colors.black87 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<double?>(
                      future: _estacionesService.obtenerRatingUsuario(place.placeId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && currentRating == 0.0) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            setStateDialog(() {
                              currentRating = snapshot.data!;
                            });
                          });
                        }
                        return Column(
                          children: [
                            const Text(
                              'Tu calificación',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RatingBar.builder(
                              initialRating: currentRating,
                              minRating: 0.5, // Calificación mínima permitida
                              maxRating: 5.0, // Calificación máxima permitida
                              direction: Axis.horizontal,
                              allowHalfRating: true, // Permite medias estrellas
                              itemCount: 5, // Número total de estrellas a mostrar
                              itemSize: 36, // Tamaño de cada estrella
                              unratedColor: Colors.grey.withOpacity(0.3),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                setStateDialog(() {
                                  currentRating = rating;
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorVerdeEsmeralda,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      if (currentRating == 0.0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor selecciona una calificación'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      await _estacionesService.calificarEstacion(
                        place.placeId,
                        currentRating,
                      );
                      Navigator.pop(dialogContext);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Gracias por tu calificación!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (error) {
                      print('❌ Error al calificar: $error');
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al guardar la calificación. Por favor intenta nuevamente.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStartTripConfirmation(PlaceResult place) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorAzulPetroleo.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.navigation, color: colorAzulPetroleo),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Viaje a ${place.nombre}',
                  style: const TextStyle(fontSize: 18, color: colorGrisCarbon),
                ),
              ),
            ],
          ),
          content: const Text(
            '¿Deseas trazar la ruta en el mapa?',
            style: TextStyle(color: colorAzulPetroleo),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorVerdeEsmeralda,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (_currentPosition == null) {
                  _showSnackBar(
                      '📍 Obteniendo tu ubicación para trazar la ruta...');
                  _goToPosition(place.ubicacion, zoom: 17.0);
                  return;
                }
                _getRoute(_currentPosition!, place.ubicacion, place);
              },
              child: const Text('Sí, Iniciar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getRoute(
      LatLng origin, LatLng destination, PlaceResult place) async {
    _showSnackBar('🗺️ Trazando ruta...');

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKeyInline';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decoded = PolylinePoints.decodePolyline(points);
          final coords =
              decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();

          setState(() {
            _polylines.clear();
            _isRouteActive = true;
            _arrivalHandled = false;
            _currentDestination = destination;
            _destinationPlace = place;

            dev.log(
                '🚀 Ruta activada. Destino: ${destination.latitude}, ${destination.longitude}');

            _polylines.add(
              Polyline(
                polylineId: const PolylineId('http_route_to_poi'),
                color: const Color.fromARGB(255, 223, 255, 42),
                points: coords,
                width: 6,
                geodesic: true,
              ),
            );
          });

          _fitMapToRoute(origin, destination);
        } else {
          _showSnackBar('❌ No se encontró ninguna ruta.');
        }
      } else {
        _showSnackBar('❌ Error de conexión: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("❌ Error al obtener la ruta: $e");
      _showSnackBar('❌ Error al trazar la ruta. Verifica tu conexión.');
    }
  }

  Future<void> _fitMapToRoute(LatLng origin, LatLng destination) async {
    final GoogleMapController controller = await _controller.future;

    final sw = LatLng(
      origin.latitude < destination.latitude
          ? origin.latitude
          : destination.latitude,
      origin.longitude < destination.longitude
          ? origin.longitude
          : destination.longitude,
    );
    final ne = LatLng(
      origin.latitude > destination.latitude
          ? origin.latitude
          : destination.latitude,
      origin.longitude > destination.longitude
          ? origin.longitude
          : destination.longitude,
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(
        LatLngBounds(southwest: sw, northeast: ne), 70));
  }

  Future<void> _goToPosition(LatLng position, {double zoom = 16.0}) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom)));
  }

  Future<void> _goToTheUserLocation() async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('No se pudo obtener la ubicación a tiempo.');
      });

      await _goToPosition(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 16.0);
    } catch (e) {
      dev.log("❌ Error en el botón Mi ubicación: $e");
      _showSnackBar(
          '❌ No se pudo obtener la ubicación. Verifica permisos y GPS.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorAzulPetroleo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool canShowFlagBtn = false;
    if (_isRouteActive &&
        _currentDestination != null &&
        _currentPosition != null) {
      final distToDest = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentDestination!.latitude,
        _currentDestination!.longitude,
      );
      canShowFlagBtn = distToDest <= _arrivalToleranceMeters;
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              print('🗺️ Mapa creado correctamente');
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
          ),

          // ⭐ Botón Mi ubicación (esquina superior derecha)
          Positioned(
            top: 60,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: colorVerdeOliva,
              child: InkWell(
                onTap: _goToTheUserLocation,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // ⭐ Botón QR (esquina superior izquierda)
          Positioned(
            top: 60,
            left: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: colorVerdeOliva,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/escaner'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),

          // ⭐ Botón cancelar ruta
          if (_isRouteActive)
            Positioned(
              top: 125,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.redAccent,
                child: InkWell(
                  onTap: _cancelRoute,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // ⭐ Botón evaluar lugar
          if (canShowFlagBtn && _destinationPlace != null)
            Positioned(
              top: 185,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: colorVerdeEsmeralda,
                child: InkWell(
                  onTap: () => _showRatingDialog(_destinationPlace!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),

          // ⭐ Carrusel de cards en la parte inferior
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: _cardHeight + 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: _cardHeight,
                    child: _lugares.isEmpty && _currentPosition != null
                        ? Container(
                            width: _cardWidth,
                            height: _cardHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "🔍 No hay lugares en un radio de 5 km",
                                style: TextStyle(
                                  color: colorGrisCarbon,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : PageView(
                            controller: _pageController,
                            physics: const ClampingScrollPhysics(),
                            children: _lugares.asMap().entries.map((entry) {
                              final index = entry.key;
                              final place = entry.value;

                              return _buildCard(
                                place.nombre,
                                'Rating: ${place.rating?.toStringAsFixed(1) ?? 'Sin calificar'}',
                                index + 1,
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // ⭐ Indicadores de página (dots alargados)
                  if (_lugares.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _lugares.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: _currentPage == index
                                ? colorVerdeOliva
                                : Colors.grey.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Calcula el texto de distancia y tiempo estimado para mostrar en la card
  String _getDistanceText(LatLng ubicacion) {
    if (_currentPosition == null) return '';
    
    final double distanceMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      ubicacion.latitude,
      ubicacion.longitude,
    );
    
    // Velocidad promedio caminando: 5 km/h = 1.4 m/s
    final double walkingSpeedMps = 1.4;
    final int timeSeconds = (distanceMeters / walkingSpeedMps).round();
    
    String timeText;
    if (timeSeconds < 60) {
      timeText = '$timeSeconds seg';
    } else if (timeSeconds < 3600) {
      final int minutes = (timeSeconds / 60).round();
      timeText = '$minutes min';
    } else {
      final int hours = (timeSeconds / 3600).round();
      final int remainingMinutes = ((timeSeconds % 3600) / 60).round();
      timeText = hours > 0 ? 
        (remainingMinutes > 0 ? '$hours h $remainingMinutes min' : '$hours h') :
        '$remainingMinutes min';
    }
    
    // Convertir a kilómetros si es más de 1000 metros
    String distanceText;
    if (distanceMeters >= 1000) {
      distanceText = '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    } else {
      distanceText = '${distanceMeters.toStringAsFixed(0)} m';
    }
    
    return '$distanceText • $timeText';
  }

  // Widget para construir la tarjeta de cada lugar
  Widget _buildCard(String title, String subtitle, int cardNumber) {
    final place = _lugares[cardNumber - 1];
    final bool isDisabled = _isRouteActive;
    
    // Verificar si estamos cerca del destino (5 metros)
    bool isNearDestination = false;
    double? currentDistance;
    
    if (_currentPosition != null) {
      currentDistance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        place.ubicacion.latitude,
        place.ubicacion.longitude,
      );
      
      if (_isRouteActive && _currentDestination != null && 
          place.ubicacion.latitude == _currentDestination!.latitude &&
          place.ubicacion.longitude == _currentDestination!.longitude) {
        isNearDestination = currentDistance <= 5; // 5 metros
        if (isNearDestination && !_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        } else if (!isNearDestination && _pulseController.isAnimating) {
          _pulseController.stop();
        }
      }
    }

    final displayRating = place.rating != null
        ? place.rating!.toStringAsFixed(1)
        : 'Sin calificar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: isNearDestination ? _pulseAnimation.value : 1.0,
            child: SizedBox(
              width: _cardWidth,
              height: _cardHeight,
              child: Card(
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: isDisabled
                      ? () => _showSnackBar(
                          '⚠️ Cancela la ruta actual (botón X) antes de iniciar una nueva.')
                      : () => _showStartTripConfirmation(place),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // ⭐ Icono circular verde a la izquierda
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: colorVerdeOliva.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.place,
                            color: colorVerdeOliva,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ⭐ Contenido del card
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Título del lugar
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorGrisCarbon,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Rating y distancia
                              Row(
                                children: [
                                  // Rating con estrella
                                  const Icon(
                                    Icons.star,
                                    size: 20,
                                    color: colorAmarillo,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayRating,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (_currentPosition != null)
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.directions_walk,
                                            size: 20,
                                            color: colorVerdeOliva,
                                          ),
                                          const SizedBox(width: 2),
                                          Flexible(
                                            child: Text(
                                              _getDistanceText(place.ubicacion),
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}