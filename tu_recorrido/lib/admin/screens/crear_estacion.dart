import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

      final estacion = Estacion(
        id: '', // Se genera automáticamente
        codigo: codigo,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        latitud: _ubicacionActual!.latitude,
        longitud: _ubicacionActual!.longitude,
        fechaCreacion: DateTime.now(),
      );

      await EstacionService.crearEstacion(estacion);

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
              hint: 'Cuéntanos sobre la importancia histórica de este lugar...',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Agrega una descripción del lugar';
                }
                return null;
              },
            ),
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
