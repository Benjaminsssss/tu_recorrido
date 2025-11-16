import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tu_recorrido/models/album_photo.dart';

/// Servicio para manejar las fotos de experiencia del usuario en Firebase
class AlbumPhotosService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _usersCollection = 'users';
  static const String _albumPhotosSubcollection = 'album_photos';
  static const String _storageFolder = 'album_photos';

  /// Obtener el ID del usuario actual (con autenticación anónima si es necesario)
  static Future<String?> _getCurrentUserId() async {
    try {
      // Intentar obtener usuario de Firebase
      var firebaseUser = FirebaseAuth.instance.currentUser;
      print('🔍 Usuario actual: ${firebaseUser?.uid}');

      // Si no hay usuario autenticado, crear uno anónimo
      if (firebaseUser == null) {
        print('🔑 Creando usuario anónimo...');
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        firebaseUser = userCredential.user;
        print('✅ Usuario anónimo creado: ${firebaseUser?.uid}');
      }

      if (firebaseUser == null) {
        print('❌ No se pudo obtener usuario después de autenticación');
        return null;
      }

      // Verificar/crear documento de usuario en Firestore si no existe
      print('📝 Verificando documento de usuario en Firestore...');
      final userDocRef =
          _firestore.collection(_usersCollection).doc(firebaseUser.uid);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print('📝 Creando documento de usuario en Firestore...');

        final userData = {
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? 'anonimo@ejemplo.com',
          'displayName': firebaseUser.displayName ?? 'Usuario Anónimo',
          'photoURL': firebaseUser.photoURL,
          'nombre': 'Usuario Anónimo',
          'activo': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'role': null, // Usuario normal sin rol específico
        };

        await userDocRef.set(userData);

        // Esperar un momento para asegurar que el documento se ha creado
        await Future.delayed(const Duration(milliseconds: 500));

        // Verificar que el documento se creó correctamente
        final verifyDoc = await userDocRef.get();
        if (!verifyDoc.exists) {
          print('❌ El documento de usuario no se creó correctamente');
          return null;
        }

        print('✅ Documento de usuario creado y verificado en Firestore');
      } else {
        print('✅ Documento de usuario ya existe en Firestore');
      }

      return firebaseUser.uid;
    } catch (e) {
      print('❌ Error en _getCurrentUserId: $e');
      return null;
    }
  }

  /// Subir una foto de experiencia
  static Future<AlbumPhoto> uploadPhoto({
    required XFile imageFile,
    required String badgeId,
    String? description,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    print('🚀 Iniciando subida de foto...');

    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    print('✅ Usuario autenticado: $userId');

    try {
      // Generar ID único para la foto
      final photoId = _firestore.collection('temp').doc().id;
      print('📸 ID de foto generado: $photoId');

      // Leer bytes de la imagen
      final imageBytes = await imageFile.readAsBytes();
      print('📁 Imagen leída: ${imageBytes.length} bytes');

      // Subir imagen a Firebase Storage
      final storageRef = _storage
          .ref()
          .child(_storageFolder)
          .child(userId)
          .child('$photoId.jpg');

      print('☁️ Subiendo a Storage: ${storageRef.fullPath}');

      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'badgeId': badgeId,
            'uploadedBy': userId,
            'uploadDate': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Obtener URL de descarga
      final imageUrl = await uploadTask.ref.getDownloadURL();
      print('🔗 URL de imagen obtenida: $imageUrl');

      // Crear objeto AlbumPhoto
      final albumPhoto = AlbumPhoto(
        id: photoId,
        badgeId: badgeId,
        imageUrl: imageUrl,
        description: description,
        uploadDate: DateTime.now(),
        location: location,
        metadata: metadata,
      );

      // Preparar datos para Firestore
      final firestoreData = albumPhoto.toJson();
      print('📝 Datos para Firestore preparados: $firestoreData');

      // Guardar en Firestore
      final docRef = _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_albumPhotosSubcollection)
          .doc(photoId);

      print('💾 Guardando en Firestore: ${docRef.path}');
      await docRef.set(firestoreData);

      print('✅ Foto subida exitosamente');
      return albumPhoto;
    } catch (e) {
      print('❌ Error detallado en uploadPhoto: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Error al subir la foto: $e');
    }
  }

  /// Eliminar una foto
  static Future<void> deletePhoto(String photoId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      // Obtener datos de la foto para eliminar de Storage
      final docSnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_albumPhotosSubcollection)
          .doc(photoId)
          .get();

      if (docSnapshot.exists) {
        final photoData = docSnapshot.data();
        final imageUrl = photoData?['imageUrl'] as String?;

        // Eliminar de Storage si existe la URL
        if (imageUrl != null) {
          try {
            final ref = _storage.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Archivo ya eliminado o no existe: $e');
          }
        }
      }

      // Eliminar documento de Firestore
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_albumPhotosSubcollection)
          .doc(photoId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar la foto: $e');
    }
  }

  /// Obtener todas las fotos del álbum del usuario especificado o el actual
  static Future<List<AlbumPhoto>> getUserPhotos({String? userId}) async {
    final uid = userId ?? await _getCurrentUserId();
    if (uid == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .doc(uid)
          .collection(_albumPhotosSubcollection)
          .orderBy('uploadDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return AlbumPhoto.fromJson(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener las fotos: $e');
    }
  }

  /// Stream para escuchar cambios en las fotos del usuario especificado o el actual en tiempo real
  static Stream<List<AlbumPhoto>> watchUserPhotos({String? userId}) async* {
    final uid = userId ?? await _getCurrentUserId();
    if (uid == null) {
      yield* Stream.error(Exception('Usuario no autenticado'));
      return;
    }

    yield* _firestore
        .collection(_usersCollection)
        .doc(uid)
        .collection(_albumPhotosSubcollection)
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AlbumPhoto.fromJson(data);
      }).toList();
    });
  }

  /// Actualizar la descripción de una foto
  static Future<void> updatePhotoDescription(
      String photoId, String? description) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_albumPhotosSubcollection)
          .doc(photoId)
          .update({'description': description});
    } catch (e) {
      throw Exception('Error al actualizar la descripción: $e');
    }
  }

  /// Verificar si el usuario ha alcanzado el límite de fotos
  static Future<bool> hasReachedPhotoLimit({int maxPhotos = 50}) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;

    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_albumPhotosSubcollection)
          .limit(maxPhotos + 1)
          .get();

      return querySnapshot.docs.length >= maxPhotos;
    } catch (e) {
      return false;
    }
  }
}