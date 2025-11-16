import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:geolocator/geolocator.dart';


class ProfileService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Obtiene la comuna actual basada en la ubicación del usuario
  static Future<String?> getCurrentComuna() async {
    try {
      // Verificar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permisos de ubicación denegados');
          return null;
        }
      }

      // Obtener la ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Obtener el nombre de la comuna desde Firebase
      QuerySnapshot querySnapshot = await _firestore
          .collection('estaciones')
          .where('activa', isEqualTo: true)
          .get();

      // Encontrar la estación más cercana
      double minDistance = double.infinity;
      String? nearestComuna;

      for (var doc in querySnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        double lat = data['lat'] as double;
        double lng = data['lng'] as double;
        String comuna = data['comuna'] as String;

        // Calcular distancia a la estación
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lng
        );

        if (distance < minDistance) {
          minDistance = distance;
          // Extraer solo el nombre de la comuna (sin ", Santiago de Chile")
          nearestComuna = comuna.split(',').first;
        }
      }

      if (nearestComuna != null) {
        debugPrint('Comuna más cercana detectada: $nearestComuna');
        return nearestComuna;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error obteniendo comuna actual: $e');
      return null;
    }
  }

  /// Obtiene el progreso total de lugares visitados en Chile
  static Stream<Map<String, dynamic>> getTotalProgress(String uid) {
    try {
      // Stream de estaciones totales (solo activas)
      final totalStream = _firestore
          .collection('estaciones')
          .where('activa', isEqualTo: true)
          .snapshots()
          .map((snapshot) => snapshot.size);

      // Stream de estaciones visitadas por el usuario
      final visitadasStream = _firestore
          .collection('users')
          .doc(uid)
          .collection('estaciones_visitadas')
          .snapshots()
          .map((snapshot) => snapshot.size);

      // Combinar ambos streams
      return Rx.combineLatest2(
        totalStream,
        visitadasStream,
        (total, visitados) => {
          'visitados': visitados,
          'total': total,
        },
      ).handleError((error) {
        debugPrint('Error obteniendo progreso total: $error');
        return {'visitados': 0, 'total': 0};
      });
    } catch (e) {
      debugPrint('Error en getTotalProgress: $e');
      return Stream.value({'visitados': 0, 'total': 0});
    }
  }

  /// Obtiene la lista de comunas disponibles
  static Stream<List<String>> getComunas() {
    try {
      return _firestore
          .collection('comunas')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList())
          .handleError((error) {
            debugPrint('Error obteniendo lista de comunas: $error');
            return <String>[];
          });
    } catch (e) {
      debugPrint('Error inesperado en getComunas: $e');
      return Stream.value(<String>[]);
    }
  }

  /// Obtiene el progreso de una comuna específica para un usuario
  static Stream<Map<String, dynamic>> getComunaProgress(String uid, String comuna) {
    if (uid.isEmpty || comuna.isEmpty) {
      return Stream.value({
        'comuna': comuna,
        'visitados': 0,
        'total': 0,
      });
    }

    try {
      debugPrint('Buscando estaciones en comuna: $comuna');
      
      // Obtener todas las estaciones activas en la comuna
      final estacionesStream = _firestore
          .collection('estaciones')
          .where('activa', isEqualTo: true)
          .where('comuna', isEqualTo: '$comuna, Santiago de Chile')
          .snapshots();

      // Obtener las estaciones visitadas por el usuario
      final visitadasStream = _firestore
          .collection('users')
          .doc(uid)
          .collection('estaciones_visitadas')
          .snapshots();

      // Combinar los streams para contar correctamente
      return Rx.combineLatest2(
        estacionesStream,
        visitadasStream,
        (QuerySnapshot estacionesSnapshot, QuerySnapshot visitadasSnapshot) {
          // Obtener IDs de todas las estaciones en la comuna
          final estacionesIds = estacionesSnapshot.docs.map((doc) => doc.id).toSet();
          debugPrint('Estaciones en $comuna: ${estacionesIds.length}');

          // Contar solo las visitas a estaciones de esta comuna
          int visitadas = 0;
          for (var doc in visitadasSnapshot.docs) {
            var estacionId = doc.data()! as Map<String, dynamic>;
            if (estacionesIds.contains(estacionId['estacionId'])) {
              visitadas++;
              debugPrint('Estación válida encontrada: ${estacionId['estacionId']}');
            }
          }
          
          debugPrint('Total en $comuna: ${estacionesIds.length}, Visitadas: $visitadas');
          return {
            'comuna': comuna,
            'visitados': visitadas,
            'total': estacionesIds.length,
          };
        },
      ).handleError((error) {
        debugPrint('Error procesando progreso de $comuna: $error');
        return {
          'comuna': comuna,
          'visitados': 0,
          'total': 0,
        };
      });
    } catch (e) {
      debugPrint('Error inesperado en getComunaProgress: $e');
      return Stream.value({
        'comuna': comuna,
        'visitados': 0,
        'total': 0,
      });
    }
  }

  /// Obtiene el avatar del usuario en formato base64 desde Firestore
  static Future<String?> getAvatarBase64(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['avatarBase64'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting avatar: $e');
      return null;
    }
  }

  /// Guarda el avatar del usuario en Firebase Storage y Firestore
  static Future<void> saveAvatarBase64(String uid, Uint8List bytes) async {
    try {
      // Convertir a base64
      final base64String = base64Encode(bytes);

      // Guardar en Firestore
      await _firestore.collection('users').doc(uid).set({
        'avatarBase64': base64String,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Opcional: también subir a Storage para respaldo
      try {
        final ref = _storage.ref().child('avatars/$uid.jpg');
        await ref.putData(bytes);
      } catch (e) {
        debugPrint('Error uploading to Storage (non-critical): $e');
      }
    } catch (e) {
      debugPrint('Error saving avatar: $e');
      rethrow;
    }
  }

  /// Actualiza el perfil del usuario en Firestore
  static Future<void> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  /// Obtiene los datos del perfil del usuario
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
}
