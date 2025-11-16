import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:tu_recorrido/services/social/follow_service.dart';
import '../../screens/album.dart';

/// Carrusel horizontal de sugerencias de seguidores tipo Instagram
class FollowSuggestionsCarousel extends StatefulWidget {
  const FollowSuggestionsCarousel({super.key});

  @override
  State<FollowSuggestionsCarousel> createState() =>
      _FollowSuggestionsCarouselState();
}

class _FollowSuggestionsCarouselState
    extends State<FollowSuggestionsCarousel> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final Set<String> _followedUsers = {};
  final _followService = FollowService();
  StreamSubscription<QuerySnapshot>? _followingSubscription;

  @override
  void initState() {
    super.initState();
    _loadFollowedUsers();
    _listenToFollowingChanges();
  }
  
  @override
  void dispose() {
    _followingSubscription?.cancel();
    super.dispose();
  }
  
  /// Escucha cambios en tiempo real de los usuarios que sigo
  void _listenToFollowingChanges() {
    if (currentUserId == null) return;
    
    _followingSubscription = FirebaseFirestore.instance
        .collection('following')
        .doc(currentUserId)
        .collection('following')
        .snapshots()
        .listen((snapshot) {
      final followedIds = snapshot.docs.map((doc) => doc.id).toSet();
      if (mounted) {
        setState(() {
          _followedUsers.clear();
          _followedUsers.addAll(followedIds);
        });
        debugPrint('🔄 Actualizado: ahora sigues a ${_followedUsers.length} usuarios');
      }
    }, onError: (e) {
      debugPrint('⚠️ Error en listener de following: $e');
    });
  }

  Future<void> _loadFollowedUsers() async {
    if (currentUserId == null) return;
    
    try {
      // Cargar desde la subcolección following
      final followingSnapshot = await FirebaseFirestore.instance
          .collection('following')
          .doc(currentUserId)
          .collection('following')
          .get();
      
      final followedIds = followingSnapshot.docs.map((doc) => doc.id).toSet();
      
      setState(() {
        _followedUsers.addAll(followedIds);
      });
      
      debugPrint('✅ Cargados ${_followedUsers.length} usuarios seguidos');
    } catch (e) {
      debugPrint('⚠️ Error cargando usuarios seguidos: $e');
      // Continuar sin problema, simplemente no filtraremos por usuarios seguidos
    }
  }

  Future<void> _followUser(String userId) async {
    if (currentUserId == null) return;

    try {
      // Usar el servicio de follow existente
      await _followService.followUser(userId);

      // No es necesario actualizar manualmente _followedUsers
      // El listener en tiempo real lo hará automáticamente
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Ahora sigues a este usuario!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF156A79),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al seguir usuario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      debugPrint('⚠️ FollowSuggestions: Usuario no autenticado');
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        // Si hay error, ocultar el carrusel
        if (snapshot.hasError) {
          debugPrint('❌ FollowSuggestions: Error en snapshot: ${snapshot.error}');
          return const SizedBox.shrink();
        }
        
        // Si no hay datos, ocultar el carrusel
        if (!snapshot.hasData) {
          debugPrint('⚠️ FollowSuggestions: No hay datos de snapshot');
          return const SizedBox.shrink();
        }
        
        // Si no hay documentos, ocultar el carrusel
        if (snapshot.data!.docs.isEmpty) {
          debugPrint('⚠️ FollowSuggestions: No hay documentos en usuarios');
          return const SizedBox.shrink();
        }

        debugPrint('✅ FollowSuggestions: ${snapshot.data!.docs.length} usuarios encontrados');

        // Filtrar usuarios que NO seguimos y que no somos nosotros mismos
        final suggestions = snapshot.data!.docs.where((doc) {
          final uid = doc.id;
          final isNotMe = uid != currentUserId;
          final notFollowing = !_followedUsers.contains(uid);
          return isNotMe && notFollowing;
        }).toList();

        debugPrint('✅ FollowSuggestions: ${suggestions.length} sugerencias después de filtrar');

        // Si no hay sugerencias, OCULTAR el carrusel completamente
        if (suggestions.isEmpty) {
          debugPrint('✅ FollowSuggestions: No hay más sugerencias - ocultando carrusel');
          return const SizedBox.shrink();
        }

        // Limitar a máximo 10 sugerencias
        final limitedSuggestions = suggestions.take(10).toList();

        return _buildCarousel(limitedSuggestions);
      },
    );
  }
  
  /// Construye el carrusel con datos reales de Firebase
  Widget _buildCarousel(List<QueryDocumentSnapshot> suggestions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Sugerencias para ti',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  Icon(
                    Icons.people_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Carrusel horizontal
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final userDoc = suggestions[index];
                  final data = userDoc.data() as Map<String, dynamic>?;
                  
                  if (data == null) return const SizedBox.shrink();

                  final displayName = data['displayName'] as String? ?? 
                                     data['nombre'] as String? ?? 
                                     'Usuario';
                  final photoUrl = data['photoURL'] as String? ?? 
                                  data['profileImage'] as String?;
                  final bio = data['bio'] as String? ?? '';
                  final userId = userDoc.id;

                  return _SuggestionCard(
                    displayName: displayName,
                    photoUrl: photoUrl,
                    bio: bio,
                    userId: userId,
                    onFollow: () => _followUser(userId),
                    isFollowing: _followedUsers.contains(userId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card individual de sugerencia de seguidor
class _SuggestionCard extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final String bio;
  final String userId;
  final VoidCallback onFollow;
  final bool isFollowing;

  const _SuggestionCard({
    required this.displayName,
    this.photoUrl,
    required this.bio,
    required this.userId,
    required this.onFollow,
    required this.isFollowing,
  });

  void _navigateToProfile(BuildContext context) {
    // Navegar al álbum/perfil del usuario
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar - Clickeable
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF156A79),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? Image.network(
                        photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAvatar(),
                      )
                    : _defaultAvatar(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Nombre - Clickeable
          GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                displayName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Bio corta
          if (bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                bio,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Botón Seguir
          ElevatedButton(
            onPressed: isFollowing ? null : onFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing 
                  ? Colors.grey[400] 
                  : const Color(0xFF156A79),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: Text(
              isFollowing ? 'Siguiendo' : 'Seguir',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.grey[600],
      ),
    );
  }
}
