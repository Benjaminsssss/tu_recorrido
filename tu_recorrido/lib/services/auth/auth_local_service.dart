import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar autenticación local (mock)
/// Para desarrollo y testing sin Firebase Auth
class AuthLocalService {
  static const String _keyUserId = 'mock_user_id';
  static const String _keyUserName = 'mock_user_name';
  static const String _keyUserEmail = 'mock_user_email';
  static const String _keyIsLoggedIn = 'mock_is_logged_in';

  /// Usuario mock por defecto
  static const String _defaultUserId = 'user_dev_123';
  static const String _defaultUserName = 'Usuario Desarrollo';
  static const String _defaultUserEmail = 'dev@turecorrido.com';

  /// Verificar si hay un usuario logueado
  static Future<bool> estaLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Obtener información del usuario actual
  static Future<Map<String, String>?> obtenerUsuarioActual() async {
    final prefs = await SharedPreferences.getInstance();
    final estaLogueado = prefs.getBool(_keyIsLoggedIn) ?? false;

    if (!estaLogueado) return null;

    return {
      'id': prefs.getString(_keyUserId) ?? _defaultUserId,
      'nombre': prefs.getString(_keyUserName) ?? _defaultUserName,
      'email': prefs.getString(_keyUserEmail) ?? _defaultUserEmail,
    };
  }

  /// Login del usuario mock
  static Future<void> loginMock({
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyUserId, userId ?? _defaultUserId);
    await prefs.setString(_keyUserName, userName ?? _defaultUserName);
    await prefs.setString(_keyUserEmail, userEmail ?? _defaultUserEmail);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  /// Logout del usuario
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Inicializar usuario por defecto si no existe
  static Future<void> inicializarUsuarioPorDefecto() async {
    final estaLogueado = await AuthLocalService.estaLogueado();
    if (!estaLogueado) {
      await loginMock();
    }
  }

  /// Obtener ID del usuario actual
  static Future<String?> obtenerIdUsuario() async {
    final usuario = await obtenerUsuarioActual();
    return usuario?['id'];
  }
}