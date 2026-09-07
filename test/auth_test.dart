import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:recipe/models/user_model.dart';
import 'package:recipe/providers/auth_provider.dart';
import 'package:recipe/services/auth_service.dart';
import 'package:recipe/services/user_service.dart';
import 'package:recipe/views/auth/auth_gate.dart';
import 'package:recipe/views/auth/login_screen.dart';

// ── Mock implementations for testing ─────────────────────────────────────────

class FakeUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final bool isAnonymous;

  FakeUser({
    this.uid = 'test-uid-123',
    this.email = 'chef@example.com',
    this.displayName = 'Chef Gordon',
    this.isAnonymous = false,
  });
}

class FakeAuthService extends Fake implements AuthService {
  final StreamController<User?> _controller = StreamController<User?>.broadcast();
  User? _current;

  FakeAuthService([this._current]);

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _current;

  @override
  bool get isAuthenticated => _current != null;

  @override
  bool get isAnonymous => _current?.isAnonymous ?? false;

  void emitUser(User? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (password == 'wrong') {
      throw const AuthException('Incorrect email or password.');
    }
    final user = FakeUser(email: email, displayName: 'Test Chef');
    emitUser(user);
    return FakeUserCredential(user);
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    final user = FakeUser(isAnonymous: true, email: null, displayName: null);
    emitUser(user);
    return FakeUserCredential(user);
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }
}

class FakeUserService extends Fake implements UserService {
  final StreamController<UserModel?> _controller = StreamController<UserModel?>.broadcast();

  @override
  Stream<UserModel?> getUserStream(String uid) => _controller.stream;

  @override
  Future<UserModel> createOrSyncUserDoc(User user, {String? displayName}) async {
    final model = UserModel(
      uid: user.uid,
      name: displayName ?? user.displayName ?? 'Chef',
      email: user.email ?? '',
    );
    _controller.add(model);
    return model;
  }
}

class FakeUserCredential extends Fake implements UserCredential {
  final User _user;
  FakeUserCredential(this._user);

  @override
  User get user => _user;
}

void main() {
  group('Auth System Tests', () {
    test('AuthException returns correct string message', () {
      const ex = AuthException('Invalid email or password');
      expect(ex.toString(), 'Invalid email or password');
    });

    test('AuthProvider exposes correct default values when unauthenticated', () {
      final fakeAuth = FakeAuthService(null);
      final fakeUser = FakeUserService();
      final provider = AuthProvider(authService: fakeAuth, userService: fakeUser);

      expect(provider.isAuthenticated, false);
      expect(provider.isAnonymous, false);
      expect(provider.displayName, 'Guest');
      expect(provider.email, 'Guest User');
    });

    test('AuthProvider reflects authenticated user metadata correctly', () {
      final user = FakeUser(email: 'pasta@italian.com', displayName: 'Mario');
      final fakeAuth = FakeAuthService(user);
      final fakeUser = FakeUserService();
      final provider = AuthProvider(authService: fakeAuth, userService: fakeUser);

      expect(provider.isAuthenticated, true);
      expect(provider.isAnonymous, false);
      expect(provider.displayName, 'Mario');
      expect(provider.email, 'pasta@italian.com');
    });

    test('AuthProvider handles guest anonymous user properly', () {
      final guest = FakeUser(isAnonymous: true, email: null, displayName: null);
      final fakeAuth = FakeAuthService(guest);
      final fakeUser = FakeUserService();
      final provider = AuthProvider(authService: fakeAuth, userService: fakeUser);

      expect(provider.isAuthenticated, true);
      expect(provider.isAnonymous, true);
      expect(provider.displayName, 'Guest Cook');
      expect(provider.email, 'Guest User');
    });

    test('AuthProvider sign in with email updates user', () async {
      final fakeAuth = FakeAuthService(null);
      final fakeUser = FakeUserService();
      final provider = AuthProvider(authService: fakeAuth, userService: fakeUser);

      final ok = await provider.signInWithEmail(
        email: 'test@food.com',
        password: 'password123',
      );

      expect(ok, true);
      expect(provider.isAuthenticated, true);
      expect(provider.errorMessage, isNull);
    });

    test('AuthProvider captures error message on failure', () async {
      final fakeAuth = FakeAuthService(null);
      final fakeUser = FakeUserService();
      final provider = AuthProvider(authService: fakeAuth, userService: fakeUser);

      final ok = await provider.signInWithEmail(
        email: 'test@food.com',
        password: 'wrong',
      );

      expect(ok, false);
      expect(provider.isAuthenticated, false);
      expect(provider.errorMessage, contains('Incorrect email or password'));
    });

    testWidgets('AuthGate displays LoginScreen when user is not logged in', (tester) async {
      final fakeAuth = FakeAuthService(null);
      final fakeUser = FakeUserService();
      final provider = AuthProvider(authService: fakeAuth, userService: fakeUser);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: provider,
            child: const AuthGate(),
          ),
        ),
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.text('Continue as Guest'), findsOneWidget);
    });
  });
}
