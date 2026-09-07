import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Provider managing authentication state, user profile synchronization,
/// and user profile updates.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userDocSubscription;

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({
    AuthService? authService,
    UserService? userService,
  })  : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService() {
    _user = _authService.currentUser;
    _initAuthListener();
  }

  // ── Getters ──────────────────────────────────────────────────────────────
  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  String get displayName {
    if (_user == null) return 'Guest';
    if (_user!.isAnonymous) return 'Guest Cook';
    if (_userModel != null && _userModel!.name.trim().isNotEmpty) {
      return _userModel!.name.trim();
    }
    if (_user!.displayName != null && _user!.displayName!.trim().isNotEmpty) {
      return _user!.displayName!.trim();
    }
    if (_user!.email != null && _user!.email!.isNotEmpty) {
      return _user!.email!.split('@').first;
    }
    return 'Chef';
  }

  String get email {
    if (_user == null || _user!.isAnonymous) return 'Guest User';
    return _userModel?.email.isNotEmpty == true ? _userModel!.email : (_user!.email ?? 'No email');
  }

  String get photoUrl {
    if (_userModel != null && _userModel!.photoUrl.isNotEmpty) {
      return _userModel!.photoUrl;
    }
    return _user?.photoURL ?? '';
  }

  String get bio => _userModel?.bio ?? '';

  String get themeMode => _userModel?.themeMode ?? 'system';

  // ── Auth Stream Listener ──────────────────────────────────────────────────
  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((user) {
      _user = user;
      _onAuthStateChanged(user);
    });
  }

  void _onAuthStateChanged(User? user) {
    _userDocSubscription?.cancel();
    _userDocSubscription = null;

    if (user == null || user.isAnonymous) {
      _userModel = null;
      notifyListeners();
      return;
    }

    // Sync or create user document in Firestore
    _userService.createOrSyncUserDoc(user).then((model) {
      _userModel = model;
      notifyListeners();
    }).catchError((_) {});

    // Listen to user document updates
    _userDocSubscription = _userService.getUserStream(user.uid).listen((model) {
      _userModel = model;
      notifyListeners();
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithEmail(email: email, password: password);
      if (credential.user != null) {
        try {
          await _userService.createOrSyncUserDoc(credential.user!);
        } catch (_) {}
      }
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);
    try {
      final credential = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      if (credential.user != null) {
        try {
          await _userService.createOrSyncUserDoc(credential.user!, displayName: displayName);
        } catch (_) {}
      }
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final credential = await _authService.signInWithGoogle();
      if (credential == null || credential.user == null) {
        // User aborted Google sign in flow
        _setLoading(false);
        return false;
      }
      try {
        await _userService.createOrSyncUserDoc(credential.user!);
      } catch (_) {}
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    try {
      await _authService.signInAnonymously();
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String bio,
  }) async {
    if (_user == null || _user!.isAnonymous) return false;
    _setLoading(true);
    try {
      await _userService.updateProfile(uid: _user!.uid, name: name, bio: bio);
      _userModel = _userModel?.copyWith(name: name, bio: bio);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> uploadProfilePhoto(XFile file) async {
    if (_user == null || _user!.isAnonymous) return false;
    _setLoading(true);
    try {
      final url = await _userService.uploadProfilePhoto(uid: _user!.uid, file: file);
      _userModel = _userModel?.copyWith(photoUrl: url);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> removeProfilePhoto() async {
    if (_user == null || _user!.isAnonymous) return false;
    _setLoading(true);
    try {
      await _userService.removeProfilePhoto(_user!.uid);
      _userModel = _userModel?.copyWith(photoUrl: '');
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _userService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      _userDocSubscription?.cancel();
      _userDocSubscription = null;
      _userModel = null;
      await _authService.signOut();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
