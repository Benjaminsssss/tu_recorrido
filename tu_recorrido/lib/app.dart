import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'utils/app_theme.dart';

// Screens
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/registro.dart';
import 'screens/escanerqr.dart';
import 'screens/menu.dart';
import 'screens/perfil.dart';
import 'screens/saved_places_screen.dart';

// AuthGate & Protection
import 'widgets/auth_gate.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu Recorrido',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Usamos AuthGate en la raíz: decide Home o Login según sesión
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthGate(
              signedIn: HomeScreen(),
              signedOut: LoginScreen(),
            ),
        '/home': (_) => const HomeScreen(),
        '/auth/login': (_) => const LoginScreen(),
        '/auth/registro': (_) => const RegistroScreen(),
        '/escaner': (_) => const EscanerQRScreen(),
        '/mapa': (_) => const Mapita(),
        '/perfil': (_) => const Perfil(),
        '/saved-places': (_) => const SavedPlacesScreen(),

        // Si ya tienes una pantalla de lugares, descomenta:
        // '/places': (_) => const PlacesScreen(),
      },
    );
  }
}
