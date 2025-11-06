import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _nombre;
  String? _avatarUrl;
  String? _backgroundUrl;
  User? _user;
  StreamSubscription<User?>? _authSubscription;

  UserState({required String nombre, String? avatarUrl, String? backgroundUrl})
      : _nombre = nombre,
        _avatarUrl = avatarUrl,
        _backgroundUrl = backgroundUrl {
    _loadFromPrefs();
    _initAuthListener();
  }

  String get nombre {
    // Usar el nombre guardado localmente (que se sincroniza con Firestore)
    return _nombre;
  }
  
  String? get email => _user?.email;
  String? get avatarUrl => _avatarUrl;
  String? get backgroundUrl => _backgroundUrl;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;

  void _initAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        // Cargar datos desde Firestore cuando el usuario se autentica
        _loadFromFirestore();
      }
      notifyListeners();
    });
  }

  Future<void> _loadFromFirestore() async {
    if (_user == null) return;
    
    try {
      debugPrint('🔍 Cargando datos desde Firestore para UID: ${_user!.uid}');
      
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        debugPrint('📥 Datos encontrados en Firestore: $data');
        
        if (data != null) {
          // Cargar nombre
          if (data['nombre'] != null) {
            final firestoreName = data['nombre'] as String;
            debugPrint('✅ Nombre desde Firestore: $firestoreName');
            _nombre = firestoreName;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_nombre', firestoreName);
          }
          
          // Cargar URLs de imágenes
          if (data['photoURL'] != null) {
            _avatarUrl = data['photoURL'] as String;
            debugPrint('✅ PhotoURL desde Firestore: $_avatarUrl');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_avatarUrl', _avatarUrl!);
          }
          
          if (data['backgroundURL'] != null) {
            _backgroundUrl = data['backgroundURL'] as String;
            debugPrint('✅ BackgroundURL desde Firestore: $_backgroundUrl');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_backgroundUrl', _backgroundUrl!);
          } else {
            debugPrint('⚠️ No hay backgroundURL en Firestore');
          }
          
          notifyListeners();
        }
      } else {
        debugPrint('⚠️ Documento de usuario no existe en Firestore');
      }
    } catch (e) {
      debugPrint('❌ Error cargando desde Firestore: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _nombre = prefs.getString('user_nombre') ?? _nombre;
    final savedAvatarUrl = prefs.getString('user_avatarUrl');
    if (savedAvatarUrl != null && savedAvatarUrl.isNotEmpty) {
      _avatarUrl = savedAvatarUrl;
      debugPrint('📦 Avatar cargado desde SharedPreferences: $_avatarUrl');
    }
    final savedBackgroundUrl = prefs.getString('user_backgroundUrl');
    if (savedBackgroundUrl != null && savedBackgroundUrl.isNotEmpty) {
      _backgroundUrl = savedBackgroundUrl;
      debugPrint('📦 Background cargado desde SharedPreferences: $_backgroundUrl');
    }
    notifyListeners();
  }

  Future<void> setNombre(String nuevoNombre) async {
    _nombre = nuevoNombre;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nombre', nuevoNombre);
    
    // También actualizar en Firebase si el usuario está autenticado
    if (_user != null) {
      try {
        // Actualizar displayName en Firebase Auth
        await _user!.updateDisplayName(nuevoNombre);
        // Recargar el usuario para obtener los cambios actualizados
        await _user!.reload();
        _user = _auth.currentUser;
        
        // Actualizar también el documento en Firestore
        debugPrint('🔥🔥🔥 INICIANDO ACTUALIZACIÓN FIRESTORE 🔥🔥🔥');
        debugPrint('🔥 UID del usuario: ${_user!.uid}');
        debugPrint('🔥 Nombre anterior: $_nombre');
        debugPrint('🔥 Nombre nuevo: $nuevoNombre');
        debugPrint('🔥 Email: ${_user!.email}');
        
        try {
          // Verificar si el documento existe primero
          final docRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
          final docSnapshot = await docRef.get();
          
          debugPrint('🔍 ¿Documento existe? ${docSnapshot.exists}');
          if (docSnapshot.exists) {
            debugPrint('📄 Datos actuales del documento: ${docSnapshot.data()}');
          }
          
          // Intentar actualizar
          await docRef.update({'nombre': nuevoNombre});
          debugPrint('✅ Firestore actualizado exitosamente con update()');
          
          // Verificar que se actualizó
          final updatedDoc = await docRef.get();
          debugPrint('🔍 Datos después de actualizar: ${updatedDoc.data()}');
          
        } catch (updateError) {
          // Si update falla, intentar con set (puede que el documento no exista)
          debugPrint('⚠️ Update falló, intentando con set: $updateError');
          
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .set({'nombre': nuevoNombre}, SetOptions(merge: true));
                
            debugPrint('✅ Firestore actualizado exitosamente con set()');
            
            // Verificar que se creó/actualizó
            final newDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .get();
            debugPrint('🔍 Datos después de set: ${newDoc.data()}');
            
          } catch (setError) {
            debugPrint('❌ Set también falló: $setError');
            rethrow;
          }
        }
            
      } catch (e) {
        debugPrint('❌ Error actualizando nombre en Firebase: $e');
        debugPrint('❌ Stack trace: ${StackTrace.current}');
      }
    }
    
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
    
    // Actualizar en Firestore
    if (_user != null && url != null) {
      try {
        debugPrint('🔥 Actualizando photoURL en Firestore: $url');
        final docRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
        
        // Intentar actualizar directamente (funciona si el documento existe)
        try {
          await docRef.update({'photoURL': url});
          debugPrint('✅ photoURL actualizado con update()');
        } catch (updateError) {
          // Si falla el update, es porque el documento no existe
          // Crear el documento completo con todos los campos requeridos
          debugPrint('⚠️ Update falló, creando documento completo...');
          await docRef.set({
            'uid': _user!.uid,
            'email': _user!.email ?? '',
            'displayName': _user!.displayName ?? _nombre,
            'photoURL': url,
            'backgroundURL': _backgroundUrl,
            'nombre': _nombre,
            'activo': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Documento creado con photoURL');
        }
      } catch (e) {
        debugPrint('❌ Error actualizando photoURL en Firestore: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> setBackgroundUrl(String? url) async {
    _backgroundUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString('user_backgroundUrl', url);
    } else {
      await prefs.remove('user_backgroundUrl');
    }
    
    // Actualizar en Firestore
    if (_user != null && url != null) {
      try {
        debugPrint('🔥 Actualizando backgroundURL en Firestore: $url');
        final docRef = FirebaseFirestore.instance.collection('users').doc(_user!.uid);
        
        // Intentar actualizar directamente (funciona si el documento existe)
        try {
          await docRef.update({'backgroundURL': url});
          debugPrint('✅ backgroundURL actualizado con update()');
        } catch (updateError) {
          // Si falla el update, es porque el documento no existe
          // Crear el documento completo con todos los campos requeridos
          debugPrint('⚠️ Update falló, creando documento completo...');
          await docRef.set({
            'uid': _user!.uid,
            'email': _user!.email ?? '',
            'displayName': _user!.displayName ?? _nombre,
            'photoURL': _avatarUrl,
            'backgroundURL': url,
            'nombre': _nombre,
            'activo': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ Documento creado con backgroundURL');
        }
      } catch (e) {
        debugPrint('❌ Error actualizando backgroundURL en Firestore: $e');
      }
    }
    
    notifyListeners();
  }

  /// Obtiene el número de insignias obtenidas por el usuario
  /// Consulta la colección estaciones_visitadas que es donde realmente se guardan
  Future<int> getInsigniasCount() async {
    if (_user == null) return 0;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('estaciones_visitadas')
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ Error obteniendo conteo de insignias: $e');
      return 0;
    }
  }
}
