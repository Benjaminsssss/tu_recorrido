import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'package:easy_localization/easy_localization.dart';
import 'firebase_options_dev.dart';

import 'user_state_provider.dart';

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
          child: const MyApp(),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('❌ Uncaught error: $error\n$stack');
  });
}
