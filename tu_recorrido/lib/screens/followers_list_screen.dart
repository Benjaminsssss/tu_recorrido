import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'album.dart';

/// Pantalla para mostrar la lista de seguidores o seguidos de un usuario
class FollowersListScreen extends StatefulWidget {
  final String userId;
  final String type; // 'followers' o 'following'
  
  const FollowersListScreen({
    super.key,
    required this.userId,
    required this.type,
  });

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final String collection = widget.type == 'followers' ? 'followers' : 'following';
      
      // Obtener los documentos de la subcolección
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(widget.userId)
          .collection(collection)
          .get();

      // Cargar datos de cada usuario
      final List<Map<String, dynamic>> users = [];
      
      for (final doc in snapshot.docs) {
        final userId = doc.id;
        
        // Obtener datos del usuario
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          users.add({
            'id': userId,
            'displayName': userDoc.data()?['displayName'] ?? 
                          userDoc.data()?['nombre'] ?? 
                          'Usuario',
            'photoURL': userDoc.data()?['photoURL'] ?? 
                       userDoc.data()?['profileImage'],
            'bio': userDoc.data()?['bio'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
      if (mounted) {
        setState(() {
          _error = 'Error al cargar la lista';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'followers' ? 'Seguidores' : 'Siguiendo';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF156A79),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF156A79),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            widget.type == 'followers'
                                ? 'Aún no tienes seguidores'
                                : 'Aún no sigues a nadie',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return _UserListTile(
                          userId: user['id'],
                          displayName: user['displayName'],
                          photoURL: user['photoURL'],
                          bio: user['bio'],
                        );
                      },
                    ),
    );
  }
}

/// Widget de cada usuario en la lista
class _UserListTile extends StatelessWidget {
  final String userId;
  final String displayName;
  final String? photoURL;
  final String bio;

  const _UserListTile({
    required this.userId,
    required this.displayName,
    this.photoURL,
    required this.bio,
  });

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumScreen(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToProfile(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF156A79),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: photoURL != null && photoURL!.isNotEmpty
                      ? Image.network(
                          photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatar(),
                        )
                      : _defaultAvatar(),
                ),
              ),
              const SizedBox(width: 12),
              
              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Icono de flecha
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: 32,
        color: Colors.grey[600],
      ),
    );
  }
}
