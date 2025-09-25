
import 'package:flutter/material.dart';
import '../utils/colores.dart';

import '../utils/seed.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con gradiente y patrones
          Container(
            decoration: const BoxDecoration(
              gradient: Coloressito.backgroundGradient,
            ),
          ),
          // Elementos decorativos flotantes
          Positioned(
            top: 100,
            right: 30,
            child: _FloatingElement(
              icon: Icons.location_on,
              color: Coloressito.badgeRed,
              size: 40,
            ),
          ),
          Positioned(
            top: 180,
            left: 50,
            child: _FloatingElement(
              icon: Icons.stars,
              color: Coloressito.badgeYellow,
              size: 35,
            ),
          ),
          Positioned(
            top: 280,
            right: 80,
            child: _FloatingElement(
              icon: Icons.camera_alt,
              color: Coloressito.badgeGreen,
              size: 30,
            ),
          ),
          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                // Header con logo y botones
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Coloressito.surfaceLight,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Coloressito.borderLight),
                        ),
                        child: const Icon(
                          Icons.map,
                          color: Coloressito.textPrimary,
                          size: 24,
                        ),
                      ),
                      // Botón login
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/auth/login'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Coloressito.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Coloressito.borderLight),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              color: Coloressito.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido principal
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // parte del avatare
                      Container(
                        width: 150,
                        height: 150,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Coloressito.surfaceLight,
                              Coloressito.surfaceDark,
                            ],
                          ),
                          border: Border.all(color: Coloressito.borderLight, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Coloressito.shadowColor,
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.explore,
                          size: 80,
                          color: Coloressito.textPrimary,
                        ),
                      ),
                      // Título
                      const Text(
                        'RECORRIDO',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Coloressito.textPrimary,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Coloressito.shadowColor,
                            ),
                          ],
                        ),
                      ),
                          // Botón temporal para seedear lugares
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                await seedPlaces();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Seed places listo ✅')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error al seedear: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Cargar lugares de ejemplo'),
                          ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      const Text(
                        'Colecciona el mundo',
                        style: TextStyle(
                          fontSize: 18,
                          color: Coloressito.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Stats o preview de funcionalidades
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatCard(
                            icon: Icons.location_on,
                            title: 'Lugares',
                            subtitle: '500+',
                            color: Coloressito.badgeRed,
                          ),
                          _StatCard(
                            icon: Icons.emoji_events,
                            title: 'Insignias',
                            subtitle: '200+',
                            color: Coloressito.badgeYellow,
                          ),
                          _StatCard(
                            icon: Icons.people,
                            title: 'Exploradores',
                            subtitle: '10K+',
                            color: Coloressito.badgeGreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón principal de inicio
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Botón principal
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/auth'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: Coloressito.buttonGradient,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Coloressito.glowColor,
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rocket_launch,
                                color: Coloressito.textPrimary,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'COMENZAR AVENTURA',
                                style: TextStyle(
                                  color: Coloressito.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Acceso a /places solo en debug
                      if (kDebugMode)
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/places'),
                          child: const Text('Ver / administrar lugares'),
                        ),
                      // Texto adicional
                      const Text(
                        'Crea tu pasaporte digital y descubre\nlugares increíbles cerca de ti',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Coloressito.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            print('FAB pressed → signing in anonymously…');
            await FirebaseAuth.instance.signInAnonymously();

            print('Signed in. Writing to Firestore…');
            await FirebaseFirestore.instance.collection('healthchecks').add({
              'ts': DateTime.now().toIso8601String(),
              'env': 'dev',
            });

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Firestore OK ✅')),
              );
            }
            print('Write done ✅');
          } catch (e, st) {
            print('🔥 Firestore write failed: $e\n$st');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.cloud_done),
      ),
    );
  }
}

class _FloatingElement extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _FloatingElement({
    required this.icon,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.6,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Coloressito.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Coloressito.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Coloressito.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Coloressito.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      );
    }
}

