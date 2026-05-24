import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import 'package:firebase_auth/firebase_auth.dart'; // Para manejar errores de Auth

import '../../../services/auth_service.dart'; // Servicio de autenticación
import '../../../services/user_service.dart'; // Servicio para guardar perfil
import '../../../data/spain_locations.dart'; // Datos provincia -> población -> CP

class RegisterCitizenForm extends StatefulWidget {
  const RegisterCitizenForm({super.key});

  @override
  State<RegisterCitizenForm> createState() => _RegisterCitizenFormState();
}

class _RegisterCitizenFormState extends State<RegisterCitizenForm> {
  // 1- Clave para validar todo el formulario
  final _formKey = GlobalKey<FormState>();

  // 2- Controllers para leer campos escritos por el usuario
  final nameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final dniCtrl = TextEditingController();

  // 3- Variables para los desplegables dependientes
  String? selectedProvince;
  String? selectedPopulation;
  String? selectedPostalCode;

  // 4- Lista de provincias obtenida desde spain_locations.dart
  final List<String> provinces = spainLocations.keys.toList();

  // 5- Para mostrar/ocultar la contraseña
  bool obscurePass = true;

  // 6- Servicios que encapsulan Firebase
  final _auth = AuthService();
  final _users = UserService();

  // 7- Para desactivar el botón mientras se crea la cuenta
  bool loading = false;

  @override
  void dispose() {
    // 8- Liberamos memoria de los controllers
    nameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    addressCtrl.dispose();
    dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 9- Validamos todos los campos del formulario
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // 10- Creamos usuario en Firebase Auth
      final cred = await _auth.register(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      // 11- Obtenemos UID único del usuario
      final uid = cred.user!.uid;

      // 12- Guardamos perfil del ciudadano en Firestore
      await _users.createUserProfile(
        uid: uid,
        role: 'citizen',
        email: cred.user!.email!,

        // 13- Datos escritos manualmente
        name: nameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        dniNif: dniCtrl.text.trim().toUpperCase(),

        // 14- Datos normalizados desde desplegables
        city: selectedProvince!,
        population: selectedPopulation!,
        postalCode: selectedPostalCode!,
      );

      // 15- Enviamos correo de verificación
      await _auth.sendEmailVerification();

      if (!mounted) return;
      void _showRegisterMessageDialog({
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
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
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
      _showRegisterMessageDialog(
  title: 'Cuenta creada',
  message: 'Tu cuenta se ha creado correctamente. Revisa tu correo para verificarla.',
  icon: Icons.check_circle,
  color: Colors.green,
);

      // 16- Como Firebase deja al usuario logueado, entramos al panel ciudadano
      Navigator.pushReplacementNamed(context, '/citizen-home');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      final msg = switch (e.code) {
        'email-already-in-use' => 'Ese correo ya está registrado',
        'invalid-email' => 'Correo inválido',
        'weak-password' => 'Contraseña demasiado débil',
        _ => 'Error registro: ${e.code}',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 17- Calculamos poblaciones según provincia seleccionada
    final populations = selectedProvince == null
        ? <String>[]
        : spainLocations[selectedProvince]!.keys.toList();

    // 18- Calculamos códigos postales según población seleccionada
    final postalCodes =
        selectedProvince == null || selectedPopulation == null
            ? <String>[]
            : spainLocations[selectedProvince]![selectedPopulation]!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),

          // ---------- NOMBRE ----------
          const Center(
            child: Text(
              'Nombre',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameCtrl,
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Introduce tu nombre' : null,
            decoration: _decoration(
              hint: 'Ej: María',
              icon: Icons.person_outline,
            ),
          ),

          const SizedBox(height: 14),

          // ---------- APELLIDOS ----------
          const Center(
            child: Text(
              'Apellidos',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: lastNameCtrl,
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Introduce tus apellidos' : null,
            decoration: _decoration(
              hint: 'Ej: González',
              icon: Icons.badge_outlined,
            ),
          ),

          const SizedBox(height: 14),

          // ---------- EMAIL ----------
          const Center(
            child: Text(
              'Correo electrónico',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
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

          // ---------- CONTRASEÑA ----------
          const Center(
            child: Text(
              'Contraseña',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passCtrl,
            obscureText: obscurePass,
            validator: (value) {
              final pass = value ?? '';
              if (pass.isEmpty) return 'Introduce tu contraseña';
              if (pass.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
            decoration: _decoration(
              hint: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  obscurePass ? Icons.visibility_off : Icons.visibility,
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

          // ---------- DIRECCIÓN ----------
          const Center(
            child: Text(
              'Dirección',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: addressCtrl,
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Introduce tu dirección' : null,
            decoration: _decoration(
              hint: 'Calle y número',
              icon: Icons.location_on_outlined,
            ),
          ),

          const SizedBox(height: 20),

          // ---------- PROVINCIA ----------
          const Center(
            child: Text(
              'Provincia',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedProvince,
            decoration: _decoration(
              hint: 'Selecciona provincia',
              icon: Icons.map_outlined,
            ),
            items: provinces.map((province) {
              return DropdownMenuItem(
                value: province,
                child: Text(province),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Selecciona una provincia' : null,
            onChanged: (value) {
              setState(() {
                selectedProvince = value;

                // Al cambiar provincia, limpiamos población y CP
                selectedPopulation = null;
                selectedPostalCode = null;
              });
            },
          ),

          const SizedBox(height: 20),

          // ---------- POBLACIÓN ----------
          const Center(
            child: Text(
              'Población',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedPopulation,
            decoration: _decoration(
              hint: selectedProvince == null
                  ? 'Selecciona primero provincia'
                  : 'Selecciona población',
              icon: Icons.location_city_outlined,
            ),
            items: populations.map((population) {
              return DropdownMenuItem(
                value: population,
                child: Text(population),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Selecciona una población' : null,
            onChanged: selectedProvince == null
                ? null
                : (value) {
                    setState(() {
                      selectedPopulation = value;

                      // Al cambiar población, limpiamos CP
                      selectedPostalCode = null;
                    });
                  },
          ),

          const SizedBox(height: 20),

          // ---------- CÓDIGO POSTAL ----------
          const Center(
            child: Text(
              'Código Postal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedPostalCode,
            decoration: _decoration(
              hint: selectedPopulation == null
                  ? 'Selecciona primero población'
                  : 'Selecciona código postal',
              icon: Icons.local_post_office_outlined,
            ),
            items: postalCodes.map((cp) {
              return DropdownMenuItem(
                value: cp,
                child: Text(cp),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Selecciona un código postal' : null,
            onChanged: selectedPopulation == null
                ? null
                : (value) {
                    setState(() {
                      selectedPostalCode = value;
                    });
                  },
          ),

          const SizedBox(height: 14),

          // ---------- DNI / NIF ----------
          const Center(
            child: Text(
              'DNI / NIF',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: dniCtrl,
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final doc = (v ?? '').trim().toUpperCase();
              if (doc.isEmpty) return 'Introduce tu DNI/NIF';
              if (doc.length < 8) return 'Documento inválido';
              return null;
            },
            decoration: _decoration(
              hint: 'Ej: 12345678A',
              icon: Icons.credit_card_outlined,
            ),
          ),

          const SizedBox(height: 20),

          // ---------- BOTÓN CREAR CUENTA ----------
          SizedBox(
  height: 54,
  child: ElevatedButton(
    onPressed: loading ? null : _submit,

    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2F80ED),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),

    child: Text(
      loading ? 'Creando...' : 'Crear cuenta',
    ),
  ),
),
        ],
      ),
    );
  }

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
}