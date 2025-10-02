import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool obscure = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);
    try {
      final cred = await AuthService.signInWithEmail(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      // si no está verificado, salimos y pedimos verificación
      if (!(cred?.user?.emailVerified ?? false)) {
        await AuthService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verifica tu correo para continuar.'),
              action: SnackBarAction(
                label: 'Reenviar',
                onPressed: () async {
                  try {
                    await AuthService.resendEmailVerification();
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📧 Enviamos un nuevo correo de verificación')),
                    );
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ $e')),
                    );
                  }
                },
              ),
            ),
          );
        }
        return;
      }

      // ok, pasa a home
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Bienvenido')),
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _resetPass() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu correo para recuperar')),
      );
      return;
    }
    try {
      await AuthService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📧 Te enviamos un correo de recuperación')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Validación para el botón "Olvidé mi contraseña"
    final emailValido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(emailCtrl.text.trim());

    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Iniciar sesión', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        hintText: 'usuario@ejemplo.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}), // Refresca para actualizar emailValido
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                        return ok ? null : 'Correo inválido';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Tu clave',
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : _login,
                        child: Text(loading ? 'Ingresando...' : 'Ingresar'),
                      ),
                    ),
                    TextButton(
                      onPressed: emailValido ? _resetPass : null,
                      child: const Text('Olvidé mi contraseña'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed('/auth/registro'),
                      child: const Text('Crear cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
