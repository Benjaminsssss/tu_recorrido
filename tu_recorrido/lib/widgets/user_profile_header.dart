import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/user_state.dart';

class UserProfileHeader extends StatefulWidget {
  const UserProfileHeader({super.key});

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader> {
  final ImagePicker _picker = ImagePicker();
  int _seguidoresCount = 0;
  int _siguiendoCount = 0;
  bool _uploadingProfile = false;
  bool _uploadingBackground = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Cargar contadores
    setState(() {
      _seguidoresCount = 0;
      _siguiendoCount = 0;
    });
  }

  Future<void> _changeBackgroundImage() async {
    if (_uploadingBackground) return;
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
      );
      
      if (image == null) return;
      
      setState(() => _uploadingBackground = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
            duration: Duration(seconds: 30),
          ),
        );
      }
      
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Imagen de fondo actualizada'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al cambiar imagen de fondo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
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
            duration: Duration(seconds: 30),
          ),
        );
      }
      
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
      
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto de perfil actualizada'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error al cambiar foto de perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
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
    final userState = context.watch<UserState>();
    final backgroundUrl = userState.backgroundUrl;
    
    debugPrint('🖼️ Background URL: $backgroundUrl');
    
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

  Widget _buildProfileImage(UserState userState) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: userState.avatarUrl != null && userState.avatarUrl!.isNotEmpty
            ? (kIsWeb
                ? Image.network(
                    userState.avatarUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  )
                : Image.file(
                    File(userState.avatarUrl!),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  ))
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
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Profile picture positioned in top-left
                  Positioned(
                    top: 20,
                    left: 20,
                    child: _buildProfileImage(userState),
                  ),
                  // Edit button in top-right
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Material(
                      color: Colors.black.withOpacity(0.5),
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
                  // User name positioned below profile picture
                  Positioned(
                    top: 150,
                    left: 20,
                    child: Text(
                      userState.nombre,
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
                        // TODO: Navegar a lista de siguiendo
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lista de siguiendo - Próximamente')),
                        );
                      }),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildStatItem('Seguidores', _seguidoresCount, () {
                        // TODO: Navegar a lista de seguidores
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lista de seguidores - Próximamente')),
                        );
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