import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF5F1E8), // beige claro
            const Color(0xFFE8DCC4), // arena/crema
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFF5D4E37).withOpacity(0.15), // marrón tierra sutil
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D4E37).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Título
          Expanded(
            child: Text(
              tr('app_title'),
              style: GoogleFonts.pacifico(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 24,
                  letterSpacing: 0.3,
                  color: Color(0xFF5D4E37), // marrón tierra
                ),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: 'Título de la app',
            ),
          ),
          const SizedBox(width: 12),
          // Avatar minimalista
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isPressed
                              ? const Color(
                                  0xFF4A7C59) // verde bosque al presionar
                              : const Color(0xFF5D4E37)
                                  .withOpacity(0.3), // marrón claro
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5D4E37).withOpacity(0.12),
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
                                  avatarProvider = MemoryImage(
                                      base64Decode(widget.avatarBase64!));
                                } catch (_) {}
                              }
                              return CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    const Color(0xFFE8DCC4), // beige
                                backgroundImage: avatarProvider,
                                child: (avatarProvider == null)
                                    ? const Icon(
                                        Icons.person,
                                        color:
                                            Color(0xFF5D4E37), // marrón tierra
                                        size: 20,
                                      )
                                    : null,
                              );
                            },
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
}
