import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options_dev.dart';

import 'user_state_provider.dart';
import 'models/user_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // Mantener todo en la misma zona evita 'Zone mismatch' en Web
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();

    // Inicializa Firebase con tus opciones DEV
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    if (kIsWeb) {
      usePathUrlStrategy();
    }

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
    };

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
          Locale('fr'),
          Locale('pt'),
          Locale('ru'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('es'),
        saveLocale: true,
        child: UserStateProvider(
          nombre: 'Explorador',
          child: Builder(
            builder: (context) {
              // Hidratar avatar desde SharedPreferences si existe, antes de construir la app
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                final prefs = await SharedPreferences.getInstance();
                final savedUrl = prefs.getString('user_avatarUrl');
                if (savedUrl != null && savedUrl.isNotEmpty) {
                  try {
                    final userState = context.read<UserState>();
                    if (userState.avatarUrl != savedUrl) {
                      await userState.setAvatarUrl(savedUrl);
                    }
                  } catch (_) {
                    // Provider no disponible aún; ignorar silenciosamente
                  }
                }
              });
              return const MyApp();
            },
          ),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('❌ Uncaught error: $error\n$stack');
  });
}
