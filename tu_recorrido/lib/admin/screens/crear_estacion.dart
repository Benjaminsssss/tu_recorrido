import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'seleccionar_punto_map.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';
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
  final _comunaController = TextEditingController();
  final _descripcionCardController = TextEditingController();

  bool _cargando = false;
  // Puede ser un Position (cuando usamos Geolocator) o un objeto con latitude/longitude (LatLng)
  dynamic _ubicacionActual;
  final ImagePicker _picker = ImagePicker();
  
  // Badge/insignia para la estación patrimonial
  XFile? _pickedBadge;
  Uint8List? _pickedBadgeBytes;
  
  // Imágenes para el card/lugar (múltiples)
  List<XFile> _pickedCardImages = [];
  List<Uint8List?> _pickedCardImagesBytes = [];

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _comunaController.dispose();
    _descripcionCardController.dispose();
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

      // Crear estación patrimonial y obtener el id generado
      final newId = await EstacionService.crearEstacion(estacion);

      // AHORA TAMBIÉN CREAR EL LUGAR/CARD EN FIRESTORE (colección estaciones)
      final nombreCard = _nombreController.text.trim();
      final cardId = await FirestoreService.instance.createPlace(
        name: nombreCard, 
        lat: _ubicacionActual!.latitude, 
        lng: _ubicacionActual!.longitude,
        category: 'patrimonio',
        country: 'Chile',
        city: 'Santiago', // Podrías hacer esto configurable
      );

      // Actualizar datos adicionales del card
      final comuna = _comunaController.text.trim();
      final descripcionCard = _descripcionCardController.text.trim();
      await FirestoreService.instance.updatePlacePartial(placeId: cardId, data: {
        'comuna': comuna.isNotEmpty ? comuna : '',
        'descripcion': descripcionCard,
        'shortDesc': descripcionCard.isNotEmpty ? (descripcionCard.length > 120 ? '${descripcionCard.substring(0, 120)}...' : descripcionCard) : '',
        'mejorMomento': '',
        'estacionId': newId, // Enlazar el card con la estación patrimonial
      });

      // Subir imágenes del card (múltiples)
      if (_pickedCardImages.isNotEmpty) {
        final toUpload = _pickedCardImages.take(5).toList();
        for (var idx = 0; idx < toUpload.length; idx++) {
          final picked = toUpload[idx];
          final ts = DateTime.now().millisecondsSinceEpoch;
          final ext = kIsWeb ? _getExt(picked.name) : _getExt(picked.path);
          final cardImagePath = 'estaciones/$cardId/img_$ts$ext';
          try {
            String cardImageUrl;
            if (kIsWeb && idx < _pickedCardImagesBytes.length && _pickedCardImagesBytes[idx] != null) {
              cardImageUrl = await StorageService.instance.uploadBytes(_pickedCardImagesBytes[idx]!, cardImagePath, contentType: 'image/jpeg');
            } else {
              final file = File(picked.path);
              cardImageUrl = await StorageService.instance.uploadFile(file, cardImagePath, contentType: 'image/jpeg');
            }
            final imageObj = {'url': cardImageUrl, 'path': cardImagePath, 'alt': nombreCard};
            await FirestoreService.instance.addPlaceImage(placeId: cardId, image: imageObj);
          } catch (e) {
            debugPrint('Error subiendo imagen $idx del card: $e');
            continue;
          }
        }
      }

      // Si el admin escogió una insignia para la estación patrimonial, subirla
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

      if (mounted) {
        _mostrarExito('Estación patrimonial y lugar/card creados exitosamente.\nCódigo: $codigo');
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

  /// Seleccionar múltiples imágenes para el card
  Future<void> _pickCardImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked == null || picked.isEmpty) return;

    final remaining = 5 - _pickedCardImages.length;
    if (remaining <= 0) return;
    final toTake = picked.take(remaining).toList();

    if (kIsWeb) {
      final List<Uint8List?> bytesList = [];
      for (final p in toTake) {
        try {
          bytesList.add(await p.readAsBytes());
        } catch (_) {
          bytesList.add(null);
        }
      }
      setState(() {
        _pickedCardImages = [..._pickedCardImages, ...toTake];
        _pickedCardImagesBytes = [..._pickedCardImagesBytes, ...bytesList];
      });
    } else {
      setState(() {
        _pickedCardImages = [..._pickedCardImages, ...toTake];
        _pickedCardImagesBytes = [..._pickedCardImagesBytes, ...List<Uint8List?>.filled(toTake.length, null)];
      });
    }
  }

  /// Seleccionar insignia/badge para la estación patrimonial
  Future<void> _pickBadge() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    
    setState(() {
      _pickedBadge = picked;
    });
    
    if (kIsWeb) {
      try {
        _pickedBadgeBytes = await picked.readAsBytes();
      } catch (e) {
        debugPrint('Error leyendo bytes de badge: $e');
      }
    }
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _descripcionController.clear();
    _comunaController.clear();
    _descripcionCardController.clear();
    _formKey.currentState?.reset();
    setState(() {
      _pickedBadge = null;
      _pickedBadgeBytes = null;
      _pickedCardImages = [];
      _pickedCardImagesBytes = [];
    });
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
              const SizedBox(height: 24),
              // Separador visual
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              const Text(
                'Información para el Card/Lugar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              CampoFormulario(
                controller: _comunaController,
                label: 'Comuna',
                hint: 'Ej: Santiago, Las Condes, Providencia...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la comuna donde se ubica';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CampoFormulario(
                controller: _descripcionCardController,
                label: 'Descripción del card',
                hint: 'Descripción breve que aparecerá en la pantalla principal...',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Agrega una descripción para el card';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Selector de imágenes del card
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickCardImages,
                      icon: const Icon(Icons.photo_library),
                      label: Text('Imágenes del card (${_pickedCardImages.length})'),
                    ),
                  ),
                ],
              ),
              if (_pickedCardImages.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedCardImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        height: 100,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb && _pickedCardImagesBytes[index] != null
                                  ? Image.memory(
                                      _pickedCardImagesBytes[index]!,
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    )
                                  : Image.file(
                                      File(_pickedCardImages[index].path),
                                      fit: BoxFit.cover,
                                      width: 100,
                                      height: 100,
                                    ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _pickedCardImages.removeAt(index);
                                    _pickedCardImagesBytes.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Separador visual
              const Divider(thickness: 2),
              const SizedBox(height: 12),
              // Selector de insignia (badge)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickBadge,
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
              // Botones para seleccionar ubicación: mapa o usar ubicación actual
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Abrir pantalla de mapa para seleccionar punto
                        final LatLng? selected = await Navigator.of(context).push<LatLng>(
                          MaterialPageRoute(builder: (_) => SeleccionarPuntoMap(initialLocation: _ubicacionActual != null ? LatLng(_ubicacionActual!.latitude, _ubicacionActual!.longitude) : null)),
                        );
                        if (selected != null) {
                          // Guardar como LatLng (InfoUbicacion acepta objetos con latitude/longitude)
                          setState(() {
                            _ubicacionActual = LatLng(selected.latitude, selected.longitude);
                          });
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Seleccionar en mapa'),
                    ),
                  ),
                  // Se eliminó el botón de "Usar mi ubicación" según solicitud.
                ],
              ),
              const SizedBox(height: 12),
              // Las imágenes para el card se gestionan desde la pantalla de gestión de lugares.
              const SizedBox(height: 4),
              const SizedBox(height: 12),
              const SizedBox(height: 16),
              InfoUbicacion(ubicacion: _ubicacionActual),
              const SizedBox(height: 32),
              BotonAccion(
                texto: 'Crear Estación Patrimonial y Card',
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
