import 'package:flutter/material.dart';
import 'package:tu_recorrido/screens/menu.dart'; 
import 'package:tu_recorrido/screens/login.dart';
import 'package:tu_recorrido/screens/registro.dart';
import 'package:tu_recorrido/screens/places_screen.dart';
import 'package:tu_recorrido/admin/screens/admin_screen.dart';
import 'package:tu_recorrido/admin/screens/crear_estacion.dart';
import 'package:tu_recorrido/screens/escanerqr.dart';
import 'package:tu_recorrido/screens/coleccion.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase (usa firebase_options.dart real en producción)
  try {
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform,
      options: const FirebaseOptions(
        apiKey: "tu-api-key-aqui",
        authDomain: "tu-proyecto.firebaseapp.com",
        projectId: "tu-proyecto-id",
        storageBucket: "tu-proyecto.appspot.com",
        messagingSenderId: "123456789",
        appId: "1:123456789:web:abcdef123456",
      ),
    );
    debugPrint('Firebase initialized');
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  if (kIsWeb) {
    usePathUrlStrategy();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorrido',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/': (_) => const LoginScreen(), // Ruta por defecto
        '/login': (_) => const LoginScreen(),
        '/registro': (_) => const RegistroScreen(),
        '/menu': (_) => Mapita(),
        '/places': (_) => const PlacesScreen(),
        '/admin': (_) => const AdminScreen(),
        '/admin/crear-estacion': (_) => const CrearEstacionScreen(),
        '/escanear': (_) => const EscanerQRScreen(),
        '/coleccion': (_) => const ColeccionScreen(),
      },
    );
  }
}



