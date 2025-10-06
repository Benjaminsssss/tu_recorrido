import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/colores.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint(
        '🔄 Iniciando ${_isLogin ? "login" : "registro"} con email: ${_emailController.text.trim()}',
      );
      debugPrint('🔄 Firebase App: ${FirebaseAuth.instance.app.name}');

      UserCredential? userCredential;

      if (_isLogin) {
        // Iniciar sesión con email y contraseña
        userCredential = await AuthService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        debugPrint('✅ Login exitoso para: ${userCredential?.user?.email}');
      } else {
        // Registrarse con email y contraseña
        userCredential = await AuthService.registerWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
        );
        debugPrint('✅ Registro exitoso para: ${userCredential?.user?.email}');

        // Limpiar formulario tras registro exitoso
        _clearForm();
      }

      // Mostrar mensaje de éxito
      if (mounted && userCredential != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLogin
                  ? '✅ Inicio de sesión exitoso'
                  : '✅ Registro exitoso. ¡Bienvenido!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar al menú principal
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('🔥 FirebaseAuthException: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil.';
          break;
        case 'email-already-in-use':
          errorMessage = 'Ya existe una cuenta con este correo.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo no es válido.';
          break;
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este correo.';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El registro con email/contraseña no está habilitado.';
          break;
        case 'invalid-api-key':
          errorMessage = 'Error de configuración: API key inválida.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      if (mounted) {
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      debugPrint('🔥 Error general: $e');
      if (mounted) {
        _showErrorDialog('Error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await AuthService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // Mostrar mensaje de bienvenida
        _showWelcomeDialog(userCredential.user?.displayName ?? 'Usuario');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        title: const Text(
          'Error',
          style: TextStyle(color: Coloressito.textPrimary),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Coloressito.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Coloressito.adventureGreen),
            ),
          ),
        ],
      ),
    );
  }

  void _showWelcomeDialog(String displayName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Coloressito.surfaceDark,
        title: Text(
          '¡Bienvenido, $displayName!',
          style: const TextStyle(color: Coloressito.textPrimary),
        ),
        content: const Text(
          'Tu pasaporte digital está listo. Comienza a explorar.',
          style: TextStyle(color: Coloressito.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushReplacementNamed(context, '/menu');
            },
            child: const Text(
              'Comenzar',
              style: TextStyle(color: Coloressito.adventureGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElement({
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de interfaz
          Container(
            decoration: const BoxDecoration(
              gradient: Coloressito.backgroundGradient,
            ),
          ),

          // Elementos decorativos
          Positioned(
            top: 120,
            right: 40,
            child: _buildFloatingElement(
              icon: Icons.location_on,
              color: Coloressito.badgeRed,
              size: 30,
            ),
          ),
          Positioned(
            top: 200,
            left: 60,
            child: _buildFloatingElement(
              icon: Icons.stars,
              color: Coloressito.badgeYellow,
              size: 25,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 24.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo/Icono igual al Home
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [
                                Coloressito.adventureGreen,
                                Coloressito.brightGreen,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Coloressito.glowColor,
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: Coloressito.borderLight,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.map,
                            size: 50,
                            color: Coloressito.textPrimary,
                          ),
                        ),

                        // Título
                        Text(
                          _isLogin
                              ? 'Inicia sesión para\ncontinuar tu recorrido'
                              : 'Regístrate para\nempezar a explorar\ny coleccionar\nrecuerdos',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Coloressito.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Campo nombre (solo en registro)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: Coloressito.textPrimary,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Nombre completo',
                              labelStyle: const TextStyle(
                                color: Coloressito.textSecondary,
                              ),
                              hintText: 'Ej: Juan Pérez',
                              hintStyle: const TextStyle(
                                color: Coloressito.textMuted,
                              ),
                              filled: true,
                              fillColor: Coloressito.surfaceDark,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Coloressito.borderLight,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Coloressito.adventureGreen,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa tu nombre completo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Campo email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: Coloressito.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Dirección de email',
                            labelStyle: const TextStyle(
                              color: Coloressito.textSecondary,
                            ),
                            hintText: 'nombre@dominio.com',
                            hintStyle: const TextStyle(
                              color: Coloressito.textMuted,
                            ),
                            filled: true,
                            fillColor: Coloressito.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Coloressito.borderLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Coloressito.adventureGreen,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Ingresa tu email';
                            }
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value.trim())) {
                              return 'Ingresa un email válido';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Campo contraseña
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Coloressito.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: const TextStyle(
                              color: Coloressito.textSecondary,
                            ),
                            filled: true,
                            fillColor: Coloressito.surfaceDark,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Coloressito.borderLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Coloressito.adventureGreen,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Coloressito.textMuted,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Ingresa tu contraseña';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),

                        if (_isLogin) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Implementar recuperar contraseña
                              },
                              child: const Text(
                                'Usar el número de teléfono',
                                style: TextStyle(
                                  color: Coloressito.adventureGreen,
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Botón principal
                        ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Coloressito.textPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.all(
                              Colors.transparent,
                            ),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              gradient: _isLoading
                                  ? null
                                  : Coloressito.buttonGradient,
                              color: _isLoading ? Coloressito.textMuted : null,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: _isLoading
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Coloressito.glowColor,
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Coloressito.textPrimary,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _isLogin ? 'Siguiente' : 'Siguiente',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Coloressito.textPrimary,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Separador
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(color: Coloressito.borderLight),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'o',
                                style: const TextStyle(
                                  color: Coloressito.textMuted,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(color: Coloressito.borderLight),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Botón Google
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Coloressito.textPrimary,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        'https://developers.google.com/identity/images/g-logo.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                          label: Text(
                            _isLoading
                                ? 'Conectando con Google...'
                                : '${_isLogin ? 'Iniciar sesión' : 'Registrarte'} con Google',
                            style: const TextStyle(
                              color: Coloressito.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Coloressito.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Coloressito.surfaceDark,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Botón Apple
                        OutlinedButton.icon(
                          onPressed: () {
                            // Implementar auth con Apple
                          },
                          icon: const Icon(
                            Icons.apple,
                            color: Coloressito.textPrimary,
                            size: 20,
                          ),
                          label: Text(
                            '${_isLogin ? 'Iniciar sesión' : 'Registrarte'} con Apple',
                            style: const TextStyle(
                              color: Coloressito.textPrimary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: Coloressito.borderLight,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Coloressito.surfaceDark,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Toggle login/registro
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? '¿No tienes una cuenta?'
                                  : '¿Ya tienes una cuenta?',
                              style: const TextStyle(
                                color: Coloressito.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: _toggleMode,
                              child: Text(
                                _isLogin ? 'Regístrate' : 'Iniciar sesión',
                                style: const TextStyle(
                                  color: Coloressito.adventureGreen,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
