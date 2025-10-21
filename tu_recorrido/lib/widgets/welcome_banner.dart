import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeBanner extends StatefulWidget {
  final String nombre;
  final String uid;

  const WelcomeBanner({
    super.key,
    required this.nombre,
    required this.uid,
  });

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner> {
  bool _showWelcome = false;
  late SharedPreferences _prefs;

  // Design tokens - Paleta cálida
  static const _onPrimary = Color(0xFF1A1A1A); // onSurface
  static const bannerBg = Color(0xFFEAF5FE); // celeste suave para fondo

  @override
  void initState() {
    super.initState();
    _loadWelcomeFlag();
  }

  Future<void> _loadWelcomeFlag() async {
    _prefs = await SharedPreferences.getInstance();
    final seen = _prefs.getBool('welcome_seen_${widget.uid}') ?? false;
    setState(() {
      _showWelcome = !seen;
    });
  }

  Future<void> _dismissWelcome() async {
    await _prefs.setBool('welcome_seen_${widget.uid}', true);
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showWelcome) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 2, vertical: 10), // Mismo margen que las cards
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // sombra sutil
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.explore,
              color: Color(0xFF66B7F0), size: 28), // celeste
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('hello_name', namedArgs: {'name': widget.nombre}),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _onPrimary,
                  ),
                  semanticsLabel: 'Bienvenida',
                ),
                const SizedBox(height: 2),
                Text(
                  tr('welcome_activate_location'),
                  style: TextStyle(
                    fontSize: 13,
                    color: _onPrimary.withOpacity(0.6),
                  ),
                  semanticsLabel: 'Subtítulo bienvenida',
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Color(0xFF6A756E)),
            tooltip: 'Cerrar banner de bienvenida',
            onPressed: _dismissWelcome,
          ),
        ],
      ),
    );
  }
}
