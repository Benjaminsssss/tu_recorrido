import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/user_state.dart';
import '../../services/user_profile_service.dart';
import '../../services/follow_service.dart';
import '../../models/user_profile.dart';
import '../../screens/followers_list_screen.dart';

class UserProfileHeader extends StatefulWidget {
  final String? userId; // ID del usuario a mostrar (null = usuario actual)
  
  const UserProfileHeader({super.key, this.userId});

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader> {
  final ImagePicker _picker = ImagePicker();
  final _userProfileService = UserProfileService();
  final _followService = FollowService();
  
  int _seguidoresCount = 0;
  int _siguiendoCount = 0;
  bool _uploadingProfile = false;
  bool _uploadingBackground = false;
  
  // Datos del usuario a mostrar
  UserProfile? _userProfile;
  bool _loadingProfile = true;
  bool _isOwnProfile = true;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.userId == null) {
      // Es el perfil propio - cargar datos desde Firestore
      try {
        final currentUserId = _followService.currentUserId;
        if (currentUserId != null) {
          final profile = await _userProfileService.getUserProfile(currentUserId);
          
          if (profile != null) {
            setState(() {
              _isOwnProfile = true;
              _loadingProfile = false;
              _seguidoresCount = profile.followersCount;
              _siguiendoCount = profile.followingCount;
            });
          } else {
            setState(() {
              _isOwnProfile = true;
              _loadingProfile = false;
              _seguidoresCount = 0;
              _siguiendoCount = 0;
            });
          }
        }
      } catch (e) {
        print('Error cargando perfil propio: $e');
        setState(() {
          _isOwnProfile = true;
          _loadingProfile = false;
          _seguidoresCount = 0;
          _siguiendoCount = 0;
        });
      }
    } else {
      // Es el perfil de otro usuario
      try {
        final profile = await _userProfileService.getUserProfile(widget.userId!);
        
        if (profile != null) {
          final following = await _followServiceIsFollowingSafe(widget.userId!);
          if (!mounted) return;

          setState(() {
            _userProfile = profile;
            _isOwnProfile = false;
            _loadingProfile = false;
            _isFollowing = following;
            _seguidoresCount = profile.followersCount;
            _siguiendoCount = profile.followingCount;
          });
        }
      } catch (e) {
        print('Error cargando perfil: $e');
        setState(() => _loadingProfile = false);
      }
    }
  }

  // Helper safe call to avoid direct dependency issues in hot moves
  Future<bool> _followServiceIsFollowingSafe(String userId) async {
    try {
      return await _followService.isFollowing(userId);
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleFollow() async {
    if (widget.userId == null || _loadingProfile) return;

    try {
      if (_isFollowing) {
        await _followService.unfollowUser(widget.userId!);
        setState(() {
          _isFollowing = false;
          _seguidoresCount = (_seguidoresCount > 0) ? _seguidoresCount - 1 : 0;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Has dejado de seguir a ${_userProfile?.displayName ?? "este usuario"}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        await _followService.followUser(widget.userId!);
        setState(() {
          _isFollowing = true;
          _seguidoresCount++;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ahora sigues a este usuario!'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error al cambiar estado de seguimiento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el seguimiento: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _changeBackgroundImage() async {
    if (_uploadingBackground) return;
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
      );
      
      if (image == null) return;
      
      setState(() => _uploadingBackground = true);
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Subiendo imagen de fondo...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ));
      }

      if (!mounted) return;
      final userState = context.read<UserState>();
      if (userState.userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Subir a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${userState.userId}/background.jpg');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = storageRef.putFile(File(image.path));
      }
      
      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Guardar la URL en UserState (que también actualiza Firestore)
      await userState.setBackgroundUrl(downloadUrl);
      
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Imagen de fondo actualizada'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al cambiar imagen de fondo: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al cambiar imagen de fondo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingBackground = false);
      }
    }
  }

  Future<void> _changeProfileImage() async {
    if (_uploadingProfile) return;
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image == null) return;
      
      setState(() => _uploadingProfile = true);
      
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Subiendo foto de perfil...'),
            ],
          ),
          duration: const Duration(seconds: 30),
        ));
      }

      if (!mounted) return;
      final userState = context.read<UserState>();
      if (userState.userId == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Subir a Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users/${userState.userId}/profile.jpg');
      
      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        uploadTask = storageRef.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = storageRef.putFile(File(image.path));
      }
      
      // Esperar a que termine la subida
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Guardar la URL en UserState (que también actualiza Firestore)
      await userState.setAvatarUrl(downloadUrl);
      
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ Foto de perfil actualizada'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Error al cambiar foto de perfil: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error al cambiar foto de perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingProfile = false);
      }
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Cambiar foto de perfil'),
              onTap: () {
                Navigator.pop(context);
                _changeProfileImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: const Text('Cambiar imagen de fondo'),
              onTap: () {
                Navigator.pop(context);
                _changeBackgroundImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar nombre de usuario'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final userState = context.read<UserState>();
    final nameController = TextEditingController(text: userState.nombre);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de usuario',
                border: OutlineInputBorder(),
                helperText: 'Este nombre se mostrará en tu perfil y se sincronizará con Firebase',
              ),
              maxLength: 50,
            ),
            if (userState.email != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Correo electrónico:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userState.email!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await userState.setNombre(newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Perfil actualizado correctamente')),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    String? backgroundUrl;
    
    if (_isOwnProfile) {
      // Perfil propio: usar UserState
      final userState = context.watch<UserState>();
      backgroundUrl = userState.backgroundUrl;
    } else {
      // Perfil de otro usuario: usar _userProfile
      backgroundUrl = _userProfile?.backgroundURL;
    }
    
    debugPrint('🖼️ Background URL: $backgroundUrl (isOwnProfile: $_isOwnProfile)');
    
    if (backgroundUrl != null && backgroundUrl.isNotEmpty) {
      // Verificar si es una URL de Firebase Storage o una ruta local antigua
      if (backgroundUrl.startsWith('http')) {
        return Image.network(
          backgroundUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: double.infinity,
              height: 200,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('❌ Error cargando imagen de fondo: $error');
            return _buildDefaultBackground();
          },
        );
      } else {
        // Es una ruta local antigua, mostrar el fondo por defecto
        debugPrint('⚠️ URL de fondo es ruta local antigua, usando fondo por defecto');
        return _buildDefaultBackground();
      }
    }
    return _buildDefaultBackground();
  }

  Widget _buildDefaultBackground() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[400]!,
            Colors.blue[600]!,
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    String? avatarUrl;
    
    if (_isOwnProfile) {
      // Perfil propio: usar UserState
      final userState = context.watch<UserState>();
      avatarUrl = userState.avatarUrl;
    } else {
      // Perfil de otro usuario: usar _userProfile
      avatarUrl = _userProfile?.photoURL;
    }
    
    debugPrint('👤 Avatar URL: $avatarUrl (isOwnProfile: $_isOwnProfile)');
    
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('❌ Error cargando imagen de perfil: $error');
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey[300],
      child: const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, userState, _) {
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Background image container
              Stack(
                children: [
                  _buildBackgroundImage(),
                  // Dark overlay for better text/button visibility
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha((0.3 * 255).round()),
                        ],
                      ),
                    ),
                  ),
                  // Profile picture positioned in top-left
                  Positioned(
                    top: 20,
                    left: 20,
                    child: _buildProfileImage(),
                  ),
                  // Edit button in top-right (only for own profile)
                  if (_isOwnProfile)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Material(
                        color: Colors.black.withAlpha((0.5 * 255).round()),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _showEditOptions,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Follow/Unfollow button (only for other users' profiles)
                  if (!_isOwnProfile && !_loadingProfile)
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Material(
                        color: _isFollowing 
                          ? Colors.grey[700]?.withAlpha((0.9 * 255).round()) 
                          : const Color(0xFFDAA520).withAlpha((0.9 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _toggleFollow,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              _isFollowing ? 'Siguiendo' : 'Seguir',
                              style: TextStyle(
                                color: _isFollowing ? Colors.white : Colors.grey[900],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // User name positioned below profile picture
                  Positioned(
                    top: 150,
                    left: 20,
                    child: _loadingProfile
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isOwnProfile 
                            ? userState.nombre 
                            : (_userProfile?.displayName?.isNotEmpty == true 
                                ? _userProfile!.displayName! 
                                : _userProfile?.nombre ?? 'Usuario'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.grey[900]!,
                                blurRadius: 0,
                                offset: const Offset(-1, -1),
                              ),
                              Shadow(
                                color: Colors.grey[900]!,
                                blurRadius: 0,
                                offset: const Offset(1, -1),
                              ),
                              Shadow(
                                color: Colors.grey[900]!,
                                blurRadius: 0,
                                offset: const Offset(1, 1),
                              ),
                              Shadow(
                                color: Colors.grey[900]!,
                                blurRadius: 0,
                                offset: const Offset(-1, 1),
                              ),
                            ],
                          ),
                        ),
                  ),
                ],
              ),
              // Followers and Following counts
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem('Siguiendo', _siguiendoCount, () {
                        // Obtener el userId (si es perfil propio usa el actual, si no usa el pasado)
                        final targetUserId = widget.userId ?? _followService.currentUserId;
                        if (targetUserId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersListScreen(
                                userId: targetUserId,
                                type: 'following',
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildStatItem('Seguidores', _seguidoresCount, () {
                        // Obtener el userId (si es perfil propio usa el actual, si no usa el pasado)
                        final targetUserId = widget.userId ?? _followService.currentUserId;
                        if (targetUserId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersListScreen(
                                userId: targetUserId,
                                type: 'followers',
                              ),
                            ),
                          );
                        }
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
