import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import 'package:tu_recorrido/models/lugares.dart';
import 'package:tu_recorrido/models/marcadores.dart';


class Mapita extends StatefulWidget {
  const Mapita({super.key});

  @override
  State<Mapita> createState() => _MapitaState();
}

class _MapitaState extends State<Mapita> {
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

  static const double _cardHeight = 130;
  static const double _cardWidth = 300;
  static const double _imageWidth = 80;

  // Manejo del Carrusel
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  // Datos del Mapa y Lugares
  CameraPosition? _initialCameraPosition;
  Marker? _userMarker;
  List<PlaceResult> _lugares = [];
  final Set<Marker> _markers = {};

  // Variables para la Ruta
  final Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  LatLng? _currentDestination;

  static const double _arrivalToleranceMeters = 50.0; // ⭐ Reducido a 50m para mayor precisión
  bool _isRouteActive = false;

  // Variables para manejo de llegada
  double distToDest = 0.0;
  bool _arrivalHandled = false;
  static const double _arrivalToleranceMeters = 50.0;
  LatLng? _currentDestination;
  PlaceResult? _destinationPlace;

  // Inicializamos PolylinePoints SOLO para la función decodePolyline
  PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKeyInline);

  // ⭐ MEJORA 1: LocationSettings con máxima precisión
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation, // Máxima precisión
    distanceFilter: 3, // Actualiza cada 3 metros
  );

  final LocationSettings _oneTimeLocationSettings = const LocationSettings(
    accuracy: LocationAccuracy.best,
  );

  @override
  void initState() {
    super.initState();

    _determinePositionAndStartListening();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.addListener(_pageControllerListener);
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _pageController.removeListener(_pageControllerListener);
    _pageController.dispose();
    super.dispose();
  }

  // --- Lógica de Filtrado y Geolocalización ---

  void _pageControllerListener() {
    if (_pageController.page != null) {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
          // Limpiar polilíneas al deslizar, a menos que ya estés en una ruta
          if (!_isRouteActive) {
            _polylines.clear();
          }
        });

        if (next >= 0 && next < _lugares.length) {
          final targetPosition = _lugares[next].ubicacion;
          _goToPosition(targetPosition, zoom: 17.0);
        }
      }
    }
  }

  void _filterPlacesByDistance() {
    if (_currentPosition == null) {
      return;
    }

    const double maxDistanceMeters = 5000;
    final List<PlaceResult> allPlaces = MarcadoresData.lugaresMarcados;

    final List<PlaceResult> nearbyPlaces = allPlaces.where((place) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        place.ubicacion.latitude,
        place.ubicacion.longitude,
      );
      return distance <= maxDistanceMeters;
    }).toList();

    nearbyPlaces.sort((a, b) {
      double distA = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.ubicacion.latitude,
          a.ubicacion.longitude);
      double distB = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.ubicacion.latitude,
          b.ubicacion.longitude);
      return distA.compareTo(distB);
    });

    setState(() {
      _lugares = nearbyPlaces;
      _markers.clear();
      if (_userMarker != null) {
        _markers.add(_userMarker!);
      }

      if (_userMarker != null) _markers.add(_userMarker!);

      for (final place in allPlaces) {
        _markers.add(
          Marker(
            markerId: MarkerId(place.placeId),
            position: place.ubicacion,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen), // ⭐ Verde esmeralda
            infoWindow: InfoWindow(
              title: place.nombre,
              snippet: place.rating != null
                  ? 'Rating: ${place.rating!.toStringAsFixed(1)}'
                  : 'Sin calificar',
            ),
            onTap: () {
              final index =
                  _lugares.indexWhere((p) => p.placeId == place.placeId);
              if (index != -1 && _pageController.hasClients) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _goToPosition(place.ubicacion, zoom: 17.0);
              }
            },
          ),
        );
        // Línea duplicada eliminada - el marcador ya fue agregado arriba
      }

      if (_pageController.hasClients) {
        // Mantiene la página si el índice sigue siendo válido
        int newPage = _currentPage < _lugares.length ? _currentPage : 0;
        _pageController.jumpToPage(newPage);
        _currentPage = newPage;
      }
    });

    _showSnackBar(
        'Lugares cercanos actualizados: ${_lugares.length} encontrados en 5 km.');
  }

  Future<void> _determinePositionAndStartListening() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('⚠️ Los servicios de ubicación están deshabilitados.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('❌ Los permisos de ubicación fueron denegados.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnackBar('❌ Permisos denegados permanentemente. Actívalos en Configuración.');
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException(
              'No se pudo obtener la ubicación a tiempo.'));

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
      if (mounted && _initialCameraPosition == null && MarcadoresData.lugaresMarcados.isNotEmpty) {
        setState(() {
          _initialCameraPosition = CameraPosition(
              target: MarcadoresData.lugaresMarcados.first.ubicacion,
              zoom: 14.0);
        });
      }
      _showSnackBar(
          'No se pudo obtener la ubicación inicial. Usando ubicación por defecto.');
    }
  }

  // ⭐ MEJORA 2: Filtro de precisión en el stream de ubicación
  void _listenForRealTimeUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) async {
      if (!mounted) return;

      // ⭐ MEJORA 3: Filtrar ubicaciones con precisión menor a 20 metros
      if (position.accuracy > 20.0) {
        dev.log('⚠️ Precisión baja (${position.accuracy.toStringAsFixed(1)}m), ignorando lectura.');
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
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // ⭐ Azul petróleo
            infoWindow: const InfoWindow(title: '📍 Tú Estás Aquí'),
          );

        if (_currentPosition?.latitude != newLatLng.latitude ||
            _currentPosition?.longitude != newLatLng.longitude) {
          setState(() {
            _currentPosition = newLatLng;

            _userMarker = Marker(
              markerId: const MarkerId('current_location'),
              position: newLatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'Tú Estás Aquí'),
            );

            _markers.removeWhere((m) => m.markerId.value == 'current_location');
            _markers.add(_userMarker!);
          });

        if (_isRouteActive && _currentDestination != null) {
          final distToDest = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _currentDestination!.latitude,
            _currentDestination!.longitude,
          );

          dev.log('📍 Distancia: ${distToDest.toStringAsFixed(1)}m | Precisión: ${position.accuracy.toStringAsFixed(1)}m | _arrivalHandled: $_arrivalHandled');

          if (distToDest <= _arrivalToleranceMeters && !_arrivalHandled) {
            dev.log('🎉 LLEGADA CONFIRMADA (dentro de ${_arrivalToleranceMeters}m)');
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

  // --- Lógica de Rutas, Navegación y Cancelación ---

  // ⭐️ FUNCIÓN: Cancela la ruta y limpia el mapa
  void _cancelRoute() {
    setState(() {
      _polylines.clear();
      _isRouteActive = false;
      _currentDestination = null;
      _destinationPlace = null;
      _arrivalHandled = false;
      distToDest = 0.0;
      _showSnackBar(tr('route_canceled'));
    });
    _showSnackBar('🚫 Ruta cancelada.');
  }

  // ⭐ Modal con diseño renovado
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: colorVerdeEsmeralda,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.white, size: 48),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRatingDialog(PlaceResult place) {
    int selectedRating = 0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorVerdeEsmeralda.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.star, color: colorVerdeEsmeralda, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Evalúa ${place.nombre}',
                      style: const TextStyle(fontSize: 18, color: colorGrisCarbon),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¿Cómo calificarías tu experiencia?',
                      style: TextStyle(fontSize: 14, color: colorAzulPetroleo),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starValue = i + 1;
                        return IconButton(
                          iconSize: 36,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            selectedRating >= starValue ? Icons.star : Icons.star_border,
                            color: selectedRating >= starValue ? colorAmarillo : Colors.grey.shade400,
                          ),
                          onPressed: () =>
                              setStateDialog(() => selectedRating = starValue),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    if (selectedRating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorAmarillo.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$selectedRating de 5 estrellas',
                          style: const TextStyle(fontSize: 12, color: colorGrisCarbon, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: colorGrisCarbon,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedRating > 0 ? colorVerdeEsmeralda : Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: selectedRating > 0
                          ? () {
                              MarcadoresData.updatePlaceRating(
                                place.placeId,
                                selectedRating.toDouble(),
                              );
                              Navigator.of(dialogContext).pop();
                              setState(() {
                                _filterPlacesByDistance();
                              });
                              _showSnackBar('✅ Gracias por evaluar ${place.nombre}.');
                            }
                          : null,
                      child: const Text('Enviar'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ⭐️ FUNCIÓN: Muestra el modal de confirmación antes de trazar la ruta
  void _showStartTripConfirmation(PlaceResult place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorAzulPetroleo.withOpacity(0.2),
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
            // Botón NO (Cerrar modal)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorVerdeEsmeralda,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el modal primero

                if (_currentPosition == null) {
                  _showSnackBar('📍 Obteniendo tu ubicación para trazar la ruta...');
                  _goToPosition(place.ubicacion, zoom: 17.0);
                  return;
                }

                // Inicia el trazado de la ruta (función que ya existe)
                _getRoute(_currentPosition!, place.ubicacion, place);
              },
              child: const Text('Sí, Iniciar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getRoute(LatLng origin, LatLng destination, PlaceResult place) async {
    _showSnackBar('🗺️ Trazando ruta...');

    final String apiKey = googleApiKeyInline;

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

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
            // ⭐️ CAMBIO: Activar el estado de ruta
            _isRouteActive = true;
            _arrivalHandled = false;
            _currentDestination = destination;
            _destinationPlace = place;

            dev.log(
                '🚀 Ruta activada. Destino: ${destination.latitude}, ${destination.longitude}');

            _polylines.add(
              Polyline(
                polylineId: const PolylineId('http_route_to_poi'),
                color: colorVerdeEsmeralda, // ⭐ Verde esmeralda
                points: coords,
                width: 6,
                geodesic: true,
              ),
            );
            // Línea duplicada eliminada - la polilínea ya fue agregada arriba
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
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: zoom)),
    );
  }

  Future<void> _goToTheUserLocation() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException(
              'No se pudo obtener la ubicación a tiempo.'));

      await _goToPosition(
          LatLng(currentPosition.latitude, currentPosition.longitude),
          zoom: 16.0);
    } catch (e) {
      dev.log("❌ Error en el botón Mi ubicación: $e");
      _showSnackBar('❌ No se pudo obtener la ubicación. Verifica permisos y GPS.');
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

  // --- Construcción de la UI ---

  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorVerdeEsmeralda),
              const SizedBox(height: 16),
              const Text('Obteniendo ubicación...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

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
          // MAPA
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition!,
            onMapCreated: (GoogleMapController controller) =>
                _controller.complete(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
          ),

          // ⭐ Botón Mi ubicación con nuevo diseño
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToTheUserLocation,
              heroTag: 'miUbicacionBtn',
              backgroundColor: colorVerdeOliva,
              elevation: 4,
              child: const Icon(Icons.my_location, color: Color.fromARGB(255, 255, 255, 255)),
            ),
          ),

          // ⭐ Botón cancelar ruta
          if (_isRouteActive)
            Positioned(
              top: 85,
              right: 16,
              child: FloatingActionButton(
                onPressed: _cancelRoute,
                heroTag: 'cancelRouteBtn',
                backgroundColor: Colors.redAccent,
                mini: true,
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),

          // ⭐ Botón evaluar lugar
          if (canShowFlagBtn && _destinationPlace != null)
            Positioned(
              top: 140,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showRatingDialog(_destinationPlace!),
                heroTag: 'nearArrivalBtn',
                backgroundColor: colorVerdeEsmeralda,
                mini: true,
                child: const Icon(Icons.star, color: Colors.white),
              ),
            ),

          // ⭐ Botón QR
          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () => _showSnackBar('📷 Escaneando QR...'),
              heroTag: 'qrBtn',
              backgroundColor: colorVerdeOliva,
              child: const Icon(Icons.qr_code_scanner, color: Colors.white),
            ),
          ),

          // ⭐ Carrusel con nuevo diseño
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: ClipRect(
              child: SizedBox(
                height: _cardHeight + 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _cardHeight,
                      child: _lugares.isEmpty && _currentPosition != null
                          ? Container(
                              width: double.infinity,
                              height: _cardHeight,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorAzulPetroleo, colorGrisCarbon],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  "🔍 No hay lugares en un radio de 5 km",
                                  style: TextStyle(
                                    color: Colors.white,
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
                                  'assets/img/insignia.png',
                                  place.nombre,
                                  'Rating: ${place.rating?.toStringAsFixed(1) ?? 'Sin calificar'}',
                                  index + 1,
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 8),
                    if (_lugares.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _lugares.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            width: _currentPage == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index ? colorAmarillo : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para construir cada tarjeta
  Widget _buildCard(
      String imagePath, String title, String subtitle, int cardNumber) {
    // Buscamos el lugar por índice dentro de la lista _lugares (filtrada)
    final place = _lugares[cardNumber - 1];
    final bool isDisabled = _isRouteActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Center(
        child: SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: Card(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(0.3),
            color: isDisabled ? Colors.grey[300] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: isDisabled
                  ? () => _showSnackBar('⚠️ Cancela la ruta actual (botón X) antes de iniciar una nueva.')
                  : () => _showStartTripConfirmation(place),
              borderRadius: BorderRadius.circular(16),
              splashColor: colorAmarillo.withOpacity(0.3),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isDisabled
                      ? null
                      : LinearGradient(
                          colors: [
                            colorVerdeEsmeralda.withOpacity(0.1),
                            colorAmarillo.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorVerdeEsmeralda.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.place,
                            color: isDisabled ? Colors.grey : colorVerdeEsmeralda,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDisabled ? Colors.black45 : colorGrisCarbon,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: colorAmarillo),
                        const SizedBox(width: 4),
                        Text(
                          displayRating,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDisabled ? Colors.black38 : colorAzulPetroleo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (place.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < place.rating!.round() ? Icons.star : Icons.star_border,
                              size: 14,
                              color: colorAmarillo,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (place.rating != null)
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < place.rating!.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  isDisabled ? Colors.black38 : Colors.black54,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
