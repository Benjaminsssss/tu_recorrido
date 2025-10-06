import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tu_recorrido/screens/perfil.dart';


//simple creacion de la clase del mapa y es un stateful widget
//por que va a cambiar conforme se mueva el usuario
class Mapita extends StatefulWidget {
  const Mapita({super.key});

  @override
  State<Mapita> createState() => _Mapita();
}


//clase que maneja el estado del mapa
class _Mapita extends State<Mapita> {
  //creamos un controlador para el mapa
  final Completer<GoogleMapController> _controller = Completer();
  //esta variable va a manejar la subscripcion al stream de ubicacion
  //Es decir que va a escuchar los cambios en la ubicacion del usuario
  StreamSubscription<Position>? _positionStreamSubscription;
  
  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(-33.517429163590734, -70.5980614832371), //mall por ahora, aqui deberia tener la ubicacion inicial del usuario
    zoom: 14.0,// el zoom inicial del mapa
  );


//se crea un final set de marcadores
//aqui deberian estar todos los puntos de interes que se quieran mostrar en el mapa
//esto posterioemente estara en una base de datos o en un archivo externo o en una api
  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('DuocUC'),
      position: LatLng(-33.50000015510835, -70.6159570814609),
      infoWindow: InfoWindow(
        title: 'Duoc uc san joaquin',
        snippet: 'Punto de interés fijo',
      ),
    ),
  };

// metodo initState que se llama cuando el widget es insertado en el arbol de widgets
  @override
  void initState() {
    super.initState();
    _listenForLocationUpdates();
  }

//el dispose es para limpiar la subscripcion al stream de ubicacion
  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }


//creamo un meotodo prara escuchar las actualizaciones de ubicacion
//es  decir el metodo que va a mover el "punto azul" del usuario
//y que ademas va a centrar la camara en la ubicacion inicial del usuario
  Future<void> _listenForLocationUpdates() async {
    bool serviceEnabled;
    LocationPermission permission;

    //aqui se verifica si los servicios de ubicacion estan habilitados
    //y si los permisos de ubicacion han sido otorgados
    //si no es asi se solicitan o lanza un mensaje de error
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    //permiso de ubicacion
    if (!serviceEnabled) {
      
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }
    //permiso de geolocalizacion
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        
        return Future.error('Los permisos de ubicación fueron denegados.');
      }
    }
    //Permiso denegado permanentemente
    if (permission == LocationPermission.deniedForever) {

      return Future.error('Los permisos de ubicación están permanentemente denegados, no podemos solicitar más.');
    }

    //aqui se obtiene la ubicacion inicial del usuario y se centra la camara en esa ubicacion
    try {
      Position initialPosition = await Geolocator.getCurrentPosition();
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(initialPosition.latitude, initialPosition.longitude),
        ),
      );
    } catch (e) {
      // Manejar el error de obtener la ubicación, por ejemplo si el GPS está apagado.
      debugPrint("Error al obtener la ubicación inicial: $e");
    }

    //este comando es el que escucha los cambios en la ubicacion del usuario
    //es decir, cada vez que el usuario se mueva, este metodo se va a ejecutar
    //para actualizar la ubicacion del "punto azul" y centrar la camara en la nueva ubicacion
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (Position position) async {
      },
      onError: (e) {
        debugPrint("Error en el stream de ubicación: $e");
      },
    );
  }
//creacion basica del widget
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntos de Interés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  Perfil()),//nos lleva a la pantalla de perfil
              );
            },
          ),
        ],
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _defaultCameraPosition,//posicion inicial del mapa
        onMapCreated: (GoogleMapController controller) {//cuando el mapa es creado se completa el controlador
          _controller.complete(controller);//completamos el controlador del mapa
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
      ),
    );
  }
}