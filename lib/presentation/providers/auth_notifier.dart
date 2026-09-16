import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/models/user_dto.dart';

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final FirebaseAuthDatasource _authDatasource;

  AuthNotifier(this._authDatasource) : super(const AsyncValue.data(null)) {
    _authDatasource.authStateChanges.listen((user) {
      if (user != null) {
        state = AsyncValue.data(_userFromFirebase(user));
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authDatasource.signIn(email, password);
    } on FirebaseAuthException catch (_) {
      state = const AsyncValue.data(null);
      rethrow;
    } catch (_) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authDatasource.signOut();
    state = const AsyncValue.data(null);
  }

  UserEntity? get currentUser => _authDatasource.currentUserToEntity();

  UserEntity _userFromFirebase(User user) {
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? '',
      active: true,
    );
  }
}