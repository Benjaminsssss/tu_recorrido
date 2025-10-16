import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../components/white_card.dart';
import '../components/collection_card.dart';
import '../components/bottom_pill_nav.dart';
import '../widgets/home_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snap) {
        final user = snap.data;
        final nombre = (user?.displayName?.trim().isNotEmpty ?? false)
            ? user!.displayName!.trim()
            : (user?.email ?? 'Explorador');
        final avatarUrl = user?.photoURL ?? '';
        final uid = user?.uid ?? '';
        return Scaffold(
          body: SafeArea(
            child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              HomeHeader(
                nombre: nombre,
                avatarUrl: avatarUrl,
                uid: uid,
                hasNotifications: false,
              ),
              WhiteCard(
                padding: const EdgeInsets.all(20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 360;
                    final imgSize = isNarrow ? 72.0 : 90.0;
                    final iconSize = isNarrow ? 36.0 : 44.0;
                    final image = Container(
                      width: imgSize,
                      height: imgSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.explore_rounded,
                          size: iconSize, color: Theme.of(context).colorScheme.primary),
                    );
                    final text = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Colecciona el mundo',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Crea tu pasaporte digital y descubre lugares increíbles cerca de ti.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: const [
                            Chip(label: Text('Descubre')),
                            Chip(label: Text('Explora')),
                            Chip(label: Text('Colecciona')),
                          ],
                        ),
                      ],
                    );
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          text,
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerLeft, child: image),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: text),
                          const SizedBox(width: 12),
                          image,
                        ],
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Sección: Cerca de ti
              Text('Cerca de ti',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) => SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8 < 260
                        ? 260
                        : MediaQuery.of(context).size.width * 0.8 > 340
                            ? 340
                            : MediaQuery.of(context).size.width * 0.8,
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
              // Sección: Últimas insignias
              Text('Últimas insignias',
                  style: Theme.of(context).textTheme.titleMedium
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
              }
            },
          ),
        );
      },
    );
  }
}
