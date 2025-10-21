import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserState extends ChangeNotifier {
  String _nombre;
  String? _avatarUrl;

  UserState({required String nombre, String? avatarUrl})
      : _nombre = nombre,
        _avatarUrl = avatarUrl {
    _loadFromPrefs();
  }

  String get nombre => _nombre;
  String? get avatarUrl => _avatarUrl;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _nombre = prefs.getString('user_nombre') ?? _nombre;
    _avatarUrl = prefs.getString('user_avatarUrl') ?? _avatarUrl;
    notifyListeners();
  }

  Future<void> setNombre(String nuevoNombre) async {
    _nombre = nuevoNombre;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nombre', nuevoNombre);
    notifyListeners();
  }

  Future<void> setAvatarUrl(String? url) async {
    _avatarUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString('user_avatarUrl', url);
    } else {
      await prefs.remove('user_avatarUrl');
    }
    notifyListeners();
  }
}
