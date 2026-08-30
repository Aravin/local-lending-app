import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';

abstract class AuthRemoteDataSource {
  Future<AuthUser> signInWithGoogle();
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
  Future<AuthUser> signInWithGoogle() async {
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

    final authUser = await _toAuthUser(user, refreshClaims: true);
    await _ensureBorrowerCustomer(authUser);
    return authUser;
  }

  @override
  Future<void> signOut() async {
    await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
  }

  @override
  Future<AuthUser?> getCurrentUser() async {
    final currentFbUser = _firebaseAuth.currentUser;
    if (currentFbUser == null) return null;

    final authUser = await _toAuthUser(currentFbUser);
    await _ensureBorrowerCustomer(authUser);
    return authUser;
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.idTokenChanges().asyncMap((user) async {
      if (user == null) return null;
      return _toAuthUser(user);
    });
  }

  Future<AuthUser> _toAuthUser(
    fb.User user, {
    bool refreshClaims = false,
  }) async {
    final token = await user.getIdTokenResult(refreshClaims);
    final claims = token.claims ?? const <String, dynamic>{};
    final isAdmin = claims['admin'] == true;
    return AuthUser(
      id: user.uid,
      name: user.displayName ?? (isAdmin ? 'Lender Admin' : 'Borrower'),
      email: user.email ?? '',
      role: isAdmin ? UserRole.admin : UserRole.client,
      phoneNumber: user.phoneNumber,
      avatarUrl: user.photoURL,
    );
  }

  /// Google Sign-In only creates an Auth user. Admin KYC/customers screens
  /// read Firestore, so borrowers need a pending customer profile on first open.
  Future<void> _ensureBorrowerCustomer(AuthUser user) async {
    if (user.role.isAdmin) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('customers')
          .doc(user.id);
      final snapshot = await ref.get();
      if (snapshot.exists) return;
      await ref.set({
        'id': user.id,
        'name': user.name,
        'phone': user.phoneNumber ?? '',
        'email': user.email,
        'activeLoansCount': 0,
        'lifetimeRepaymentRate': 1,
        'riskTier': 'low',
        'kycStatus': 'pending',
        'outstandingRupees': 0,
        'address': '',
      });
    } catch (_) {
      // Sign-in must still succeed if the profile bootstrap fails.
    }
  }
}
