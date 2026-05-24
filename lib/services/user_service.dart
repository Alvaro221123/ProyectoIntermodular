import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  /// Crea/guarda el perfil del usuario en: users/{uid}
  Future<void> createUserProfile({
    required String uid,
    required String role, // "citizen" o "association"
    required String email,

    required String name,
    required String lastName,
    required String address,
    required String city,
    required String postalCode,
    required String population,

    // ciudadano: dni/nif
    String? dniNif,

    // asociación: CIF/DNI/NIF (en producción lo refinamos)
    String? docValue,
    String? docType, // "CIF" | "DNI" | "NIF"
  }) {
    return _db.collection('users').doc(uid).set({
  'role': role,
  'email': email,

  'name': name,
  'lastName': lastName,
  'address': address,
  'city': city,
  'population': population,
  'postalCode': postalCode,

  'dniNif': dniNif,
  'docType': docType,
  'docValue': docValue,

  'createdAt': FieldValue.serverTimestamp(),
});
  }
  Future<void> updateUserProfile({
  required String uid,
  required String name,
  required String lastName,
  required String address,
  required String city,
  required String population,
  required String postalCode,
  required String dniNif,
}) async {
  await _db.collection('users').doc(uid).update({
    'name': name,
    'lastName': lastName,
    'address': address,
    'city': city,
    'population': population,
    'postalCode': postalCode,
    'dniNif': dniNif,
  });
}

  /// Leer perfil (lo usaremos en login para redirigir por role)
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
