import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:vecinoapp/services/auth_service.dart';
import 'package:vecinoapp/services/user_service.dart';
import 'package:vecinoapp/data/spain_locations.dart';

class RegistroAsociacion extends StatefulWidget {
  const RegistroAsociacion({super.key});

  @override
  State<RegistroAsociacion> createState() => _RegistroAsociacionState();
}

class _RegistroAsociacionState extends State<RegistroAsociacion> {
  // 1- Clave para validar todos los campos del formulario
  final _formKey = GlobalKey<FormState>();

  // 2- Controllers para los campos escritos manualmente
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final dniCtrl = TextEditingController();

  // 3- Variables para los desplegables dependientes
  String? selectedProvince;
  String? selectedPopulation;
  String? selectedPostalCode;

  // 4- Lista de provincias obtenida del archivo spain_locations.dart
  final List<String> provinces = spainLocations.keys.toList();

  // 5- Controla si la contraseña se ve o se oculta
  bool obscurePass = true;

  // 6- Servicios de Firebase
  final _auth = AuthService();
  final _users = UserService();

  // 7- Controla el estado de carga al crear cuenta
  bool loading = false;

  @override
  void dispose() {
    // 8- Liberamos memoria de los controllers
    nameCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    addressCtrl.dispose();
    dniCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 9- Validamos todo el formulario antes de crear la cuenta
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      // 10- Creamos el usuario en Firebase Auth
      final cred = await _auth.register(
        email: emailCtrl.text.trim(),
        password: passCtrl.text,
      );

      // 11- Obtenemos el UID generado por Firebase
      final uid = cred.user!.uid;

      // 12- Guardamos el perfil de asociación en Firestore
      await _users.createUserProfile(
        uid: uid,
        role: 'association',
        email: cred.user!.email!,
        name: nameCtrl.text.trim(),
        lastName: '',
        address: addressCtrl.text.trim(),
        city: selectedProvince!,
        population: selectedPopulation!,
        postalCode: selectedPostalCode!,
        dniNif: dniCtrl.text.trim().toUpperCase(),
      );

      // 13- Enviamos verificación por correo
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
  message: 'Tu cuenta de asociación se ha creado correctamente. Revisa tu correo para verificarla.',
  icon: Icons.check_circle,
  color: Colors.green,
);
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
    // 14- Poblaciones disponibles según provincia seleccionada
    final populations = selectedProvince == null
        ? <String>[]
        : spainLocations[selectedProvince!]!.keys.toList();

    // 15- Códigos postales disponibles según población seleccionada
    final postalCodes = selectedProvince == null || selectedPopulation == null
        ? <String>[]
        : spainLocations[selectedProvince!]![selectedPopulation!]!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),

          // ---------- NOMBRE ASOCIACIÓN ----------
          const Center(
            child: Text(
              'Nombre asociación',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameCtrl,
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Introduce el nombre de tu asociación' : null,
            decoration: _decoration(
              hint: 'Ej: Asociación Patitas',
              icon: Icons.apartment_outlined,
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
                // 16- Guardamos provincia y reseteamos dependientes
                selectedProvince = value;
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
                      // 17- Guardamos población y reseteamos CP
                      selectedPopulation = value;
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
                      // 18- Guardamos código postal final
                      selectedPostalCode = value;
                    });
                  },
          ),

          const SizedBox(height: 14),

          // ---------- DNI / NIF / CIF ----------
          const Center(
            child: Text(
              'DNI / NIF / CIF',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: dniCtrl,
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final doc = (v ?? '').trim().toUpperCase();
              if (doc.isEmpty) return 'Introduce tu DNI/NIF/CIF';
              if (doc.length < 8) return 'Documento inválido';
              return null;
            },
            decoration: _decoration(
              hint: 'Ej: B12345678 / 12345678A',
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

  // 19- Helper visual para reutilizar el mismo estilo en todos los campos
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
}