import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../models/user_state.dart';
import '../models/regioycomu.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/colores.dart';
import 'escanerqr.dart';
import 'login.dart';
import '../services/profile_service.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

enum PerfilModo { hub, editar, configuracion }

class _PerfilState extends State<Perfil> with SingleTickerProviderStateMixin {
  PerfilModo _modo = PerfilModo.hub;
  double _sheetFraction = 0.92; // 92% alto al abrir
  bool _showingGeneralProgress = false;
  static const double minFraction = 0.7;
  static const double maxFraction = 0.92;
  late AnimationController _controller;
  late Animation<double> _blurAnim;
  late Animation<double> _dimAnim;
  String? _photoBase64;
  String? _nombre;
  String? _correo;
  String? _nivel;
  String _selectedRegion = '';
  String _selectedComuna = '';
  List<String> _comunas = [];
  Stream<Map<String, dynamic>>? _progresoStream;
  List<String> _sellos = [];
  List<String> _amigos = [];
  Locale? _selectedLocale;
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Uint8List? _localBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _blurAnim = Tween<double>(begin: 0, end: 12).animate(_controller);
    _dimAnim = Tween<double>(begin: 0, end: 0.18).animate(_controller);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = Provider.of<UserState>(context, listen: false);
      _nameCtrl.text = userState.nombre;
    });
    _loadUser();
    _controller.forward();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    String? base64img;
    if (user != null) {
      base64img = await ProfileService.getAvatarBase64(user.uid);
      
      // Inicializar regiones y comunas
      setState(() {
        // Obtener la lista de regiones del mapa
        if (_selectedRegion.isEmpty && regionesYComunas.isNotEmpty) {
          _selectedRegion = regionesYComunas.keys.first;
          _comunas = regionesYComunas[_selectedRegion] ?? [];
          if (_selectedComuna.isEmpty && _comunas.isNotEmpty) {
            _selectedComuna = _comunas.first;
            _updateProgresoStream(user.uid);
          }
        }
      });
    }
    
    setState(() {
      _photoBase64 = base64img;
      _nombre = user?.displayName ?? '';
      _correo = user?.email ?? '';
      _nivel = 'Nivel Viajero 1';
      _sellos = [];
      _amigos = [];
      _selectedLocale = Locale('es');
      _nameCtrl.text = _nombre ?? '';
    });
  }

  void _updateProgresoStream(String uid) {
    setState(() {
      _progresoStream = ProfileService.getComunaProgress(uid, _selectedComuna);
    });
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _sheetFraction -=
          details.primaryDelta! / MediaQuery.of(context).size.height;
      _sheetFraction = _sheetFraction.clamp(minFraction, maxFraction);
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_sheetFraction < 0.75) {
      _closeSheet();
    } else if (_sheetFraction > 0.85) {
      setState(() => _sheetFraction = maxFraction);
    } else {
      setState(() => _sheetFraction = minFraction);
    }
  }

  void _closeSheet() {
    HapticFeedback.lightImpact();
    _controller.reverse().then((_) {
      Navigator.of(context).maybePop();
    });
  }

  void _switchToEditar() {
    setState(() => _modo = PerfilModo.editar);
    HapticFeedback.lightImpact();
  }

  void _switchToHub() {
    // final userState = Provider.of<UserState>(context, listen: false);
    setState(() {
      _modo = PerfilModo.hub;
      // Si hay avatar persistido en Provider, úsalo como respaldo
      // Ya no se usa avatarUrl ni _photoUrl, solo base64/localBytes
    });
    HapticFeedback.lightImpact();
  }

  void _switchToConfiguracion() {
    setState(() => _modo = PerfilModo.configuracion);
    HapticFeedback.lightImpact();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _localBytes = bytes;
        // No anulamos _photoUrl aún; la UI prioriza _localBytes automáticamente
      });
    }
  }

  Future<Uint8List> _compressImage(Uint8List input) async {
    // Decodificar imagen
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;

    // Redimensionar si es muy grande (max 512px en el lado mayor)
    const maxSide = 512;
    img.Image resized = decoded;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: maxSide);
      } else {
        resized = img.copyResize(decoded, height: maxSide);
      }
    }

    // Comprimir a JPG calidad 80 (buen balance peso/calidad)
    final jpg = img.encodeJpg(resized, quality: 80);
    return Uint8List.fromList(jpg);
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final nuevoNombre = _nameCtrl.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    final userState = Provider.of<UserState>(context, listen: false);

    try {
      // Actualizar nombre local
      setState(() => _nombre = nuevoNombre);
      await userState.setNombre(nuevoNombre);

      // Ya no se usa finalUrl ni _photoUrl

      // Si hay imagen nueva, comprimir y subir a Firebase Storage
      if (_localBytes != null && user != null) {
        final compressed = await _compressImage(_localBytes!);
        await ProfileService.saveAvatarBase64(user.uid, compressed);
        await user.updateDisplayName(nuevoNombre);
        await user.reload();
        await ProfileService.updateUserProfile(user.uid, {
          'displayName': nuevoNombre,
        });
        setState(() {
          _photoBase64 = base64Encode(compressed);
          _localBytes = null;
        });
        await Future.delayed(const Duration(milliseconds: 100));
      } else if (user != null) {
        await user.updateDisplayName(nuevoNombre);
        await user.reload();
        await ProfileService.updateUserProfile(user.uid, {
          'displayName': nuevoNombre,
        });
      }

      setState(() => _saving = false);

      // Esperar a que Provider notifique y la UI se reconstruya
      await Future.delayed(const Duration(milliseconds: 200));

      // Cerrar el modal de edición y volver al hub automáticamente
      if (mounted) {
        // Si estamos en modo editar, cambiamos a hub
        if (_modo == PerfilModo.editar) {
          setState(() => _modo = PerfilModo.hub);
        }
        // Cerrar el modal si está abierto (asegurando mounted tras el await)
        if (!mounted) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
        // Mostrar confirmación (reverificar mounted por seguridad)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        // Blur + dim del fondo
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurAnim.value,
                sigmaY: _blurAnim.value,
              ),
              child: Container(
                color: Color.fromARGB((_dimAnim.value * 255).round(), 0, 0, 0),
              ),
            );
          },
        ),
        // Sheet principal con degradado rural (beige a verde claro)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          bottom: 0,
          height: size.height * _sheetFraction,
          child: GestureDetector(
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF5E9D2), // beige rural
                            Color(0xFFD6EFC7), // verde muy claro
                            Colors.white,
                          ],
                          stops: [0.0, 0.18, 1.0],
                        ),
                  color: isDark ? Coloressito.backgroundDark : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(22)),
                  elevation: 0,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Handle visual
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Color.fromARGB((0.35 * 255).round(), 188, 161,
                              119), // marrón claro
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _modo == PerfilModo.hub
                            ? _buildHub(context, isDark)
                            : (_modo == PerfilModo.editar
                                ? _buildEditar(context, isDark)
                                : _buildConfiguracion(context, isDark)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHub(BuildContext context, bool isDark) {
    final handle = _correo != null && _correo!.contains('@')
        ? '@${_correo!.split('@')[0].replaceAll(RegExp(r'\s'), '').toLowerCase()}'
        : '@usuario';
    // final userState = Provider.of<UserState>(context);

    // Determinar fuente de avatar: prioridad local bytes > base64 > ícono
    ImageProvider? avatarProvider;
    if (_localBytes != null) {
      avatarProvider = MemoryImage(_localBytes!);
    } else if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        avatarProvider = MemoryImage(base64Decode(_photoBase64!));
      } catch (_) {}
    }
    // ...existing code...
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        // Header compacto
        Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFFD6EFC7), // verde claro rural
              backgroundImage: avatarProvider,
              child: (avatarProvider == null)
                  ? Icon(Icons.person,
                      color: const Color(0xFF7C6F57), // marrón rural
                      size: 40)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              _nombre ?? '',
              style: const TextStyle(
                fontFamily: 'Pacifico',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF7C6F57), // marrón rural
              ),
            ),
            const SizedBox(height: 2),
            Text(handle,
                style: const TextStyle(color: Color(0xFFBCA177), fontSize: 15)),
            const SizedBox(height: 2),
            Text(_nivel ?? 'Nivel Viajero 1',
                style: const TextStyle(
                    color: Color(0xFF7C9A5B), // verde hoja
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
        const SizedBox(height: 18),
        // Quick actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _QuickAction(
                icon: Icons.edit,
                label: 'Editar',
                onTap: _switchToEditar,
                iconColor: Color(0xFF7C9A5B)),
            _QuickAction(
                icon: Icons.settings,
                label: 'Ajustes',
                onTap: _switchToConfiguracion,
                iconColor: Color(0xFFBCA177)),
            _QuickAction(
              icon: Icons.qr_code,
              label: 'QR',
              onTap: () {
                Navigator.pop(context); // Cerrar el bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EscanerQRScreen()),
                );
              },
              iconColor: Color(0xFF7C6F57),
            ),
            _QuickAction(
                icon: Icons.share,
                label: 'Compartir',
                onTap: () {},
                iconColor: Color(0xFF7C9A5B)),
          ],
        ),
        const SizedBox(height: 18),
        // Separador rural
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildComunaProgressCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildSavedPlacesCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildStampsCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildStreakCard(),
        const SizedBox(height: 10),
        Divider(
            height: 1,
            thickness: 1,
            color: Color.fromARGB((0.18 * 255).round(), 188, 161, 119)),
        const SizedBox(height: 14),
        _buildFriendsCard(),
      ],
    );
  }

  Widget _buildEditar(BuildContext context, bool isDark) {
    // final userState = Provider.of<UserState>(context);

    // Determinar fuente de avatar: prioridad local bytes > base64 > ícono
    ImageProvider? avatarProvider;
    if (_localBytes != null) {
      avatarProvider = MemoryImage(_localBytes!);
    } else if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
      try {
        avatarProvider = MemoryImage(base64Decode(_photoBase64!));
      } catch (_) {}
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
              onPressed: _switchToHub,
              splashRadius: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Editar perfil',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor:
                    Coloressito.adventureGreen.withValues(alpha: 0.18),
                backgroundImage: avatarProvider,
                child: (avatarProvider == null)
                    ? Icon(Icons.person,
                        color: Coloressito.adventureGreen, size: 48)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.camera_alt,
                          color: Coloressito.adventureGreen, size: 22),
                    ),
                  ),
                ),
              ),
              if (_saving)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withAlpha((0.7 * 255).round()),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nombre de usuario'),
                maxLength: 32,
                validator: (v) => v != null && v.trim().length < 6
                    ? 'Mínimo 6 caracteres'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _correo,
                decoration: const InputDecoration(labelText: 'Correo'),
                readOnly: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _guardarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Coloressito.adventureGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfiguracion(BuildContext context, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver',
              onPressed: _switchToHub,
              splashRadius: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Ajustes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Selector de idioma
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading: Icon(Icons.language, color: Coloressito.adventureGreen),
            title: const Text('Idioma'),
            subtitle: Text(_selectedLocale?.languageCode.toUpperCase() ?? 'ES'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
        ),
        const SizedBox(height: 12),
        // Tema (placeholder para futuro)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading:
                Icon(Icons.brightness_6, color: Coloressito.adventureGreen),
            title: const Text('Tema'),
            subtitle: Text(isDark ? 'Oscuro' : 'Claro'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Notificaciones (placeholder para futuro)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading:
                Icon(Icons.notifications, color: Coloressito.adventureGreen),
            title: const Text('Notificaciones'),
            subtitle: const Text('Configurar alertas'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Privacidad (placeholder para futuro)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          child: ListTile(
            leading: Icon(Icons.privacy_tip, color: Coloressito.adventureGreen),
            title: const Text('Privacidad'),
            subtitle: const Text('Configurar privacidad'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Debug Auth (temporal)
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          color: Colors.orange[50],
          child: ListTile(
            leading: Icon(Icons.bug_report, color: Colors.orange[600]),
            title: const Text('Debug Auth'),
            subtitle: const Text('Diagnosticar problema de auth'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.pushNamed(context, '/debug-auth'),
          ),
        ),
        const SizedBox(height: 32),
        // Cerrar sesión
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Español'),
              leading: Icon(
                _selectedLocale == const Locale('es')
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _selectedLocale == const Locale('es')
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              onTap: () {
                final v = const Locale('es');
                setState(() => _selectedLocale = v);
                context.setLocale(v);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              leading: Icon(
                _selectedLocale == const Locale('en')
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: _selectedLocale == const Locale('en')
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
              onTap: () {
                final v = const Locale('en');
                setState(() => _selectedLocale = v);
                context.setLocale(v);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      // Primero cerrar el bottom sheet con animación
      if (mounted) {
        _controller.reverse().then((_) async {
          // Cerrar sesión en Firebase
          await FirebaseAuth.instance.signOut();

          // Navegar a la pantalla de login eliminando todas las rutas anteriores
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        });
      }
    }
  }



  Widget _buildSavedPlacesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: InkWell(
        onTap: () {
          // Navegar a la pantalla de lugares guardados
          Navigator.pushNamed(context, '/saved-places');
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Color(0xFF2B6B7F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lugares guardados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Ver tus lugares favoritos',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStampsCard() {
    final empty = _sellos.isEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sellos recientes',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: empty
                  ? Center(
                      child: Text(
                          'Sin sellos. Explora cerca para conseguir uno.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sellos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => CircleAvatar(
                        backgroundColor: Coloressito.badgeBlue,
                        child: Text(_sellos[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComunaProgressCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Progreso',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: Icon(
                        _showingGeneralProgress ? Icons.location_on : Icons.public,
                        size: 20,
                      ),
                      label: Text(
                        _showingGeneralProgress ? 'Ver por comuna' : 'Ver total país',
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        setState(() {
                          _showingGeneralProgress = !_showingGeneralProgress;
                          if (_showingGeneralProgress) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _progresoStream = ProfileService.getTotalProgress(user.uid);
                            }
                          } else if (_selectedComuna.isNotEmpty) {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _updateProgresoStream(user.uid);
                            }
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (!_showingGeneralProgress) ...[
              Row(
                children: [
                  Text(
                    'Región: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRegion.isEmpty ? null : _selectedRegion,
                      hint: const Text('Selecciona una región'),
                      selectedItemBuilder: (context) {
                        final list = regionesYComunas.keys.toList();
                        return list
                            .map((region) => Text(
                                  region,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ))
                            .toList();
                      },
                      items: regionesYComunas.keys.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRegion = newValue;
                            _comunas = regionesYComunas[newValue] ?? [];
                            _selectedComuna = _comunas.isNotEmpty ? _comunas.first : '';
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _updateProgresoStream(user.uid);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Comuna: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedComuna.isEmpty ? null : _selectedComuna,
                      hint: const Text('Selecciona una comuna'),
                      selectedItemBuilder: (context) {
                        final list = _comunas;
                        return list
                            .map((comuna) => Text(
                                  comuna,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ))
                            .toList();
                      },
                      items: _comunas.map((comuna) {
                        return DropdownMenuItem(
                          value: comuna,
                          child: Text(comuna),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedComuna = newValue;
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              _updateProgresoStream(user.uid);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (_progresoStream != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: MediaQuery.of(context).size.width - 40,
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: _progresoStream,
                  builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final progress = snapshot.data!;
                  final visitados = progress['visitados'] ?? 0;
                  final total = progress['total'] ?? 0;
                  final porcentaje = total > 0 ? (visitados / total * 100) : 0.0;

                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                        _showingGeneralProgress 
                            ? 'Progreso total en Chile'
                            : 'Progreso en $_selectedComuna',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: porcentaje / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$visitados de $total lugares visitados (${porcentaje.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    ),
                    );
                  },
                ),
              ),
            ],
          ],
      ),
    )
    );
  }
  Widget _buildStreakCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Racha de exploración',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Coloressito.badgeRed),
                const SizedBox(width: 8),
                Text('0 días seguidos',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsCard() {
    final empty = _amigos.isEmpty;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
      color: Coloressito.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Amigos cercanos',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: empty
                  ? Center(
                      child: Text(
                          'Sin amigos cercanos. Explora cerca para conectar.',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _amigos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => CircleAvatar(
                        backgroundColor: Coloressito.badgeGreen,
                        child: Text(_amigos[i]),
                      ),
                    ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF5E9D2), // beige rural
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB((0.13 * 255).round(), 188, 161, 119),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: const Color(0xFFBCA177), width: 1.2),
            ),
            child: Icon(icon,
                color: iconColor ?? const Color(0xFF7C9A5B), size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7C6F57))),
      ],
    );
  }
}
