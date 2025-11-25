import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tu_recorrido/models/lugares.dart';

class EstacionesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener estaciones en tiempo real
  Stream<List<PlaceResult>> obtenerEstaciones() {
    try {
      return _firestore.collection('estaciones').snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) {
          print('⚠️ No hay estaciones en la base de datos');
          return [];
        }

        return snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                String? imageUrl;
                String? badgeImageUrl;
                if (data['images'] != null && data['images'] is List && (data['images'] as List).isNotEmpty) {
                  final imagesList = (data['images'] as List);
                  print('🔎 images para ${data['nombre'] ?? doc.id}: $imagesList');
                  final img0 = imagesList[0];
                  if (img0 is Map && img0['url'] != null && img0['url'] is String && (img0['url'] as String).isNotEmpty) {
                    imageUrl = img0['url'] as String;
                  }
                }
                if (data['badgeImage'] != null && data['badgeImage'] is Map && data['badgeImage']['url'] != null && data['badgeImage']['url'] is String && (data['badgeImage']['url'] as String).isNotEmpty) {
                  badgeImageUrl = data['badgeImage']['url'] as String;
                }
                if (badgeImageUrl == null) {
                  print('⚠️ Sin badgeImage para ${data['nombre'] ?? doc.id}');
                } else {
                  print('🏅 BadgeImage: $badgeImageUrl');
                }
                return PlaceResult(
                  placeId: doc.id,
                  nombre: data['nombre'] ?? 'Estación sin nombre',
                  ubicacion: LatLng(
                    (data['latitud'] as num?)?.toDouble() ?? 0.0,
                    (data['longitud'] as num?)?.toDouble() ?? 0.0,
                  ),
                  rating: (data['rating'] as num?)?.toDouble(),
                  esGenerado: false,
                  imageUrl: imageUrl,
                  badgeImageUrl: badgeImageUrl,
                );
              } catch (e) {
                print('❌ Error al procesar documento ${doc.id}: $e');
                return null;
              }
            })
            .where((station) => station != null)
            .cast<PlaceResult>()
            .toList();
      });
    } catch (e) {
      print('❌ Error al obtener estaciones: $e');
      return Stream.value([]);
    }
  }

  // Calificar una estación
  Future<void> calificarEstacion(String estacionId, double rating) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }
    if (!user.emailVerified) {
      throw Exception(
          'Debes verificar tu correo electrónico antes de calificar lugares');
    }
    final userId = user.uid;
    try {
      print('🔍 Intentando calificar estación: $estacionId');
      print('👤 Usuario: ${user.email} (${user.uid})');
      print('✉️ Email verificado: ${user.emailVerified}');

      // Verificar si la estación existe
      final estacionRef = _firestore.collection('estaciones').doc(estacionId);
      final estacionDoc = await estacionRef.get();

      print('🏢 Estación existe: ${estacionDoc.exists}');
      if (estacionDoc.exists) {
        print('📍 Datos de la estación: ${estacionDoc.data()}');
      }

      if (!estacionDoc.exists) {
        throw Exception('La estación no existe');
      }

      // Guardar el rating individual en la subcolección ratings
      await estacionRef.collection('ratings').doc(userId).set({
        'rating': rating,
        'fecha': FieldValue.serverTimestamp(),
        'userId': userId,
        'userEmail': user.email,
      }, SetOptions(merge: true));

      print('✅ Rating individual guardado correctamente');

      // Calcular el nuevo promedio
      final ratingsSnapshot = await estacionRef.collection('ratings').get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double suma = 0;
        int totalRatings = 0;

        for (var doc in ratingsSnapshot.docs) {
          final ratingValue = doc.data()['rating'];
          if (ratingValue != null) {
            suma += (ratingValue as num).toDouble();
            totalRatings++;
          }
        }

        if (totalRatings > 0) {
          double promedio = suma / totalRatings;

          // Actualizar el promedio en el documento principal
          await estacionRef.set({
            'rating': promedio,
            'totalRatings': totalRatings,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('✅ Promedio actualizado: $promedio (Total: $totalRatings)');
        }
      }
    } catch (e) {
      print('❌ Error al calificar estación: $e');
      rethrow;
    }
  }

  // Obtener el rating del usuario actual para una estación
  Future<double?> obtenerRatingUsuario(String estacionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore
          .collection('estaciones')
          .doc(estacionId)
          .collection('ratings')
          .doc(userId)
          .get();

      if (doc.exists) {
        return (doc.data()?['rating'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener rating del usuario: $e');
      return null;
    }
  }

  // Obtener promedio de ratings en tiempo real para una estación
  Stream<double?> obtenerPromedioRatings(String estacionId) async* {
    try {
      final ratings = _firestore
          .collection('estaciones')
          .doc(estacionId)
          .collection('ratings')
          .snapshots();

      await for (var snapshot in ratings) {
        if (snapshot.docs.isEmpty) {
          yield null;
          continue;
        }

        double suma = 0;
        int totalRatings = 0;

        for (var doc in snapshot.docs) {
          final ratingValue = doc.data()['rating'];
          if (ratingValue != null) {
            suma += (ratingValue as num).toDouble();
            totalRatings++;
          }
        }

        if (totalRatings > 0) {
          yield suma / totalRatings;
        } else {
          yield null;
        }
      }
    } catch (e) {
      print('❌ Error al obtener promedio de ratings: $e');
      yield null;
    }
  }
}