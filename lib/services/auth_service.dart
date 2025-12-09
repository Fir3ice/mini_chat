import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _auth.currentUser;

  // Реєстрація + Збереження в БД
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    String? status, // Додали статус
    String? avatarBase64, // Додали фото
  }) async {
    try {
      // 1. Створюємо юзера в Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Оновлюємо DisplayName
      await cred.user?.updateDisplayName(name);

      // 3. Створюємо об'єкт користувача для БД
      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        displayName: name,
        status: status,
        avatarBase64: avatarBase64,
      );

      // 4. Зберігаємо в Firestore
      await _firestoreService.saveUser(newUser);

      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Вхід (Без змін)
  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Google Вхід + Перевірка БД
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential cred = await _auth.signInWithCredential(credential);

      // Якщо це новий юзер (немає в базі) - збережемо його
      if (cred.user != null) {
        final existingUser = await _firestoreService.getUserByEmail(cred.user!.email!);
        if (existingUser == null) {
          UserModel newUser = UserModel(
            uid: cred.user!.uid,
            email: cred.user!.email!,
            displayName: cred.user!.displayName ?? 'Google User',
            status: 'Привіт! Я використовую MiniChat',
          );
          await _firestoreService.saveUser(newUser);
        }
      }

      return cred;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Google Sign-In Error: $e';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  String _handleAuthError(FirebaseAuthException e) {
    return e.message ?? 'Помилка авторизації';
  }
}