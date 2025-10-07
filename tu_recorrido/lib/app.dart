import 'package:flutter/material.dart';

// Screens
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/registro.dart';
import 'screens/auth.dart';
import 'screens/menu.dart';
import 'screens/perfil.dart';
import 'screens/places_screen.dart';
import 'screens/recuperar.dart';
import 'screens/escanerqr.dart';
import 'screens/coleccion.dart';

// Admin Screens
import 'admin/screens/admin_screen.dart';
import 'admin/screens/crear_estacion.dart';

// AuthGate
import 'widgets/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorrido',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4CAF50), // opcional
        brightness: Brightness.light,
      ),

      // Usamos AuthGate en la raíz: decide Home o Login según sesión
      initialRoute: '/',
      routes: {
        '/': (_) =>
            const AuthGate(signedIn: HomeScreen(), signedOut: LoginScreen()),
        '/home': (_) => const HomeScreen(),
        '/menu': (_) => const Mapita(),
        '/auth': (_) => const AuthScreen(), // Ver si eliminarla o tomar el diseño para auth registro
        '/auth/login': (_) => const LoginScreen(),
        '/auth/registro': (_) => const RegistroScreen(),
        '/perfil': (_) => const Perfil(), 
        '/places': (_) => const PlacesScreen(), // eliminar vista 
        '/escanear': (_) => const EscanerQRScreen(),
        '/coleccion': (_) => const ColeccionScreen(),
        '/admin': (_) => const AdminScreen(), // eliminar vista 
        '/admin/crear-estacion': (_) => const CrearEstacionScreen(), // eliminar vista 
      },
    );
  }
}
