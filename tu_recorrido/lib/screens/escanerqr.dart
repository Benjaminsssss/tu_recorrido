import 'package:flutter/material.dart';
import '../models/estacion.dart';
import '../services/estacion_service.dart';
import '../services/qr_service.dart';
import '../services/auth_local_service.dart';
import '../widgets/pantalla_base.dart';

/// Escáner QR solo modo manual
class EscanerQRScreen extends StatefulWidget {
  const EscanerQRScreen({super.key});

  @override
  State<EscanerQRScreen> createState() => _EscanerQRScreenState();
}

class _EscanerQRScreenState extends State<EscanerQRScreen> {
  final _codigoController = TextEditingController();
  
  bool _validando = false;
  Estacion? _estacionEncontrada;
  String? _mensajeError;

  @override
  Widget build(BuildContext context) {
    return PantallaBase(
      titulo: 'Escanear QR',
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Instrucciones
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.blue),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Instrucciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Ingresa manualmente el código QR de la estación que quieres visitar.',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Campo de entrada de código QR
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código QR',
                hintText: 'Ingresa el código QR aquí',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                errorText: _mensajeError,
              ),
              onChanged: (value) {
                if (_mensajeError != null) {
                  setState(() {
                    _mensajeError = null;
                  });
                }
              },
            ),
            
            const SizedBox(height: 20),
            
            // Botón de validación
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validando ? null : _validarCodigoQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _validando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('Validando...'),
                        ],
                      )
                    : const Text(
                        'Validar Código QR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Información de la estación encontrada
            if (_estacionEncontrada != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Estación Encontrada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nombre: ${_estacionEncontrada!.nombre}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_estacionEncontrada!.descripcion.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Descripción: ${_estacionEncontrada!.descripcion}'),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _registrarVisita(_estacionEncontrada!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Registrar Visita'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _validarCodigoQR() async {
    final codigo = _codigoController.text.trim();
    
    if (codigo.isEmpty) {
      setState(() {
        _mensajeError = 'Ingresa un código QR';
      });
      return;
    }

    setState(() {
      _validando = true;
      _mensajeError = null;
      _estacionEncontrada = null;
    });

    try {
      // Buscar la estación por código QR
      final estacion = await EstacionService.obtenerPorCodigoQR(codigo);
      
      if (estacion != null) {
        setState(() {
          _estacionEncontrada = estacion;
        });
      } else {
        setState(() {
          _mensajeError = 'Código QR no válido o estación no encontrada';
        });
      }
    } catch (e) {
      setState(() {
        _mensajeError = 'Error al validar código: $e';
      });
    } finally {
      setState(() {
        _validando = false;
      });
    }
  }

  Future<void> _registrarVisita(Estacion estacion) async {
    try {
      final usuario = await AuthLocalService.obtenerUsuarioActual();
      if (usuario == null) {
        _mostrarError('Usuario no autenticado');
        return;
      }

      // Por ahora solo mostrar éxito sin registrar en Firestore
      if (mounted) {
        // Mostrar diálogo de éxito simple
        _mostrarExito(estacion);
      }
    } catch (e) {
      _mostrarError('Error al registrar visita: $e');
    }
  }

  void _mostrarExito(Estacion estacion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 30),
            SizedBox(width: 10),
            Text('¡Éxito!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Has visitado: ${estacion.nombre}'),
            const SizedBox(height: 8),
            if (estacion.descripcion.isNotEmpty)
              Text(
                estacion.descripcion,
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _estacionEncontrada = null;
                _codigoController.clear();
              });
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }
}