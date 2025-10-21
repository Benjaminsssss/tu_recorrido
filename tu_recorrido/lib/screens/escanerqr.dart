import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/estacion.dart';
import '../services/estacion_service.dart';
import '../services/qr_service.dart';
import '../services/auth_local_service.dart';
import '../utils/colores.dart';
import '../widgets/pantalla_base.dart';
import '../widgets/escaner_widgets.dart';
import '../widgets/escaner_dialogs.dart';

/// vista para escanear códigos QR de estaciones patrimoniales
/// Simula el escaneo y valida códigos contra la base de datos
class EscanerQRScreen extends StatefulWidget {
  const EscanerQRScreen({super.key});

  @override
  State<EscanerQRScreen> createState() => _EscanerQRScreenState();
}

class _EscanerQRScreenState extends State<EscanerQRScreen>
    with SingleTickerProviderStateMixin {
  final _codigoController = TextEditingController();
  
  bool _escaneando = false;
  bool _validando = false;
  bool _modoDemo = true; // Para alternar entre demo y escáner real
  Estacion? _estacionEncontrada;
  MobileScannerController? _scannerController;
  
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
    
    // Inicializar usuario mock para desarrollo
    _inicializarUsuario();
  }

  Future<void> _inicializarUsuario() async {
    await AuthLocalService.inicializarUsuarioPorDefecto();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _animationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  /// Verificar si el usuario está autenticado
  Future<bool> _verificarAutenticacion() async {
    final usuario = await AuthLocalService.obtenerUsuarioActual();
    if (usuario == null) {
      if (mounted) {
        EscanerHelper.mostrarMensaje(
          context,
          'Debes estar logueado para escanear QR',
          Coloressito.badgeRed,
        );
      }
      return false;
    }
    return true;
  }

  /// Alternar entre modo demo y escáner real
  void _alternarModo() {
    setState(() {
      _modoDemo = !_modoDemo;
      _estacionEncontrada = null;
    });
  }

  /// Método principal para iniciar escaneo
  Future<void> _iniciarEscaneo() async {
    // Verificar autenticación primero
    final autenticado = await _verificarAutenticacion();
    if (!autenticado) return;

    if (_modoDemo) {
      await _simularEscaneo();
    } else {
      await _escaneoReal();
    }
  }

  /// Simula los qr para desarrollo
  Future<void> _simularEscaneo() async {
    setState(() {
      _escaneando = true;
      _estacionEncontrada = null;
    });

    // Simula el tiempo de escaneo
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _escaneando = false);
      _mostrarDialogCodigo();
    }
  }

  /// Escaneo real con cámara
  Future<void> _escaneoReal() async {
    setState(() {
      _escaneando = true;
      _estacionEncontrada = null;
    });

    _mostrarEscanerReal();
  }

  /// escáner real con cámara
  void _mostrarEscanerReal() {
    _scannerController = MobileScannerController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Escanear QR'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
                _scannerController?.dispose();
                setState(() => _escaneando = false);
              },
            ),
          ),
          body: MobileScanner(
            controller: _scannerController,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _procesarCodigoEscaneado(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }

  /// Callback cuando se crea la vista del QR - ya no se necesita con mobile_scanner
  /// Procesar código escaneado desde cámara
  Future<void> _procesarCodigoEscaneado(String codigo) async {
    // Cerrar el escáner
    Navigator.of(context).pop();
    
    // Validar y procesar el código
    await _validarCodigo(codigo);
  }

  /// Mostrar dialog para ingresar código manualmente
  void _mostrarDialogCodigo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogCodigoQR(
        controller: _codigoController,
        onValidar: _validarCodigo,
      ),
    );
  }

  /// Valida el código de estación en Firestore
  Future<void> _validarCodigo(String codigo) async {
    if (codigo.isEmpty) {
      EscanerHelper.mostrarMensaje(
        context,
        'Código vacío',
        Coloressito.badgeRed,
      );
      return;
    }

    setState(() => _validando = true);

    try {
      // Verificar si es un código QR válido primero
      if (QRService.esCodigoValido(codigo)) {
        final estacion = await EstacionService.obtenerPorCodigoQR(codigo);
        if (mounted) {
          setState(() => _estacionEncontrada = estacion);
          if (estacion != null) {
            _mostrarEstacionEncontrada(estacion);
          } else {
            EscanerHelper.mostrarMensaje(
              context,
              'Código QR no válido o estación inactiva',
              Coloressito.badgeRed,
            );
          }
        }
      } else {
        // Intentar con código legacy
        final estacion = await EstacionService.obtenerPorCodigo(codigo);
        if (mounted) {
          setState(() => _estacionEncontrada = estacion);
          if (estacion != null) {
            _mostrarEstacionEncontrada(estacion);
          } else {
            EscanerHelper.mostrarMensaje(
              context,
              'Código no reconocido. Verifica que sea un QR de Tu Recorrido',
              Coloressito.badgeRed,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        EscanerHelper.mostrarMensaje(
          context,
          'Error al validar: $e',
          Coloressito.badgeRed,
        );
      }
    } finally {
      if (mounted) setState(() => _validando = false);
    }
  }

  /// Mostrar información de estación encontrada
  void _mostrarEstacionEncontrada(Estacion estacion) {
    showDialog(
      context: context,
      builder: (context) => DialogEstacionEncontrada(
        estacion: estacion,
        onMarcarVisitada: () => _marcarComoVisitada(estacion),
      ),
    );
  }

  /// Marcar estación como visitada
  Future<void> _marcarComoVisitada(Estacion estacion) async {
    await EscanerHelper.marcarComoVisitada(
      estacion,
      (mensaje, color) => EscanerHelper.mostrarMensaje(context, mensaje, color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Escanear Estación',
      actions: [
        // Botón para alternar modo
        IconButton(
          icon: Icon(_modoDemo ? Icons.camera_alt : Icons.edit),
          tooltip: _modoDemo ? 'Cambiar a escáner real' : 'Cambiar a modo demo',
          onPressed: _alternarModo,
        ),
        // Botón para ir al generador QR
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          tooltip: 'Generar QR (Admin)',
          onPressed: () {
            Navigator.pushNamed(context, '/admin/generador-qr');
          },
        ),
      ],
      body: Column(
        children: [
          // Indicador de modo actual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _modoDemo ? Colors.orange[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _modoDemo ? Colors.orange : Colors.green,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _modoDemo ? Icons.edit : Icons.camera_alt,
                  color: _modoDemo ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  _modoDemo 
                    ? 'Modo Demo: Ingresa código manualmente'
                    : 'Modo Real: Usa la cámara para escanear',
                  style: TextStyle(
                    color: _modoDemo ? Colors.orange[800] : Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MarcoEscaneo(
                    escaneando: _escaneando,
                    pulseAnimation: _pulseAnimation,
                  ),
                  const SizedBox(height: 32),
                  TextoInstructivo(
                    escaneando: _escaneando, 
                    validando: _validando,
                  ),
                  const SizedBox(height: 48),
                  BotonEscaneo(
                    escaneando: _escaneando,
                    validando: _validando,
                    onPressed: _iniciarEscaneo,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón para alternar modo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _modoDemo ? 'Modo Demo' : 'Escáner Real',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: !_modoDemo,
                        onChanged: (value) => _alternarModo(),
                        activeTrackColor: Coloressito.primary,
                      ),
                    ],
                  ),
                  
                  if (_estacionEncontrada != null) ...[
                    const SizedBox(height: 24),
                    UltimaEstacionVisitada(estacion: _estacionEncontrada!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
