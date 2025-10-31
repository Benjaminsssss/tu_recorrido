import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Servicio sencillo para subir/eliminar archivos en Firebase Storage.
///
/// Nota: Este es un helper mínimo. Asegúrate de revisar tus reglas de Storage
/// en Firebase Console para permitir operaciones según tu modelo de auth.
class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Sube un archivo y devuelve la URL de descarga pública.
  /// [path] ejemplo: "places/{placeId}/images/imagen1.jpg"
  Future<String> uploadFile(File file, String path, {String? contentType}) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);

    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask.whenComplete(() {});
    // Obtener URL de descarga
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  /// Sube bytes (útil para Flutter Web) y devuelve URL de descarga
  Future<String> uploadBytes(Uint8List data, String path, {String? contentType}) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);

    final uploadTask = ref.putData(data, metadata);
    final snapshot = await uploadTask.whenComplete(() {});
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  /// Borra un archivo en Storage por su path (p. ej. 'places/.../imagen1.jpg')
  Future<void> deleteFile(String path) async {
    final ref = _storage.ref().child(path);
    await ref.delete();
  }
}
