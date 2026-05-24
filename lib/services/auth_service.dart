import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Login con email y contraseña
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Registro con email y contraseña (crea la cuenta en Firebase Auth)
  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Envía email de verificación al usuario logueado
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (user.emailVerified) return; // si ya está verificado, no hace falta
    await user.sendEmailVerification();
  }

  /// Recarga el usuario (útil para comprobar emailVerified después)
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    await user?.reload();
  }

  /// Devuelve si el usuario actual está verificado
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Enviar correo para restablecer contraseña
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Cerrar sesión
  Future<void> logout() {
    return _auth.signOut();
  }

  /// Usuario actual (puede ser null)
  User? get currentUser => _auth.currentUser;
}
