import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeHeader extends StatefulWidget {
  final String nombre;
  final String? avatarUrl;
  final String uid;
  final bool hasNotifications;
  final bool showBell;
  final VoidCallback? onAvatarTap;
  
  const HomeHeader({
    Key? key,
    required this.nombre,
    required this.uid,
    this.avatarUrl,
    this.hasNotifications = false,
    this.showBell = false,
    this.onAvatarTap,
  }) : super(key: key);

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with SingleTickerProviderStateMixin {
  bool _showWelcome = false;
  late SharedPreferences _prefs;
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Design tokens
  static const _primaryGreen = Color(0xFF16A34A);
  static const _onPrimary = Color(0xFF0F172A);
  static const _onPrimaryDark = Color(0xFFE5F4EC);
  static const _placeholderBg = Color(0xFFD9F2E4);
  static const _hairline = Color(0xFFE4EEE8);
  static const _hairlineDark = Color(0xFF1A211E);

  @override
  void initState() {
    super.initState();
    _loadWelcomeFlag();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
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

  void _handleAvatarTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _handleAvatarTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleAvatarTapCancel() {
    setState(() => _isPressed = false);
    _pressController.reverse();
  }

  void _handleAvatarTap() {
    if (widget.onAvatarTap != null) {
      widget.onAvatarTap!();
    } else {
      Navigator.pushNamed(context, '/perfil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bannerBg = const Color(0xFFE8F5E9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header con píldora flotante (Opción A)
        Container(
          height: 76,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? _hairlineDark : _hairline,
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Píldora flotante glassmorphism
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF141414).withOpacity(0.55)
                              : Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white.withOpacity(0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Contenido del header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Row(
                  children: [
                    // Título
                    Expanded(
                      child: Text(
                        tr('app_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 21,
                          letterSpacing: 0.2,
                          color: isDark ? _onPrimaryDark : _onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: 'Título de la app',
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Campana opcional
                    if (widget.showBell)
                      _buildActionButton(
                        icon: Icons.notifications_outlined,
                        hasNotification: widget.hasNotifications,
                        onTap: () {},
                        isDark: isDark,
                      ),
                    if (widget.showBell) const SizedBox(width: 8),
                    // Avatar con hero animation
                    Hero(
                      tag: 'profile_avatar_${widget.uid}',
                      child: GestureDetector(
                        onTapDown: _handleAvatarTapDown,
                        onTapUp: _handleAvatarTapUp,
                        onTapCancel: _handleAvatarTapCancel,
                        onTap: _handleAvatarTap,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _isPressed
                                        ? _primaryGreen
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: _placeholderBg,
                                      backgroundImage: widget.avatarUrl != null &&
                                              widget.avatarUrl!.isNotEmpty
                                          ? NetworkImage(widget.avatarUrl!)
                                          : null,
                                      child: widget.avatarUrl == null ||
                                              widget.avatarUrl!.isEmpty
                                          ? Icon(
                                              Icons.person,
                                              color: _primaryGreen,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                    if (widget.hasNotifications)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: _primaryGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? const Color(0xFF141414)
                                                  : Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                          color: isDark ? _onPrimaryDark.withOpacity(0.7) : _onPrimary.withOpacity(0.6),
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

  // Método helper para botones de acción (campana, etc.)
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool hasNotification = false,
  }) {
    return Semantics(
      label: 'Botón de acción',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isDark ? _onPrimaryDark : _onPrimary,
                size: 24,
              ),
              if (hasNotification)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF141414) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
