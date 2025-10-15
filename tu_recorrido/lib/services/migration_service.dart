import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de migración para convertir la estructura de estaciones visitadas
/// De: estaciones_visitadas/{id} -> { userId, estacionId, ... }
/// A: users/{userId}/estaciones_visitadas/{estacionId} -> { estacionId, ... }
class MigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Migra todos los documentos de la colección antigua a la nueva estructura
  static Future<void> migrarEstacionesVisitadas() async {
    try {
      print('Iniciando migración de estaciones visitadas...');
      
      // 1. Obtener todos los documentos de la colección antigua
      final querySnapshot = await _firestore
          .collection('estaciones_visitadas')
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('No hay documentos para migrar');
        return;
      }
      
      print('Encontrados ${querySnapshot.docs.length} documentos para migrar');
      
      // 2. Batch para operaciones eficientes
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      int totalMigrated = 0;
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'] as String?;
        final estacionId = data['estacionId'] as String?;
        
        if (userId == null || estacionId == null) {
          print('Documento inválido: ${doc.id} - userId: $userId, estacionId: $estacionId');
          continue;
        }
        
        // 3. Crear el documento en la nueva estructura
        final newDocRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('estaciones_visitadas')
            .doc(estacionId);
        
        // 4. Copiar los datos sin el userId (ya está implícito en la ruta)
        final newData = Map<String, dynamic>.from(data);
        newData.remove('userId'); // No necesario en la nueva estructura
        
        batch.set(newDocRef, newData);
        batchCount++;
        
        // 5. Ejecutar batch cada 500 operaciones (límite de Firestore)
        if (batchCount >= 500) {
          await batch.commit();
          totalMigrated += batchCount;
          print('Migrados $totalMigrated documentos...');
          batch = _firestore.batch();
          batchCount = 0;
        }
      }
      
      // 6. Ejecutar el último batch si tiene documentos
      if (batchCount > 0) {
        await batch.commit();
        totalMigrated += batchCount;
      }
      
      print('Migración completada: $totalMigrated documentos migrados');
      print('Revisa que todo funcione correctamente antes de eliminar la colección antigua');
      
    } catch (e) {
      print('Error durante la migración: $e');
      rethrow;
    }
  }
  
  /// Verifica que la migración fue exitosa comparando counts
  static Future<void> verificarMigracion() async {
    try {
      print('Verificando migración...');
      
      // Contar documentos en la colección antigua
      final antiguaSnapshot = await _firestore
          .collection('estaciones_visitadas')
          .get();
      final documentosAntiguos = antiguaSnapshot.docs.length;
      
      // Contar documentos en las nuevas subcolecciones
      // Nota: Esta es una aproximación ya que no podemos hacer queries globales en subcolecciones
      final usersSnapshot = await _firestore.collection('users').get();
      int documentosNuevos = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final estacionesVisitadas = await userDoc.reference
            .collection('estaciones_visitadas')
            .get();
        documentosNuevos += estacionesVisitadas.docs.length;
      }
      
      print('Documentos en colección antigua: $documentosAntiguos');
      print('Documentos en nuevas subcolecciones: $documentosNuevos');
      
      if (documentosAntiguos == documentosNuevos) {
        print('Migración verificada correctamente');
      } else {
        print('ADVERTENCIA: Los números no coinciden. Revisa la migración.');
      }
      
    } catch (e) {
      print('Error durante la verificación: $e');
      rethrow;
    }
  }
  
  /// PELIGROSO: Elimina la colección antigua después de verificar
  /// SOLO ejecutar después de verificar que todo funciona correctamente
  static Future<void> eliminarColeccionAntigua() async {
    try {
      print('ELIMINANDO colección antigua...');
      
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('estaciones_visitadas')
          .get();
      
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('Colección antigua eliminada');
      
    } catch (e) {
      print('Error al eliminar colección antigua: $e');
      rethrow;
    }
  }
}