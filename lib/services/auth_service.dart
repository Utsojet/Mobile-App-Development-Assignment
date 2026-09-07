import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class handling all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated user, or null if not logged in.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently logged in.
  bool get isAuthenticated => _auth.currentUser != null;

  /// Whether the currently logged in user is in Guest/Anonymous mode.
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  /// Register a new account with email and password.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  /// Sign in anonymously as a guest.
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Could not continue as guest. Please try again.');
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Could not send reset email. Please try again.');
    }
  }

  /// Sign in with Google (Cross-platform: Web popup / Android native prompt).
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // User canceled
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_handleAuthErrorCode(e.code, e.message));
    } catch (e) {
      throw AuthException('Google Sign-In failed: ${e.toString()}');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
      await _auth.signOut();
    } catch (e) {
      throw AuthException('Error signing out. Please try again.');
    }
  }

  /// Translates Firebase error codes to user-friendly messages.
  String _handleAuthErrorCode(String code, String? originalMessage) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please enable it in Firebase Console.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        return originalMessage ?? 'Authentication failed ($code). Please try again.';
    }
  }
}

/// Custom exception for authentication errors with friendly messages.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
