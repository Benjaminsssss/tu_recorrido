import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import '../screens/perfil.dart';

class HomeHeader extends StatefulWidget {
  final String nombre;
  final String? avatarBase64;
  final String uid;
  final bool hasNotifications;
  final bool showBell;
  final VoidCallback? onAvatarTap;

  const HomeHeader({
    super.key,
    required this.nombre,
    required this.uid,
    this.avatarBase64,
    this.hasNotifications = false,
    this.showBell = false,
    this.onAvatarTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Design tokens
  static const _primaryGreen = Color(0xFF16A34A);
  static const _onPrimary = Color(0xFF0F172A);
  static const _onPrimaryDark = Color(0xFFE5F4EC);
  static const _placeholderBg = Color(0xFFD9F2E4);

  @override
  void initState() {
    super.initState();
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
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Perfil(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
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
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Builder(
                            builder: (context) {
                              ImageProvider? avatarProvider;
                              if (widget.avatarBase64 != null &&
                                  widget.avatarBase64!.isNotEmpty) {
                                try {
                                  avatarProvider =
                                      MemoryImage(base64Decode(widget.avatarBase64!));
                                } catch (_) {}
                              }
                              return CircleAvatar(
                                radius: 20,
                                backgroundColor: _placeholderBg,
                                backgroundImage: avatarProvider,
                                child: (avatarProvider == null)
                                    ? Icon(
                                        Icons.person,
                                        color: _primaryGreen,
                                        size: 20,
                                      )
                                    : null,
                              );
                            },
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
    );
  }

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
