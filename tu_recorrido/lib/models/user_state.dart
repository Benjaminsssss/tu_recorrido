import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _nombre;
  String? _avatarUrl;
  User? _user;

  UserState({required String nombre, String? avatarUrl})
      : _nombre = nombre,
        _avatarUrl = avatarUrl {
    _loadFromPrefs();
    _initAuthListener();
  }

  String get nombre => _nombre;
  String? get avatarUrl => _avatarUrl;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

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
