// =======================================================
// IMPORTACIONES
// =======================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/auth_service.dart';
import 'package:vecinoapp/services/user_service.dart';

// =======================================================
// WIDGET PRINCIPAL LOGINFORM
// =======================================================

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

// =======================================================
// STATE PRINCIPAL DEL LOGIN
// =======================================================

class _LoginFormState extends State<LoginForm> {

  // =======================================================
  // VARIABLES Y CONTROLADORES
  // =======================================================

  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Controllers de los inputs
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  // Servicios de autenticación y Firestore
  final _authService = AuthService();
  final _userService = UserService();

  // Control de visibilidad de contraseña
  bool obscurePass = true;

  // =======================================================
  // CICLO DE VIDA
  // =======================================================

  @override
  void dispose() {

    // Liberamos memoria de controllers
    emailCtrl.dispose();
    passCtrl.dispose();

    super.dispose();
  }

  // =======================================================
  // HELPERS VISUALES
  // =======================================================

  // -------------------------------------------------------
  // Decoración reutilizable de inputs
  // -------------------------------------------------------
  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {

    return InputDecoration(

      hintText: hint,

      prefixIcon: Icon(icon),

      suffixIcon: suffix,

      filled: true,

      fillColor: Colors.white,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // -------------------------------------------------------
  // Dialog moderno reutilizable
  // -------------------------------------------------------
  void _showMessageDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: Row(
            children: [

              Icon(
                icon,
                color: color,
                size: 28,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          content: Text(
            message,

            style: const TextStyle(
              fontSize: 15,
            ),
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // =======================================================
  // LÓGICA PRINCIPAL LOGIN
  // =======================================================

  Future<void> _login() async {

    // ---------------------------------------------------
    // VALIDACIÓN FORMULARIO
    // ---------------------------------------------------
    if (!_formKey.currentState!.validate()) {

      _showMessageDialog(
        title: 'Campos incompletos',

        message:
            'Revisa el correo y la contraseña antes de continuar.',

        icon: Icons.warning_amber,

        color: Colors.orange,
      );

      return;
    }

    try {

      // ---------------------------------------------------
      // LOGIN FIREBASE
      // ---------------------------------------------------
      final cred = await _authService.login(

        email: emailCtrl.text.trim(),

        password: passCtrl.text,
      );

      // ---------------------------------------------------
      // OBTENER DATOS FIRESTORE
      // ---------------------------------------------------
      final uid = cred.user!.uid;

      final profile =
          await _userService.getUserProfile(uid);

      final role = profile?['role'];

      if (!mounted) return;

      // ---------------------------------------------------
      // REDIRECCIÓN CIUDADANO
      // ---------------------------------------------------
      if (role == 'citizen') {

        _showMessageDialog(
          title: 'Login correcto',

          message:
              'Has iniciado sesión correctamente.',

          icon: Icons.check_circle,

          color: Colors.green,
        );

        await Future.delayed(
          const Duration(seconds: 1),
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/citizen-home',
        );

        return;
      }

      // ---------------------------------------------------
      // REDIRECCIÓN ASOCIACIÓN
      // ---------------------------------------------------
      if (role == 'association') {

        _showMessageDialog(
          title: 'Login correcto',

          message:
              'Has iniciado sesión correctamente.',

          icon: Icons.check_circle,

          color: Colors.green,
        );

        await Future.delayed(
          const Duration(seconds: 1),
        );

        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/association-home',
        );

        return;
      }

      // ---------------------------------------------------
      // ERROR ROL NO ENCONTRADO
      // ---------------------------------------------------
      _showMessageDialog(
        title: 'Rol no encontrado',

        message:
            'No se ha podido identificar el tipo de cuenta.',

        icon: Icons.error_outline,

        color: Colors.red,
      );

    } on FirebaseAuthException catch (e) {

      // ---------------------------------------------------
      // ERRORES FIREBASE
      // ---------------------------------------------------
      if (!mounted) return;

      final msg = switch (e.code) {

        'invalid-email' =>
          'El correo introducido no es válido.',

        'user-not-found' =>
          'No existe ninguna cuenta registrada con ese correo.',

        'wrong-password' =>
          'La contraseña introducida es incorrecta.',

        'invalid-credential' =>
          'Correo o contraseña incorrectos.',

        'user-disabled' =>
          'Esta cuenta ha sido deshabilitada.',

        'too-many-requests' =>
          'Has realizado demasiados intentos. Espera unos minutos.',

        _ =>
          'No se ha podido iniciar sesión.',
      };

      _showMessageDialog(
        title: 'Error de acceso',

        message: msg,

        icon: Icons.error_outline,

        color: Colors.red,
      );

    } catch (e) {

      // ---------------------------------------------------
      // ERRORES GENERALES
      // ---------------------------------------------------
      if (!mounted) return;

      _showMessageDialog(
        title: 'Error inesperado',

        message:
            'Ha ocurrido un problema al iniciar sesión.',

        icon: Icons.error_outline,

        color: Colors.red,
      );
    }
  }

  // =======================================================
  // BUILD PRINCIPAL
  // =======================================================

  @override
  Widget build(BuildContext context) {

    return Form(
      key: _formKey,

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [

          // =================================================
          // INPUT EMAIL
          // =================================================

          const Center(
            child: Text(
              'Correo electrónico',

              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(

            controller: emailCtrl,

            keyboardType:
                TextInputType.emailAddress,

            validator: (value) {

  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Introduce tu correo electrónico';
  }

  final emailRegex = RegExp(
    r'^[^@]+@[^@]+\.[^@]+$',
  );

  if (!emailRegex.hasMatch(email)) {
    return 'Introduce un correo válido';
  }

  return null;
},

            decoration: _decoration(
              hint: 'tu@email.com',

              icon: Icons.mail_outline,
            ),
          ),

          const SizedBox(height: 14),

          // =================================================
          // INPUT PASSWORD
          // =================================================

          const Center(
            child: Text(
              'Contraseña',

              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(

            controller: passCtrl,

            obscureText: obscurePass,

            validator: (value) {

              final pass = value ?? '';

              if (pass.isEmpty) {
                return 'Introduce tu contraseña';
              }

              if (pass.length < 4) {
                return 'Mínimo 4 caracteres';
              }

              return null;
            },

            decoration: _decoration(

              hint: '••••••••',

              icon: Icons.lock_outline,

              suffix: IconButton(

                icon: Icon(
                  obscurePass
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),

                onPressed: () {

                  setState(() {
                    obscurePass = !obscurePass;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // =================================================
          // BOTÓN LOGIN
          // =================================================

          SizedBox(
            height: 52,
            width: double.infinity,

            child: ElevatedButton(

              onPressed: _login,

              style: ElevatedButton.styleFrom(

                backgroundColor:
                    const Color(0xFF2F80ED),

                foregroundColor: Colors.white,

                elevation: 0,

                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),

              child: const Text(
                'Entrar',

                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}