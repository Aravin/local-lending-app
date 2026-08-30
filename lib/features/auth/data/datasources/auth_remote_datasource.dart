import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> signInWithGoogle({required UserRole role});
  Future<void> signOut();
  Future<AuthUser?> getCurrentUser();
  Stream<AuthUser?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<AuthUser> signInWithGoogle({required UserRole role}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled by user.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('Failed to retrieve user from Firebase Auth.');
    }

    return AuthUser(
      id: user.uid,
      name: user.displayName ?? (role.isAdmin ? 'Lender Admin' : 'Borrower'),
      email: user.email ?? '',
      role: role,
      phoneNumber: user.phoneNumber,
      avatarUrl: user.photoURL,
    );
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final currentFbUser = _firebaseAuth.currentUser;
    if (currentFbUser == null) return null;

    return AuthUser(
      id: currentFbUser.uid,
      name: currentFbUser.displayName ?? 'User',
      email: currentFbUser.email ?? '',
      role: UserRole.client, // Default role
      phoneNumber: currentFbUser.phoneNumber,
      avatarUrl: currentFbUser.photoURL,
    );
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return AuthUser(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email ?? '',
        role: UserRole.client,
        phoneNumber: user.phoneNumber,
        avatarUrl: user.photoURL,
      );
    });
  }
}
