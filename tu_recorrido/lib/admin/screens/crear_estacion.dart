import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import '../../models/estacion.dart';
import '../../services/estacion_service.dart';
import '../../utils/colores.dart';
import '../../widgets/pantalla_base.dart';
import '../../widgets/role_protected_widget.dart';
import '../widgets/formulario_estacion.dart';

/// Pantalla para crear nuevas estaciones patrimoniales
/// Solo admin puede acceder
class CrearEstacionScreen extends StatefulWidget {
  const CrearEstacionScreen({super.key});

  @override
  State<CrearEstacionScreen> createState() => _CrearEstacionScreenState();
}

class _CrearEstacionScreenState extends State<CrearEstacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();

  bool _cargando = false;
  Position? _ubicacionActual;
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedBadge;
  Uint8List? _pickedBadgeBytes;
  // Nota: la subida de imágenes para el card se gestiona en otra vista.

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  /// Obtener ubicación GPS actual
  Future<void> _obtenerUbicacion() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _ubicacionActual = position;
        });
      }
    } catch (e) {
      debugPrint('Error obteniendo ubicación: $e');
    }
  }

  /// Crear nueva estación
  Future<void> _crearEstacion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ubicacionActual == null) {
      _mostrarError('No se pudo obtener la ubicación actual');
      return;
    }

    setState(() => _cargando = true);

    try {
      final codigo = EstacionService.generarCodigo(_nombreController.text);
      final codigoQR = ''; // Se generará automáticamente en el servicio

      final estacion = Estacion(
        id: '', // Se genera automáticamente
        codigo: codigo,
        codigoQR: codigoQR,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        latitud: _ubicacionActual!.latitude,
        longitud: _ubicacionActual!.longitude,
        fechaCreacion: DateTime.now(),
      );

      // Crear estación y obtener el id generado
      final newId = await EstacionService.crearEstacion(estacion);

      // Si el admin escogió una insignia, subirla y enlazarla al doc
      if (_pickedBadge != null) {
        final ts = DateTime.now().millisecondsSinceEpoch;
        final ext = kIsWeb ? _getExt(_pickedBadge!.name) : _getExt(_pickedBadge!.path);
        final path = 'insignias/$newId/badge_$ts$ext';
        String url;
        if (kIsWeb && _pickedBadgeBytes != null) {
          url = await StorageService.instance.uploadBytes(_pickedBadgeBytes!, path, contentType: 'image/jpeg');
        } else {
          final file = File(_pickedBadge!.path);
          url = await StorageService.instance.uploadFile(file, path, contentType: 'image/jpeg');
        }
        await EstacionService.setBadgeImage(newId, {'url': url, 'path': path, 'alt': _nombreController.text.trim()});
      }

      // La subida de imágenes para el card se realiza desde la pantalla de gestión de lugares.

      if (mounted) {
        _mostrarExito('Estación creada con código: $codigo');
        _limpiarFormulario();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  String _getExt(String path) {
    final idx = path.lastIndexOf('.');
    return idx >= 0 ? path.substring(idx) : '.jpg';
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _formKey.currentState?.reset();
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Coloressito.badgeRed),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Coloressito.adventureGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminProtectedWidget(
      child: PantallaBase(
        titulo: 'Crear Estación Patrimonial',
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EncabezadoEstacion(),
              const SizedBox(height: 24),
              CampoFormulario(
                controller: _nombreController,
                label: 'Nombre de la estación',
                hint: 'Ej: Plaza de Armas',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre de la estación';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CampoFormulario(
                controller: _descripcionController,
                label: 'Descripción histórica',
                hint:
                    'Cuéntanos sobre la importancia histórica de este lugar...',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Agrega una descripción del lugar';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Selector de insignia (badge)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (picked == null) return;
                        if (kIsWeb) {
                          final bytes = await picked.readAsBytes();
                          setState(() {
                            _pickedBadge = picked;
                            _pickedBadgeBytes = bytes;
                          });
                        } else {
                          setState(() {
                            _pickedBadge = picked;
                            _pickedBadgeBytes = null;
                          });
                        }
                      },
                      icon: const Icon(Icons.emoji_events),
                      label: const Text('Subir insignia (badge)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_pickedBadge != null)
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: kIsWeb && _pickedBadgeBytes != null
                          ? Image.memory(_pickedBadgeBytes!, fit: BoxFit.cover)
                          : Image.file(File(_pickedBadge!.path), fit: BoxFit.cover),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Las imágenes para el card se gestionan desde la pantalla de gestión de lugares.
              const SizedBox(height: 16),
              InfoUbicacion(ubicacion: _ubicacionActual),
              const SizedBox(height: 32),
              BotonAccion(
                texto: 'Crear Estación',
                onPressed: _crearEstacion,
                cargando: _cargando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
