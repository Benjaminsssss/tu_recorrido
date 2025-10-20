import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as dev;

// Suposiciones de tus modelos (asegúrate de que existan)
import 'package:tu_recorrido/models/lugares.dart';
import 'package:tu_recorrido/models/marcadores.dart';
// Navegación a perfil se hará por ruta '/perfil'

class Mapita extends StatefulWidget {
  const Mapita({super.key});

  @override
  State<Mapita> createState() => _MapitaState();
}

class _MapitaState extends State<Mapita> {
  // 🚨 REEMPLAZA ESTA CLAVE CON TU CLAVE REAL DE GOOGLE CLOUD/DIRECTIONS API 🚨
  static const String googleApiKeyInline =
      "AIzaSyBZ2j2pQXkUQXnkKlNkheNi-1utBPc2Vqk";

  final Completer<GoogleMapController> _controller = Completer();
  StreamSubscription<Position>? _positionStreamSubscription;

  // Constantes
  static const double _cardHeight = 100;
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
  // ⭐️ NUEVO: Estado de la ruta
  bool _isRouteActive = false;

  // Inicializamos PolylinePoints SOLO para la función decodePolyline
  PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKeyInline);

  // Configuración de Geolocator
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
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

      for (final place in _lugares) {
        final marker = Marker(
          markerId: MarkerId(place.nombre),
          position: place.ubicacion,
          infoWindow: InfoWindow(title: place.nombre),
        );
        _markers.add(marker);
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnackBar('Los servicios de ubicación están deshabilitados.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Los permisos de ubicación fueron denegados.');
      }
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: _oneTimeLocationSettings,
      ).timeout(const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException(
              'No se pudo obtener la ubicación a tiempo.'));

      if (mounted) {
        setState(() {
          _currentPosition =
              LatLng(initialPosition.latitude, initialPosition.longitude);
          _initialCameraPosition = CameraPosition(
            target: _currentPosition!,
            zoom: 16.0,
          );
        });

        _filterPlacesByDistance();
      }
      _listenForRealTimeUpdates();
    } catch (e) {
      dev.log("Error al obtener la ubicación inicial: $e");

      if (mounted &&
          _initialCameraPosition == null &&
          MarcadoresData.lugaresMarcados.isNotEmpty) {
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

  void _listenForRealTimeUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (Position position) async {
        if (!mounted) return;

        final newLatLng = LatLng(position.latitude, position.longitude);

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

          _filterPlacesByDistance();
        }
      },
      onError: (e) {
        dev.log("Error en el stream de ubicación: $e");
        _showSnackBar('No se puede actualizar la ubicación en tiempo real.');
      },
    );
  }

  // --- Lógica de Rutas, Navegación y Cancelación ---

  // ⭐️ FUNCIÓN: Cancela la ruta y limpia el mapa
  void _cancelRoute() {
    setState(() {
      _polylines.clear();
      _isRouteActive = false;
      _showSnackBar(tr('route_canceled'));
    });
  }

  // ⭐️ FUNCIÓN: Muestra el modal de confirmación antes de trazar la ruta
  void _showStartTripConfirmation(PlaceResult place) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Iniciar Viaje a ${place.nombre}'),
          content: const Text('¿Deseas trazar la ruta en el mapa?'),
          actions: <Widget>[
            // Botón NO (Cerrar modal)
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el modal
              },
            ),
            // Botón SÍ (Trazar ruta)
            TextButton(
              child: const Text('Sí, Iniciar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el modal primero

                if (_currentPosition == null) {
                  _showSnackBar(
                      'Obteniendo tu ubicación para trazar la ruta...');
                  _goToPosition(place.ubicacion, zoom: 17.0);
                  return;
                }

                // Inicia el trazado de la ruta (función que ya existe)
                _getRoute(_currentPosition!, place.ubicacion);
              },
            ),
          ],
        );
      },
    );
  }

  // Función para obtener y dibujar la Polyline
  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    _showSnackBar('Trazando ruta con la API directa...');

    final String apiKey = googleApiKeyInline;

    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];

          List<PointLatLng> decodedPoints =
              PolylinePoints.decodePolyline(points);

          List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          setState(() {
            _polylines.clear();
            // ⭐️ CAMBIO: Activar el estado de ruta
            _isRouteActive = true;

            Polyline polyline = Polyline(
              polylineId: const PolylineId('http_route_to_poi'),
              color: Theme.of(context).colorScheme.primary,
              points: polylineCoordinates,
              width: 5,
              geodesic: true,
            );
            _polylines.add(polyline);
          });

          _fitMapToRoute(origin, destination);
        } else {
          _showSnackBar('No se encontró ninguna ruta.');
        }
      } else {
        _showSnackBar(
            'Error de conexión a la API de Google: ${response.statusCode}');
      }
    } catch (e) {
      dev.log("Error al obtener la ruta por HTTP: $e");
      _showSnackBar('Error al trazar la ruta. Verifica tu conexión.');
    }
  }

  Future<void> _fitMapToRoute(LatLng origin, LatLng destination) async {
    final GoogleMapController controller = await _controller.future;

    LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude < destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude > destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
    );

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  Future<void> _goToPosition(LatLng position, {double zoom = 16.0}) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
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
        zoom: 16.0,
      );
    } catch (e) {
      dev.log("Error en el botón: $e");
      _showSnackBar(
          'No se pudo obtener la ubicación. Verifica permisos y GPS.');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // --- Construcción de la UI ---

  @override
  Widget build(BuildContext context) {
    if (_initialCameraPosition == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('poi_title')),
        backgroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/perfil'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // MAPA
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialCameraPosition!,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
            zoomControlsEnabled: false,
          ),

          // Botones de Ubicación y QR
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

          // ⭐️ NUEVO: Botón X para cancelar ruta, solo visible si la ruta está activa
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

          Positioned(
            top: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () => _showSnackBar('Escaneando QR...'),
              heroTag: 'qrBtn',
              backgroundColor: Colors.amber,
              tooltip: tr('scan_qr'),
              child: const Icon(Icons.qr_code_scanner),
            ),
          ),

          // Carrusel de tarjetas de Lugares
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SizedBox(
              height: _cardHeight + 20,
              child: Column(
                children: [
                  SizedBox(
                    height: _cardHeight,
                    child: _lugares.isEmpty && _currentPosition != null
                        ? Container(
                            width: double.infinity,
                            height: _cardHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                "No hay lugares en un radio de 5 km",
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold),
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
                                'assets/img/insiginia.png',
                                place.nombre,
                                'Rating: ${place.rating?.toStringAsFixed(1) ?? 'N/A'}',
                                index + 1,
                              );
                            }).toList(),
                          ),
                  ),

                  // Indicadores de página
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
                            color: _currentPage == index
                                ? theme.colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.5),
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

  // Método para construir cada tarjeta
  Widget _buildCard(
      String imagePath, String title, String subtitle, int cardNumber) {
    // Buscamos el lugar por índice dentro de la lista _lugares (filtrada)
    final place = _lugares[cardNumber - 1];

    // ⭐️ Lógica de bloqueo: La tarjeta está deshabilitada si hay una ruta activa
    final bool isDisabled = _isRouteActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Center(
        child: SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: Card(
            elevation: 4.0,
            // ⭐️ Color gris si está deshabilitada para indicar el bloqueo
            color: isDisabled ? Colors.grey[200] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: InkWell(
              onTap: isDisabled
                  ? () => _showSnackBar(
                      'Cancela la ruta actual (botón X) antes de iniciar una nueva.')
                  // Llama al modal de confirmación si no hay ruta activa
                  : () => _showStartTripConfirmation(place),
              borderRadius: BorderRadius.circular(12.0),
              splashColor: Colors.amber.withAlpha((255 * 0.3).round()),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: _imageWidth,
                      height: _cardHeight - 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: const Icon(Icons.image_not_supported),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDisabled ? Colors.black45 : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
