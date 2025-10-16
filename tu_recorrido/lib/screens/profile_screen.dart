import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _photoUrl;
  Uint8List? _localBytes;
  Locale? _selectedLocale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _nameCtrl.text = user?.displayName ?? '';
      _photoUrl = user?.photoURL;
      _selectedLocale = context.locale;
      // Nota: aquí podrías cargar Firestore para languageCode/photoUrl
    });
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() {
        _localBytes = bytes;
      });
      // TODO: Subir a Firebase Storage y obtener URL, luego persistir a Firestore
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameCtrl.text.trim());
        // TODO: si hay _localPhoto, subir a Storage y update photoURL
        // TODO: persistir languageCode en Firestore
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', context.locale.languageCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('save') + ' OK')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text(tr('profile'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: _localBytes != null
                        ? MemoryImage(_localBytes!)
                        : (_photoUrl != null && _photoUrl!.isNotEmpty)
                            ? NetworkImage(_photoUrl!) as ImageProvider
                            : null,
                    child: (_photoUrl == null && _localBytes == null)
                        ? const Icon(Icons.person, size: 48)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: ElevatedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.edit),
                      label: Text(tr('pick_photo')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(labelText: tr('display_name')),
              validator: (v) => (v == null || v.trim().isEmpty) ? ' ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              initialValue: user?.email ?? '',
              decoration: InputDecoration(labelText: tr('email')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Locale>(
              value: _selectedLocale ?? context.locale,
              decoration: InputDecoration(labelText: tr('language')),
              items: const [
                Locale('es'),
                Locale('en'),
                Locale('fr'),
                Locale('pt'),
                Locale('ru'),
              ]
                  .map((loc) => DropdownMenuItem(
                        value: loc,
                        child: Text(loc.languageCode.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (loc) async {
                if (loc == null) return;
                setState(() => _selectedLocale = loc);
                await context.setLocale(loc);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('languageCode', loc.languageCode);
                // TODO: FirestoreService.updateUserProfile(uid, {'languageCode': loc.languageCode});
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(tr('save')),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(tr('sign_out')),
            )
          ],
        ),
      ),
    );
  }
}
