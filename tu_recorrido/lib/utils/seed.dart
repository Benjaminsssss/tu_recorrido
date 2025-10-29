// lib/utils/seed.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

/// Carga 3 lugares de ejemplo en la colección `places`.
/// Ejecuta esta función una sola vez (luego borra el botón que la llama).
Future<void> seedPlaces() async {
  // login rápido para DEV (requiere Auth Anónima habilitada)
  await FirebaseAuth.instance.signInAnonymously();

  final s = FirestoreService.instance;
  await s.createPlace(
    name: 'Plaza de Armas',
    lat: -33.4372,
    lng: -70.6506,
    category: 'histórico',
  );
  await s.createPlace(
    name: 'Cerro San Cristóbal',
    lat: -33.4143,
    lng: -70.6385,
    category: 'parque',
  );
  await s.createPlace(
    name: 'Museo Bellas Artes',
    lat: -33.4343,
    lng: -70.6410,
    category: 'museo',
  );
}
