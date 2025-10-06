import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../services/estacion_service.dart';
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

  /// Simula los qr
  Future<void> _simularEscaneo() async {
    setState(() {
      _escaneando = true;
      _estacionEncontrada = null;
    });

    // Simula el tiempo de escaneo
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _escaneando = false);

      // Para demo, mostrar dialog para ingresar código manualmente
      _mostrarDialogCodigo();
    }
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
      final estacion = await EstacionService.obtenerPorCodigo(codigo);
      if (mounted) {
        setState(() => _estacionEncontrada = estacion);
        if (estacion != null) {
          _mostrarEstacionEncontrada(estacion);
        } else {
          EscanerHelper.mostrarMensaje(
            context,
            'Código no válido o estación inactiva',
            Coloressito.badgeRed,
          );
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MarcoEscaneo(
              escaneando: _escaneando,
              pulseAnimation: _pulseAnimation,
            ),

            const SizedBox(height: 32),

            TextoInstructivo(escaneando: _escaneando, validando: _validando),

            const SizedBox(height: 48),

            BotonEscaneo(
              escaneando: _escaneando,
              validando: _validando,
              onPressed: _simularEscaneo,
            ),

            if (_estacionEncontrada != null) ...[
              const SizedBox(height: 24),
              UltimaEstacionVisitada(estacion: _estacionEncontrada!),
            ],
          ],
        ),
      ),
    );
  }
}
