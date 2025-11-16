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
import 'screens/coleccion.dart';
import 'screens/debug_auth_screen.dart';
import 'screens/album.dart';
import 'screens/user_search_screen.dart';

// Admin screens
import 'admin/screens/admin_screen.dart';
import 'admin/screens/generador_qr_screen.dart';

// AuthGate & Protection
import 'package:tu_recorrido/widgets/auth_gate.dart';

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
        '/': (_) => AuthGate(
              signedIn: HomeScreen(),
              signedOut: LoginScreen(),
            ),
        '/home': (_) => const HomeScreen(),
        '/auth/login': (_) => const LoginScreen(),
        '/auth/registro': (_) => const RegistroScreen(),
        '/escaner': (_) => const EscanerQRScreen(),
        '/mapa': (_) => const Mapita(),
        '/menu': (_) => const Mapita(),
        '/perfil': (_) => const Perfil(),
        '/saved-places': (_) => const SavedPlacesScreen(),
        '/coleccion': (_) => const ColeccionScreen(),
        '/user-search': (_) => const UserSearchScreen(),

        // Admin routes
        '/admin': (_) => const AdminScreen(),
        '/admin/generador-qr': (_) => const GeneradorQRScreen(),
        '/debug-auth': (_) => const DebugAuthScreen(),

        // Si ya tienes una pantalla de lugares, descomenta:
        // '/places': (_) => const PlacesScreen(),
      },
      onGenerateRoute: (settings) {
        // Ruta dinámica para perfiles de usuario (álbum)
        if (settings.name?.startsWith('/user-profile/') ?? false) {
          final userId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (_) => AlbumScreen(userId: userId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
