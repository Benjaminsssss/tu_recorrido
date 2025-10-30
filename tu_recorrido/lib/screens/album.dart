import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/bottom_nav_bar.dart';

/// Album/colección: muestra insignias (badges) y sus fotos asociadas.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

enum AlbumItemType { badge, photo }

class AlbumItem {
  final String id;
  final AlbumItemType type;
  final String title;
  final String? parentId; // si es foto, referencia a la insignia
  final String? imagePath; // asset or file path
  final String? location;
  final DateTime date;
  String? description;

  AlbumItem({
    required this.id,
    required this.type,
    required this.title,
    this.parentId,
    this.imagePath,
    this.location,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.toString(),
        'title': title,
        'parentId': parentId,
        'imagePath': imagePath,
        'location': location,
        'date': date.toIso8601String(),
        'description': description,
      };

  static AlbumItem fromJson(Map<String, dynamic> j) {
    return AlbumItem(
      id: j['id'] ?? UniqueKey().toString(),
      type: j['type'] == 'AlbumItemType.photo' ? AlbumItemType.photo : AlbumItemType.badge,
      title: j['title'] ?? 'Item',
      parentId: j['parentId'],
      imagePath: j['imagePath'],
      location: j['location'],
      date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      description: j['description'],
    );
  }
}

class _AlbumScreenState extends State<AlbumScreen> {
  final List<AlbumItem> _items = [];
  int _currentIndex = 1; // 0=Inicio,1=Colección,2=Mapa
  late SharedPreferences _prefs;
  final ImagePicker _picker = ImagePicker();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getStringList('album_items') ?? [];
    _items.clear();
    for (final s in raw) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        _items.add(AlbumItem.fromJson(m));
      } catch (_) {}
    }
    _items.sort((a, b) => b.date.compareTo(a.date));
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveItems() async {
    final raw = _items.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList('album_items', raw);
  }

  int _totalPhotosCount() => _items.where((e) => e.type == AlbumItemType.photo).length;

  Future<void> _addPhotoFor(String parentId) async {
    if (_totalPhotosCount() >= 10) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Has alcanzado el límite de 10 fotos')));
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final newItem = AlbumItem(
      id: UniqueKey().toString(),
      type: AlbumItemType.photo,
      title: 'Foto',
      parentId: parentId,
      imagePath: file.path,
      location: null,
      date: DateTime.now(),
    );

    setState(() => _items.insert(0, newItem));
    await _saveItems();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📸 Foto agregada al álbum')));
  }

  void _openDetail(AlbumItem item) async {
    final edited = await showModalBottomSheet<AlbumItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final TextEditingController descCtrl = TextEditingController(text: item.description ?? '');
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildItemImage(item, width: 240, height: 160),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Fecha: ${item.date.toLocal().toString().split('.').first}'),
                  if (item.location != null) Text('Ubicación: ${item.location}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción personal'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                      ElevatedButton(
                        onPressed: () {
                          item.description = descCtrl.text.trim();
                          Navigator.pop(context, item);
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (edited != null) {
      final idx = _items.indexWhere((e) => e.id == edited.id);
      if (idx != -1) {
        setState(() => _items[idx] = edited);
        await _saveItems();
      }
    }
  }

  Widget _buildItemImage(AlbumItem item, {double? width, double? height}) {
    if (item.type == AlbumItemType.photo && item.imagePath != null) {
      final f = File(item.imagePath!);
      if (f.existsSync()) {
        return Image.file(f, width: width, height: height, fit: BoxFit.cover);
      }
    }
    return Container(
      width: width ?? 120,
      height: height ?? 90,
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.verified, size: 40, color: Colors.grey)),
    );
  }

  void _onNavChanged(int idx) {
    if (idx == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (idx == 2) {
      Navigator.pushNamed(context, '/menu');
    } else {
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Colección'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: _items.where((e) => e.type == AlbumItemType.badge).isEmpty ? _buildEmptyStateNoBadges(theme) : _buildBadgesList(context),
            ),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onChanged: _onNavChanged),
    );
  }

  Widget _buildEmptyStateNoBadges(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: const Icon(Icons.photo_album, size: 56, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Text('Aún no has desbloqueado insignias', style: theme.textTheme.titleMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 8),
          const Text(
            'Escanea códigos QR en las estaciones para desbloquear insignias.\nMientras no tengas insignias, no podrás agregar fotos al álbum.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesList(BuildContext context) {
    final badges = _items.where((e) => e.type == AlbumItemType.badge).toList();
    return ListView.separated(
      itemCount: badges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final badge = badges[index];
        final photos = _items.where((i) => i.type == AlbumItemType.photo && i.parentId == badge.id).toList();
        final canAdd = _totalPhotosCount() < 10;
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 72, height: 72, child: _buildItemImage(badge, width: 72, height: 72))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(badge.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    if (canAdd)
                      IconButton(
                        onPressed: () => _addPhotoFor(badge.id),
                        icon: const Icon(Icons.add_a_photo),
                        tooltip: 'Agregar foto a esta insignia',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: photos.isEmpty
                      ? Center(child: Text('No hay fotos para esta insignia', style: TextStyle(color: Colors.grey.shade600)))
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final p = photos[i];
                            return GestureDetector(
                              onTap: () => _openDetail(p),
                              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 140, height: 96, child: _buildItemImage(p, width: 140, height: 96))),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


