import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/estacion.dart';
import '../services/estacion_service.dart';
import '../services/coleccion_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/insignia_service.dart';
import 'package:geolocator/geolocator.dart';

/// vista para escanear códigos QR de estaciones patrimoniales
class EscanerQRScreen extends StatefulWidget {
  const EscanerQRScreen({super.key});

  @override
  State<EscanerQRScreen> createState() => _EscanerQRScreenState();
}

class _EscanerQRScreenState extends State<EscanerQRScreen>
    with SingleTickerProviderStateMixin {
  // ⭐ Paleta de colores actualizada
  static const Color colorAmarillo = Color(0xFFF7DF3E);
  static const Color colorVerdeOliva = Color(0xFFA2AD4E);
  static const Color colorVerdeEsmeralda = Color(0xFF43A78A);
  static const Color colorAzulPetroleo = Color(0xFF264E59);
  static const Color colorGrisCarbon = Color(0xFF2E2F32);

  final _codigoController = TextEditingController();
  bool _escaneando = false;
  bool _validando = false;
  bool _handlingScan = false;
  Estacion? _estacionEncontrada;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// ⭐ Abre el escáner de QR real con la cámara (SIN botón de galería)
  Future<void> _abrirEscanerQR() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: colorAzulPetroleo,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Escanear Código QR',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: Stack(
            children: [
              // ⭐ Escáner de mobile_scanner (sin botón de galería)
              MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.noDuplicates,
                  facing: CameraFacing.back,
                ),
                onDetect: (BarcodeCapture capture) async {
                  if (_handlingScan) return;
                  final String? code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
                  if (code == null || code.isEmpty) return;

                  _handlingScan = true;
                  debugPrint("📷 Código QR detectado: $code");

                  // Cerrar la pantalla del escáner de forma segura
                  try {
                    if (Navigator.canPop(context)) Navigator.of(context).pop();
                  } catch (e) {
                    debugPrint('Error al cerrar el escáner: $e');
                  }

                  await Future.delayed(const Duration(milliseconds: 250));

                  if (mounted) {
                    try {
                      await _validarCodigo(code);
                    } catch (e) {
                      debugPrint('Error validando código: $e');
                    }
                  }
                },
              ),
              
              // ⭐ Marco de escaneo personalizado
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorAmarillo,
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              
              // ⭐ Instrucciones en la parte inferior
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        colorAzulPetroleo.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: colorAmarillo, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Coloca el código QR en el marco',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'El escaneo se realizará automáticamente',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ⭐ Muestra opciones de escaneo
  void _mostrarOpcionesEscaneo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '¿Cómo deseas escanear?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorAzulPetroleo,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorVerdeEsmeralda.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.qr_code_scanner, color: colorVerdeEsmeralda, size: 28),
              ),
              title: const Text('Escanear con cámara', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Usa la cámara para escanear el código QR'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _abrirEscanerQR();
              },
            ),
            const Divider(height: 32),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorVerdeOliva.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.keyboard, color: colorVerdeOliva, size: 28),
              ),
              title: const Text('Ingresar código manualmente', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Escribe el código de la estación'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _mostrarDialogCodigo();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Dialog para ingresar código manualmente
  void _mostrarDialogCodigo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorVerdeOliva.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.vpn_key, color: colorVerdeOliva),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Ingresar Código')),
          ],
        ),
        content: TextField(
          controller: _codigoController,
          decoration: InputDecoration(
            labelText: 'Código de estación',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorVerdeEsmeralda, width: 2),
            ),
            prefixIcon: Icon(Icons.tag, color: colorVerdeOliva),
          ),
          autofocus: true,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _codigoController.clear();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: colorGrisCarbon),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorVerdeEsmeralda,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _validarCodigo(_codigoController.text);
            },
            child: const Text('Validar'),
          ),
        ],
      ),
    );
  }

  /// Valida el código en Firestore
  Future<void> _validarCodigo(String codigo) async {
    if (codigo.isEmpty) {
      _mostrarMensaje('⚠️ Código vacío', colorAmarillo);
      return;
    }

    setState(() => _validando = true);

    try {
      final estacion = await EstacionService.obtenerPorCodigo(codigo);
      if (mounted) {
        setState(() => _estacionEncontrada = estacion);
        if (estacion != null) {
          _mostrarEstacionEncontrada(estacion);
        } else {
          _mostrarMensaje('❌ Código no válido o estación inactiva', Colors.redAccent);
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('❌ Error al validar: $e', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  /// Mostrar información de estación encontrada
  void _mostrarEstacionEncontrada(Estacion estacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorVerdeEsmeralda.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: colorVerdeEsmeralda, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                estacion.nombre,
                style: TextStyle(fontSize: 18, color: colorAzulPetroleo),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorAmarillo.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorAmarillo.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.vpn_key, size: 20, color: colorVerdeOliva),
                  const SizedBox(width: 8),
                  Text(
                    'Código: ${estacion.codigo}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorGrisCarbon,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (estacion.descripcion.isNotEmpty)
              Text(
                estacion.descripcion,
                style: TextStyle(fontSize: 14, color: colorAzulPetroleo),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: colorGrisCarbon),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorVerdeEsmeralda,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _marcarComoVisitada(estacion);
            },
            icon: const Icon(Icons.check, size: 20),
            label: const Text('Marcar visitada'),
          ),
        ],
      ),
    );
  }

  /// Marcar estación como visitada
  Future<void> _marcarComoVisitada(Estacion estacion) async {
    if (!mounted) return;

    setState(() => _validando = true);

    double? lat;
    double? lon;

    // Intentar obtener la posición actual (opcional)
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
          // no hay permiso, continuar sin coordenadas
        }
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium).timeout(const Duration(seconds: 5));
      lat = pos.latitude;
      lon = pos.longitude;
    } catch (_) {
      // ignorar errores de geolocalización y continuar
    }

    try {
      await ColeccionService.marcarComoVisitada(estacion, latitudUsuario: lat, longitudUsuario: lon);
      if (mounted) {
        setState(() => _estacionEncontrada = estacion);
        _mostrarMensaje('✅ Estación ${estacion.nombre} marcada como visitada', colorVerdeEsmeralda);
      }
      // ----- Chequear insignia asignada a la estación y otorgarla -----
      try {
        if (estacion.insigniaID != null) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final uid = currentUser.uid;
            final insigniaId = estacion.insigniaID!.id;

            // Evitar duplicados: comprobar si el usuario ya tiene la insignia
            final tiene = await InsigniaService.usuarioTieneInsignia(userId: uid, insigniaId: insigniaId);
            if (tiene) {
              if (mounted) _mostrarMensaje('ℹYa tienes la insignia de esta estación', Colors.blueGrey);
            } else {
              await InsigniaService.otorgarInsigniaAUsuario(userId: uid, insigniaId: insigniaId, estacionId: estacion.id);
              if (mounted) _mostrarMensaje('¡Has obtenido la insignia "${estacion.nombre}"!', colorAmarillo);
            }
          } else {
            // Usuario no autenticado: no se puede otorgar ahora
            if (mounted) _mostrarMensaje('ℹInicia sesión para recibir insignias', Colors.orange);
          }
        } else {
          // No hay insignia asignada a la estación
        }
      } catch (e) {
        // Si falla (p.ej. offline), avisar y no bloquear la UX. Podríamos encolar para reintento.
        if (mounted) _mostrarMensaje('No se pudo otorgar la insignia ahora: $e', Colors.orange);
      }
    } catch (e) {
      if (mounted) {
        _mostrarMensaje('Error al marcar visitada: ${e.toString()}', Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  /// Mostrar SnackBar
  void _mostrarMensaje(String mensaje, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Estación'),
        backgroundColor: colorAzulPetroleo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorAzulPetroleo.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _escaneando ? colorVerdeEsmeralda : colorVerdeOliva.withOpacity(0.5),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (_escaneando ? colorVerdeEsmeralda : colorVerdeOliva).withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 120,
                      color: _escaneando ? colorVerdeEsmeralda : colorVerdeOliva,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  _escaneando
                      ? 'Escaneando...'
                      : _validando
                          ? 'Validando código...'
                          : 'Presiona el botón para escanear',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorAzulPetroleo,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: _escaneando || _validando ? null : _mostrarOpcionesEscaneo,
                  icon: _validando
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.qr_code_scanner, size: 28),
                  label: Text(
                    _validando ? 'Validando...' : 'Escanear QR',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorVerdeEsmeralda,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                    shadowColor: colorVerdeEsmeralda.withOpacity(0.5),
                  ),
                ),
                if (_estacionEncontrada != null) ...[
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorVerdeEsmeralda.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorVerdeEsmeralda.withOpacity(0.3), width: 2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: colorVerdeEsmeralda, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Última estación escaneada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorAzulPetroleo,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _estacionEncontrada!.nombre,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorGrisCarbon,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}