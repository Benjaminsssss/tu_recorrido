import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../components/white_card.dart';
import '../components/collection_card.dart';
import '../components/bottom_pill_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorrido'),
        actions: [
          StreamBuilder<User?>(
            stream: AuthService.authStateChanges,
            builder: (context, snap) {
              final signedIn = snap.hasData;
              final user = snap.data;
              final saludo = signedIn
                  ? ((user?.displayName?.trim().isNotEmpty ?? false)
                      ? user!.displayName!.trim()
                      : (user?.email ?? 'Explorador'))
                  : 'Explorador';
              return Row(children: [
                if (signedIn)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text('Hola, $saludo'),
                  ),
                IconButton(
                  tooltip: signedIn ? 'Cerrar sesión' : 'Iniciar sesión',
                  icon: Icon(signedIn ? Icons.logout : Icons.login),
                  onPressed: () => signedIn
                      ? _logout()
                      : Navigator.pushNamed(context, '/auth/login'),
                ),
              ]);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Héroe / copy
          WhiteCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Colecciona el mundo',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Crea tu pasaporte digital y descubre lugares increíbles cerca de ti.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text('Descubre')), 
                          Chip(label: Text('Explora')), 
                          Chip(label: Text('Colecciona')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.explore_rounded,
                      size: 44, color: theme.colorScheme.primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Progreso / pasaporte
          WhiteCard(
            child: Row(
              children: [
        Icon(Icons.card_travel,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu pasaporte',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: 0.35,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 6),
                      Text('7/20 sellos conseguidos',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Ver pasaporte'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Cerca de ti
          Text('Cerca de ti',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) => SizedBox(
                width: 320,
                child: CollectionCard(
                  title: 'Lugar destacado ${i + 1}',
                  subtitle: 'A ${200 * (i + 1)} m • Abierto hasta 18:00',
                  imageAsset: 'assets/img/insiginia.png',
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 5,
            ),
          ),

          const SizedBox(height: 16),

          // Desafíos
          Text('Desafíos semanales',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_rounded, color: theme.colorScheme.tertiary),
                    const SizedBox(width: 8),
                    const Text('Visita 3 plazas históricas'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.camera_alt_rounded,
                        color: theme.colorScheme.secondary),
                    const SizedBox(width: 8),
                    const Text('Toma una foto en un sitio declarado'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Últimas insignias
          Text('Últimas insignias',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              6,
              (i) => Chip(
                avatar: const CircleAvatar(child: Icon(Icons.emoji_events)),
                label: Text('Insignia ${i + 1}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/escaner'),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Escanear'),
      ),
      bottomNavigationBar: BottomPillNav(
        currentIndex: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 1) {
            Navigator.pushNamed(context, '/mapa');
          } else if (i == 2) {
            Navigator.pushNamed(context, '/perfil');
          }
        },
      ),
    );
  }
}
