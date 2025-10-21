import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _photoBase64;
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
      _selectedLocale = context.locale;
    });
    if (user != null) {
      final base64img = await ProfileService.getAvatarBase64(user.uid);
      final doc = await ProfileService.getUserProfile(user.uid);
      final data = doc?.data();
      if (data != null && mounted) {
        setState(() {
          final lang = data['languageCode'] as String?;
          if (lang != null && lang.isNotEmpty) {
            _selectedLocale = Locale(lang);
            context.setLocale(_selectedLocale!);
          }
          if ((data['displayName'] as String?)?.isNotEmpty ?? false) {
            _nameCtrl.text = data['displayName'];
          }
          _photoBase64 = base64img;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final x =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() {
        _localBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final currentLocale = context.locale;
      if (user != null) {
        await user.updateDisplayName(_nameCtrl.text.trim());
        // Guardar avatar como base64 en Firestore
        if (_localBytes != null) {
          await ProfileService.saveAvatarBase64(user.uid, _localBytes!);
          _photoBase64 = base64Encode(_localBytes!);
        }
        // Persistir en Firestore
        await ProfileService.updateUserProfile(user.uid, {
          'displayName': _nameCtrl.text.trim(),
          'languageCode': currentLocale.languageCode,
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('languageCode', currentLocale.languageCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${tr('save')} OK')),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundImage: _localBytes != null
                          ? MemoryImage(_localBytes!)
                          : (_photoBase64 != null && _photoBase64!.isNotEmpty)
                              ? MemoryImage(base64Decode(_photoBase64!))
                              : null,
                      child: (_photoBase64 == null && _localBytes == null)
                          ? const Icon(Icons.person, size: 56)
                          : null,
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _pickPhoto,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.camera_alt,
                                color: Colors.green[700], size: 20),
                          ),
                        ),
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
                maxLength: 32,
              ),
              const SizedBox(height: 12),
              TextFormField(
                readOnly: true,
                initialValue: user?.email ?? '',
                decoration: InputDecoration(labelText: tr('email')),
                maxLines: 1,
                style: const TextStyle(overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Locale>(
                initialValue: _selectedLocale ?? context.locale,
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
                          child: Text(loc.languageCode.toUpperCase(),
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (loc) async {
                  if (loc == null) return;
                  setState(() => _selectedLocale = loc);
                  await context.setLocale(loc);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('languageCode', loc.languageCode);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(tr('save'), overflow: TextOverflow.ellipsis),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await FirebaseAuth.instance.signOut();
                    if (mounted) navigator.pop();
                  },
                  child: Text(tr('sign_out'), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
