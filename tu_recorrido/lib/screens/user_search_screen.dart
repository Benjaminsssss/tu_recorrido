import 'package:flutter/material.dart';
import '../services/social_services.dart';
import '../models/social_models.dart';

/// Pantalla para buscar usuarios
class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _profileService = UserProfileService();
  final _searchController = TextEditingController();
  
  List<UserProfile> _results = [];
  List<UserProfile> _suggested = [];
  bool _isSearching = false;
  bool _isLoadingSuggestions = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    
    try {
      final followService = FollowService();
      final suggested = await followService.getSuggestedUsers(limit: 10);
      if (mounted) {
        setState(() {
          _suggested = suggested;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSuggestions = false);
      }
    }
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _profileService.searchUsers(query, limit: 20);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F7),
      appBar: AppBar(
        title: const Text('Buscar usuarios'),
        backgroundColor: const Color(0xFF156A79),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length >= 2) {
                  _search(value);
                } else if (value.isEmpty) {
                  setState(() => _results = []);
                }
              },
            ),
          ),

          // Contenido
          Expanded(
            child: _searchController.text.isEmpty
                ? _buildSuggestionsView()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsView() {
    if (_isLoadingSuggestions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_suggested.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay sugerencias',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sugerencias para seguir',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        ..._suggested.map((user) => _buildUserTile(user)),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron usuarios',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildUserTile(_results[index]),
    );
  }

  Widget _buildUserTile(UserProfile user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF156A79),
          backgroundImage: user.photoURL != null
              ? NetworkImage(user.photoURL!)
              : null,
          child: user.photoURL == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          user.displayNameOrEmail,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.ubicacion != null)
              Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      user.ubicacion!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            Text(
              '${user.badgesCount} insignias · ${user.placesVisitedCount} lugares',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF156A79),
        ),
        onTap: () {
          // Navegar al álbum del usuario
          Navigator.pushNamed(
            context,
            '/user-profile/${user.uid}',
          );
        },
      ),
    );
  }
}
