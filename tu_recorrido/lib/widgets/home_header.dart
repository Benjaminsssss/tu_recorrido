import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeHeader extends StatefulWidget {
  final String nombre;
  final String? avatarUrl;
  final String uid;
  final bool hasNotifications;
  const HomeHeader({
    Key? key,
    required this.nombre,
    required this.uid,
    this.avatarUrl,
    this.hasNotifications = false,
  }) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool _showWelcome = false;
  late SharedPreferences _prefs;

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
    final primary = const Color(0xFF157F3D);
    final textDark = const Color(0xFF111827);
    final textSecondary = const Color(0xFF6B7280);
    final appBarBorder = const Color(0xFFE5E7EB);
    final chipBg = const Color(0xFFF3F4F6);
    final bannerBg = const Color(0xFFE8F5E9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          elevation: 1,
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: appBarBorder, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Tu Recorrido',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: textDark,
                      ),
                      semanticsLabel: 'Título de la app',
                    ),
                  ),
                ),
                Stack(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.pushNamed(context, '/perfil'),
                      child: Semantics(
                        label: 'Abrir perfil',
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: chipBg,
                          backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                              ? NetworkImage(widget.avatarUrl!)
                              : null,
                          child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                              ? Icon(Icons.person, color: textSecondary)
                              : null,
                        ),
                      ),
                    ),
                    if (widget.hasNotifications)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_showWelcome)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.explore, color: primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${widget.nombre} 👋',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textDark,
                        ),
                        semanticsLabel: 'Bienvenida',
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bienvenido a Tu Recorrido. Activa tu ubicación para ver lugares cercanos.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
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
          ),
        // Chip de sesión removido según nueva especificación
      ],
    );
  }
}
