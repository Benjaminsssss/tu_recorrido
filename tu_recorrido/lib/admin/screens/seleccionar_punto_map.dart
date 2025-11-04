import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Vista para seleccionar un punto en el mapa.
/// Devuelve un [LatLng] cuando el usuario confirma la selección.
class SeleccionarPuntoMap extends StatefulWidget {
  final LatLng? initialLocation;

  const SeleccionarPuntoMap({super.key, this.initialLocation});

  @override
  State<SeleccionarPuntoMap> createState() => _SeleccionarPuntoMapState();
}

class _SeleccionarPuntoMapState extends State<SeleccionarPuntoMap> {
  LatLng? _selected;
  late CameraPosition _initialCamera;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    final defaultPos = LatLng(-33.4489, -70.6693); // Santiago por defecto
    final start = widget.initialLocation ?? defaultPos;
    _initialCamera = CameraPosition(target: start, zoom: 15);
    if (widget.initialLocation != null) {
      _selected = widget.initialLocation;
      _markers.add(
          Marker(markerId: const MarkerId('selected'), position: _selected!));
    }
  }

  void _onTap(LatLng pos) {
    setState(() {
      _selected = pos;
      _markers.clear();
      _markers.add(Marker(markerId: const MarkerId('selected'), position: pos));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCamera,
            onTap: _onTap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 20,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selected == null
                        ? null
                        : () {
                            Navigator.of(context).pop(_selected);
                          },
                    child: const Text('Confirmar ubicación'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
