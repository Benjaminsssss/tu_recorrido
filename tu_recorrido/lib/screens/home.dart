import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../components/white_card.dart';
import '../components/collection_card.dart';
import '../components/bottom_pill_nav.dart';
import '../widgets/home_header.dart';
import 'package:provider/provider.dart';
import '../models/user_state.dart';

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
    final userState = Provider.of<UserState>(context);
    final nombre = userState.nombre;
  final avatarUrl = userState.avatarUrl ?? '';
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
                          tr('collect_world'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr('home_hero_subtitle'),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildChipWithShadow(tr('discover')),
                              const SizedBox(width: 8),
                              _buildChipWithShadow(tr('explore')),
                              const SizedBox(width: 8),
                              _buildChipWithShadow(tr('collect')),
                            ],
                          ),
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
                  Text(tr('nearby'),
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
                          title: tr('featured_place', namedArgs: {'n': '${i + 1}'}),
                          subtitle: '${tr('distance_meters_abbrev', namedArgs: {'m': '${200 * (i + 1)}'})} • ${tr('open_until', namedArgs: {'time': '18:00'})}',
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
                  Text(tr('latest_badges'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    6,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Material(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Chip(
                            avatar: const CircleAvatar(child: Icon(Icons.emoji_events)),
                            label: Text(tr('badge', namedArgs: {'n': '${i + 1}'}), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ),
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

  // Helper para crear chips con sombra consistente
  Widget _buildChipWithShadow(String label) {
    return Material(
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Chip(
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
