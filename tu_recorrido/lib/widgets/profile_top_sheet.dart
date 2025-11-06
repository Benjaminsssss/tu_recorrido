import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colores.dart';

class ProfileTopSheet extends StatefulWidget {
  final String uid;
  final String? avatarUrl;

  const ProfileTopSheet({
    super.key,
    required this.uid,
    this.avatarUrl,
  });

  @override
  State<ProfileTopSheet> createState() => _ProfileTopSheetState();
}

class _ProfileTopSheetState extends State<ProfileTopSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _sheetAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _dimAnimation;

  // Snap points: Oculto (-100%), Medio (70%), Expandido (92%)
  static const double hiddenSnap = -1.0;
  static const double mediumSnap = 0.70;
  static const double expandedSnap = 0.92;

  double _currentSnap = mediumSnap;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _sheetAnimation = Tween<double>(begin: hiddenSnap, end: mediumSnap).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _dimAnimation = Tween<double>(begin: 0.0, end: 0.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta! / MediaQuery.of(context).size.height;
      _currentSnap =
          (_sheetAnimation.value - _dragOffset).clamp(0.0, expandedSnap);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    // Cerrar si se desliza hacia arriba (negativo) con velocidad o si está muy arriba
    if (velocity < -700 || _currentSnap < 0.3) {
      _closeSheet();
    } else if (_currentSnap > 0.80) {
      // Expandir
      _snapTo(expandedSnap);
    } else {
      // Medio
      _snapTo(mediumSnap);
    }

    setState(() {
      _dragOffset = 0.0;
    });
  }

  void _snapTo(double snap) {
    setState(() {
      _currentSnap = snap;
    });
    _controller.animateTo(
      snap,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _closeSheet() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeSheet();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Compute a safe visible snap fraction: prefer the manual _currentSnap while dragging,
          // otherwise use the animated value. Clamp to [0, expandedSnap] to avoid negative heights.
          final double animValue = _sheetAnimation.value;
          final double visibleSnap =
              (_dragOffset != 0.0 ? _currentSnap : animValue)
                  .clamp(0.0, expandedSnap);

          return Stack(
            children: [
              // Scrim con blur y dim
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSheet,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAnimation.value,
                      sigmaY: _blurAnimation.value,
                    ),
                    child: Container(
                      color:
                          Colors.black.withValues(alpha: _dimAnimation.value),
                    ),
                  ),
                ),
              ),
              // Top Sheet
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // Use the computed visibleSnap (already clamped to valid range)
                height: size.height * visibleSnap,
                child: GestureDetector(
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  child: SafeArea(
                    bottom: false,
                    child: Material(
                      color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(26),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF1A1A1A) : Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(26),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 28,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            // Handle visual
                            Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Quick Actions
                            _QuickActionsRow(isDark: isDark),
                            const SizedBox(height: 16),
                            // Cards con scroll
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                children: [
                                  _ProgressCard(isDark: isDark),
                                  const SizedBox(height: 12),
                                  _RecentStampsCard(isDark: isDark),
                                  const SizedBox(height: 12),
                                  _StreakCard(isDark: isDark),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



// Quick Actions en chips 56px con accesibilidad
class _QuickActionsRow extends StatelessWidget {
  final bool isDark;

  const _QuickActionsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _QuickActionChip(
            icon: Icons.edit_outlined,
            label: 'Editar',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _QuickActionChip(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _QuickActionChip(
            icon: Icons.qr_code,
            label: 'QR',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
          _QuickActionChip(
            icon: Icons.share_outlined,
            label: 'Compartir',
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Coloressito.adventureGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : Coloressito.adventureGreen.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Coloressito.adventureGreen,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Card de progreso
class _ProgressCard extends StatelessWidget {
  final bool isDark;

  const _ProgressCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso del Pasaporte',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.62,
                      minHeight: 10,
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey[200],
                      color: Coloressito.adventureGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '62%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Card de sellos recientes con carrusel
class _RecentStampsCard extends StatelessWidget {
  final bool isDark;

  const _RecentStampsCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sellos Recientes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _getStampColor(i),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'S${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStampColor(int index) {
    final colors = [
      Coloressito.badgeBlue,
      Coloressito.badgeGreen,
      Coloressito.badgeYellow,
      Coloressito.badgeRed,
      Coloressito.adventureGreen,
      const Color(0xFF9C27B0),
    ];
    return colors[index % colors.length];
  }
}

// Card de racha
class _StreakCard extends StatelessWidget {
  final bool isDark;

  const _StreakCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Racha de Exploración',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Coloressito.badgeRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    color: Coloressito.badgeRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7 días seguidos',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '¡Sigue así!',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
