import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

import 'package:tu_recorrido/models/lugares.dart';
import 'package:tu_recorrido/models/marcadores.dart';
import 'package:tu_recorrido/screens/perfil.dart';
import 'package:tu_recorrido/widgets/role_protected_widget.dart';

class Mapita extends StatefulWidget {
  const Mapita({super.key});

  @override
  State<Mapita> createState() => _MapitaState();
}

class _MapitaState extends State<Mapita> {
  static const String googleApiKeyInline = "AIzaSyBZ2j2pQXkUQXnkKlNkheNi-1utBPc2Vqk";

  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription<Position>? _positionStreamSubscription;

  static const double _cardHeight = 100;
  static const double _cardWidth = 300;

  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  CameraPosition? _initialCameraPosition;
  Marker? _userMarker;
  List<PlaceResult> _lugares = [];
  final Set<Marker> _markers = {};

  final Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  LatLng? _currentDestination;

  static const double _arrivalToleranceMeters = 100.0; // 100 m
  bool _isRouteActive = false;
  bool _arrivalHandled = false;

  PlaceResult? _destinationPlace;

  PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKeyInline);

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  final LocationSettings _oneTimeLocationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
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
    final List<PlaceResult> allPlaces = MarcadoresData.lugaresMarcados;

    final List<PlaceResult> nearbyPlaces = allPlaces.where((place) {
      final d = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        place.ubicacion.latitude,
        place.ubicacion.longitude,
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

      for (final place in allPlaces) {
        _markers.add(
          Marker(
            markerId: MarkerId(place.placeId),
            position: place.ubicacion,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: place.nombre,
              snippet: place.rating != null
                  ? 'Rating: ${place.rating!.toStringAsFixed(1)}'
                  : 'Sin calificar',
            ),
            onTap: () {
              final index = _lugares.indexWhere((p) => p.placeId == place.placeId);
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
      }

      if (_pageController.hasClients) {
        final newPage = _currentPage < _lugares.length ? _currentPage : 0;
        _pageController.jumpToPage(newPage);
        _currentPage = newPage;
      }
    });
  }

  Future<void> _determinePositionAndStartListening() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) _showSnackBar('Los servicios de ubicación están deshabilitados.');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Los permisos de ubicación fueron denegados.');
      }
    }

    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('No se pudo obtener la ubicación a tiempo.');
      });

      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(initialPosition.latitude, initialPosition.longitude);
        _initialCameraPosition = CameraPosition(target: _currentPosition!, zoom: 16.0);
      });

      _filterPlacesByDistance();
      _listenForRealTimeUpdates();
    } catch (e) {
      dev.log("Error al obtener la ubicación inicial: $e");
      if (mounted && _initialCameraPosition == null && MarcadoresData.lugaresMarcados.isNotEmpty) {
        setState(() {
          _initialCameraPosition = CameraPosition(
            target: MarcadoresData.lugaresMarcados.first.ubicacion,
            zoom: 14.0,
          );
        });
      }
      _showSnackBar('No se pudo obtener la ubicación inicial. Usando ubicación por defecto.');
    }
  }

  void _listenForRealTimeUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) async {
      if (!mounted) return;

      final newLatLng = LatLng(position.latitude, position.longitude);

      if (_currentPosition?.latitude != newLatLng.latitude ||
          _currentPosition?.longitude != newLatLng.longitude) {
        setState(() {
          _currentPosition = newLatLng;

          _userMarker = Marker(
            markerId: const MarkerId('current_location'),
            position: newLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Tú Estás Aquí'),
          );

          _markers.removeWhere((m) => m.markerId.value == 'current_location');
          _markers.add(_userMarker!);
        });

        _filterPlacesByDistance();

        // ⭐ CORREGIDO: Llegada automática con Future.delayed
        if (_isRouteActive && _currentDestination != null) {
          final distToDest = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            _currentDestination!.latitude,
            _currentDestination!.longitude,
          );

          dev.log('📍 Distancia al destino: ${distToDest.toStringAsFixed(1)} m | _arrivalHandled: $_arrivalHandled');

          if (distToDest <= _arrivalToleranceMeters && !_arrivalHandled) {
            dev.log('🎉 ACTIVANDO MODAL DE LLEGADA');
            _arrivalHandled = true;
            
            // ⭐ Future.delayed para asegurar que el modal se muestre
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
      _showSnackBar('No se puede actualizar la ubicación en tiempo real.');
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
    _showSnackBar('Ruta cancelada.');
  }

  // ⭐ Modal automático de llegada CORREGIDO
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
          title: const Text(
            '¡Felicidades!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          content: const Text(
            'Has llegado al lugar.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Aceptar'),
              ),
            ),
          ],
        );
      },
    );
  }

  // ⭐ Modal de evaluación CORREGIDO (sin overflow)
  void _showRatingDialog(PlaceResult place) {
    int selectedRating = 0;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (_, setStateDialog) {
            return AlertDialog(
              contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              title: Text(
                'Evalúa ${place.nombre}',
                style: const TextStyle(fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '¿Cómo calificarías tu experiencia?',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starValue = i + 1;
                        return IconButton(
                          iconSize: 32,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            selectedRating >= starValue ? Icons.star : Icons.star_border,
                            color: selectedRating >= starValue ? Colors.amber : Colors.grey,
                          ),
                          onPressed: () => setStateDialog(() => selectedRating = starValue),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    if (selectedRating > 0)
                      Text(
                        '$selectedRating de 5 estrellas',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                  ],
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
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
                              _showSnackBar('Gracias por evaluar ${place.nombre}.');
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

  void _showStartTripConfirmation(PlaceResult place) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Iniciar Viaje a ${place.nombre}'),
          content: const Text('¿Deseas trazar la ruta en el mapa?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Sí, Iniciar', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                if (_currentPosition == null) {
                  _showSnackBar('Obteniendo tu ubicación para trazar la ruta...');
                  _goToPosition(place.ubicacion, zoom: 17.0);
                  return;
                }
                _getRoute(_currentPosition!, place.ubicacion, place);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getRoute(LatLng origin, LatLng destination, PlaceResult place) async {
    _showSnackBar('Trazando ruta con la API directa...');

    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$googleApiKeyInline';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          final decoded = PolylinePoints.decodePolyline(points);
          final coords = decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();

          setState(() {
            _polylines.clear();
            _isRouteActive = true;
            _arrivalHandled = false;
            _currentDestination = destination;
            _destinationPlace = place;

            dev.log('🚀 Ruta activada. Destino: ${destination.latitude}, ${destination.longitude}');

            _polylines.add(
              Polyline(
                polylineId: const PolylineId('http_route_to_poi'),
                color: Theme.of(context).colorScheme.primary,
                points: coords,
                width: 5,
                geodesic: true,
              ),
            );
          });

          _fitMapToRoute(origin, destination);
        } else {
          _showSnackBar('No se encontró ninguna ruta.');
        }
      } else {
        _showSnackBar('Error de conexión a la API de Google: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("❌ Error al obtener la ruta: $e");
      _showSnackBar('Error al trazar la ruta. Verifica tu conexión.');
    }
  }

  Future<void> _fitMapToRoute(LatLng origin, LatLng destination) async {
    final GoogleMapController controller = await _controller.future;

    final sw = LatLng(
      origin.latitude < destination.latitude ? origin.latitude : destination.latitude,
      origin.longitude < destination.longitude ? origin.longitude : destination.longitude,
    );
    final ne = LatLng(
      origin.latitude > destination.latitude ? origin.latitude : destination.latitude,
      origin.longitude > destination.longitude ? origin.longitude : destination.longitude,
    );

    await controller.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: sw, northeast: ne), 70));
  }

  Future<void> _goToPosition(LatLng position, {double zoom = 16.0}) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: position, zoom: zoom)),
    );
  }

  Future<void> _goToTheUserLocation() async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('No se pudo obtener la ubicación a tiempo.');
      });

      await _goToPosition(LatLng(currentPosition.latitude, currentPosition.longitude), zoom: 16.0);
    } catch (e) {
      dev.log("❌ Error en el botón Mi ubicación: $e");
      _showSnackBar('No se pudo obtener la ubicación. Verifica permisos y GPS.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    bool canShowFlagBtn = false;
    if (_isRouteActive && _currentDestination != null && _currentPosition != null) {
      final distToDest = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _currentDestination!.latitude,
        _currentDestination!.longitude,
      );
      canShowFlagBtn = distToDest <= _arrivalToleranceMeters;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntos de Interés'),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          // Botón de admin (solo visible para administradores)
          ConditionalWidget(
            condition: (permissions) => permissions.canAccessAdmin,
            child: IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              tooltip: 'Panel de Administración',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const Perfil()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition!,
            onMapCreated: (GoogleMapController controller) => _controller.complete(controller),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
          ),

          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToTheUserLocation,
              heroTag: 'miUbicacionBtn',
              backgroundColor: Colors.amber,
              tooltip: 'Mi ubicación',
              child: const Icon(Icons.my_location),
            ),
          ),

          if (_isRouteActive)
            Positioned(
              top: 85,
              right: 16,
              child: FloatingActionButton(
                onPressed: _cancelRoute,
                heroTag: 'cancelRouteBtn',
                backgroundColor: Colors.redAccent,
                tooltip: 'Cancelar Ruta',
                mini: true,
                child: const Icon(Icons.close),
              ),
            ),

          if (canShowFlagBtn && _destinationPlace != null)
            Positioned(
              top: 140,
              right: 16,
              child: FloatingActionButton(
                onPressed: () => _showRatingDialog(_destinationPlace!),
                heroTag: 'nearArrivalBtn',
                backgroundColor: Colors.green,
                tooltip: 'Evaluar ${_destinationPlace!.nombre}',
                mini: true,
                child: const Icon(Icons.flag),
              ),
            ),

          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () => _showSnackBar('Escaneando QR...'),
              heroTag: 'qrBtn',
              backgroundColor: Colors.amber,
              tooltip: 'Escanear QR',
              child: const Icon(Icons.qr_code_scanner),
            ),
          ),

          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: ClipRect(
              child: SizedBox(
                height: _cardHeight + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: _cardHeight,
                      child: _lugares.isEmpty && _currentPosition != null
                          ? Container(
                              width: double.infinity,
                              height: _cardHeight,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "No hay lugares en un radio de 5 km",
                                  style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 6),
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
                              color: _currentPage == index ? theme.colorScheme.primary : Colors.grey.withOpacity(0.5),
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

  Widget _buildCard(String title, String subtitle, int cardNumber) {
    final place = _lugares[cardNumber - 1];
    final bool isDisabled = _isRouteActive;

    final displayRating = place.rating != null ? 'Rating: ${place.rating!.toStringAsFixed(1)}' : 'Sin calificar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Center(
        child: SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: Card(
            elevation: 4.0,
            color: isDisabled ? Colors.grey[200] : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: InkWell(
              onTap: isDisabled
                  ? () => _showSnackBar('Cancela la ruta actual (botón X) antes de iniciar una nueva.')
                  : () => _showStartTripConfirmation(place),
              borderRadius: BorderRadius.circular(12.0),
              splashColor: Colors.amber.withOpacity(0.25),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.black45 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayRating,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDisabled ? Colors.black38 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (place.rating != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Row(
                          children: List.generate(
                            5,
                            (index) => Icon(
                              index < place.rating!.round() ? Icons.star : Icons.star_border,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
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