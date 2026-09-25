import 'package:firebase_auth/firebase_auth.dart';
import '../../core/utils/constants.dart';
import '../models/user_dto.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _auth;

  FirebaseAuthDatasource({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  UserEntity? currentUserToEntity() {
    final user = _auth.currentUser;
    if (user == null) return null;
    final email = user.email ?? '';
    final isTest = Constants.isTestAccount(email);
    var displayName = user.displayName ?? '';
    if (displayName.isEmpty && isTest) displayName = 'Test';
    return UserEntity(
      id: user.uid,
      email: email,
      displayName: displayName,
      active: true,
      isTest: isTest,
    );
  }
}