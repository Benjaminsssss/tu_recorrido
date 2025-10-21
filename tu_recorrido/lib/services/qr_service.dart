import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Servicio para generar y validar códigos QR únicos para lugares
/// Genera códigos seguros y únicos para cada estación
class QRService {
  /// Formato: "TR_[HASH_ESTACION]_[TIMESTAMP]"
  /// Ejemplo: "TR_ABC123_1640995200"
  static String generarCodigoQR(String estacionId, String nombre) {
    // Crear un hash único basado en la estación
    final input = '$estacionId-$nombre-${DateTime.now().millisecondsSinceEpoch}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    
    // Tomar los primeros 8 caracteres del hash
    final hashCorto = digest.toString().substring(0, 8).toUpperCase();
    
    // Timestamp para unicidad
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    return 'TR_${hashCorto}_$timestamp';
  }

  /// Valida el formato de un código QR
  /// Debe seguir el patrón: TR_[8_CHARS]_[TIMESTAMP]
  static bool esCodigoValido(String codigo) {
    final regex = RegExp(r'^TR_[A-Z0-9]{8}_\d{10}$');
    return regex.hasMatch(codigo);
  }

  /// Extrae información del código QR
  static Map<String, dynamic> extraerInfoCodigo(String codigo) {
    if (!esCodigoValido(codigo)) {
      throw ArgumentError('Código QR inválido: $codigo');
    }

    final partes = codigo.split('_');
    final hash = partes[1];
    final timestamp = int.parse(partes[2]);
    final fecha = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return {
      'hash': hash,
      'timestamp': timestamp,
      'fecha': fecha,
      'esValido': true,
    };
  }

  /// Genera un código de respaldo en caso de error
  static String generarCodigoRespaldo() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final randomStr = random.nextInt(99999999).toString().padLeft(8, '0');
    
    return 'TR_${randomStr.substring(0, 8)}_$timestamp';
  }

  /// Valida que el código no sea muy antiguo
  static bool esCodiigoReciente(String codigo, {int diasMaximos = 365}) {
    try {
      final info = extraerInfoCodigo(codigo);
      final fecha = info['fecha'] as DateTime;
      final diferencia = DateTime.now().difference(fecha).inDays;
      
      return diferencia <= diasMaximos;
    } catch (e) {
      return false;
    }
  }
}