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

  // Design tokens
  static const _primaryGreen = Color(0xFF16A34A);
  static const _onPrimary = Color(0xFF0F172A);
  static const _onPrimaryDark = Color(0xFFE5F4EC);
  static const bannerBg = Color(0xFFE8F5E9);

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.explore, color: _primaryGreen, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('hello_name', namedArgs: {'name': widget.nombre}),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isDark ? _onPrimaryDark : _onPrimary,
                  ),
                  semanticsLabel: 'Bienvenida',
                ),
                const SizedBox(height: 2),
                Text(
                  tr('welcome_activate_location'),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? _onPrimaryDark.withValues(alpha: 0.7)
                        : _onPrimary.withValues(alpha: 0.6),
                  ),
                  semanticsLabel: 'Subtítulo bienvenida',
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Cerrar banner de bienvenida',
            onPressed: _dismissWelcome,
          ),
        ],
      ),
    );
  }
}
