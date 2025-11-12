import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/social_services.dart';
import '../models/social_models.dart';
import '../models/album_photo.dart';

/// Pantalla de perfil de usuario (puede ser el propio o de otro usuario)
/// Si es de otro usuario, muestra botón "Seguir" y solo modo visualización
class UserProfileScreen extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const UserProfileScreen({
    super.key,
    required this.userId,
  }) : isOwnProfile = false;

  // Constructor para el perfil propio (desde el álbum existente)
  const UserProfileScreen.own({
    super.key,
    required this.userId,
  }) : isOwnProfile = true;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final _followService = FollowService();
  final _profileService = UserProfileService();

  late TabController _tabController;
  bool _isFollowing = false;
  bool _isLoadingFollow = false;

  // Stream para obtener fotos del álbum de un usuario
  Stream<List<AlbumPhoto>> _getUserAlbumPhotosStream(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('album_photos')
        .orderBy('uploadDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AlbumPhoto.fromJson(data);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkFollowStatus() async {
    if (widget.isOwnProfile) return;
    
    final status = await _followService.isFollowing(widget.userId);
    if (mounted) {
      setState(() => _isFollowing = status);
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoadingFollow) return;

    setState(() => _isLoadingFollow = true);

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dejaste de seguir a este usuario')),
          );
        }
      } else {
        await _followService.followUser(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ahora sigues a este usuario')),
          );
        }
      }
      
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFollow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = widget.userId == currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.getUserProfileStream(widget.userId),
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!profileSnapshot.hasData || profileSnapshot.data == null) {
            return const Center(child: Text('Usuario no encontrado'));
          }

          final profile = profileSnapshot.data!;

          return CustomScrollView(
            slivers: [
              // AppBar con foto de fondo
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF156A79),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagen de fondo
                      if (profile.backgroundURL != null)
                        Image.network(
                          profile.backgroundURL!,
                          fit: BoxFit.cover,
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF156A79),
                                Color(0xFF0D4A56),
                              ],
                            ),
                          ),
                        ),
                      // Overlay oscuro
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      // Avatar y nombre en la parte inferior
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white,
                              backgroundImage: profile.photoURL != null
                                  ? NetworkImage(profile.photoURL!)
                                  : null,
                              child: profile.photoURL == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            // Nombre
                            Text(
                              profile.displayNameOrEmail,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (profile.ubicacion != null)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.place,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.ubicacion!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Estadísticas y botón seguir
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      // Estadísticas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Insignias', profile.badgesCount),
                          _buildStat('Lugares', profile.placesVisitedCount),
                          _buildStatButton(
                            'Seguidores',
                            profile.followersCount,
                            () => _showFollowersList(context, widget.userId),
                          ),
                          _buildStatButton(
                            'Siguiendo',
                            profile.followingCount,
                            () => _showFollowingList(context, widget.userId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Botón Seguir (solo si no es tu perfil)
                      if (!isOwnProfile)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingFollow ? null : _toggleFollow,
                              icon: Icon(
                                _isFollowing
                                    ? Icons.person_remove
                                    : Icons.person_add,
                              ),
                              label: _isLoadingFollow
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isFollowing ? 'Siguiendo' : 'Seguir',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey[600]
                                    : const Color(0xFF156A79),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF156A79),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF156A79),
                    tabs: const [
                      Tab(icon: Icon(Icons.grid_on), text: 'Álbum'),
                      Tab(icon: Icon(Icons.stars), text: 'Insignias'),
                    ],
                  ),
                ),
              ),

              // Contenido de los tabs
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAlbumTab(profile),
                    _buildBadgesTab(profile),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatButton(String label, int value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF156A79),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumTab(UserProfile profile) {
    return FutureBuilder<bool>(
      future: _profileService.canViewAlbum(widget.userId),
      builder: (context, canViewSnapshot) {
        if (canViewSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final canView = canViewSnapshot.data ?? false;

        if (!canView) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Álbum privado',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Este usuario ha configurado su álbum como privado',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<AlbumPhoto>>(
          stream: _getUserAlbumPhotosStream(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final photos = snapshot.data ?? [];

            if (photos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Sin fotos aún',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return InkWell(
                  onTap: () => _showPhotoDetail(photo),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      photo.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBadgesTab(UserProfile profile) {
    return FutureBuilder<bool>(
      future: _profileService.canViewBadges(widget.userId),
      builder: (context, canViewSnapshot) {
        if (canViewSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final canView = canViewSnapshot.data ?? false;

        if (!canView) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Insignias privadas',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _profileService.getUserBadgesStream(widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final badges = snapshot.data ?? [];

            if (badges.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Sin insignias aún',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return _buildBadgeCard(badge);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge) {
    // Aquí necesitarías obtener los detalles de la insignia desde /insignias/{id}
    // Por ahora, mostrar estructura básica
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stars, size: 64, color: Colors.amber[700]),
          const SizedBox(height: 8),
          Text(
            badge['id'],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPhotoDetail(AlbumPhoto photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(photo.imageUrl),
            if (photo.description != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(photo.description!),
              ),
          ],
        ),
      ),
    );
  }

  void _showFollowersList(BuildContext context, String userId) {
    // TODO: Navegar a pantalla de lista de seguidores
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista de seguidores - próximamente')),
    );
  }

  void _showFollowingList(BuildContext context, String userId) {
    // TODO: Navegar a pantalla de lista de seguidos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lista de seguidos - próximamente')),
    );
  }
}

// Delegate para el TabBar sticky
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
