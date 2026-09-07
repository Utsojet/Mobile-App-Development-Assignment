import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

/// Service managing user profiles in Firestore, authentication updates,
/// and profile picture uploads in Firebase Storage.
class UserService {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;
  final FirebaseStorage? _customStorage;

  UserService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  })  : _customFirestore = firestore,
        _customAuth = auth,
        _customStorage = storage;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseStorage get _storage => _customStorage ?? FirebaseStorage.instance;

  static const String usersCollection = 'users';

  /// Stream of user document by UID.
  Stream<UserModel?> getUserStream(String uid) {
    return _firestore.collection(usersCollection).doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Fetches a single user document by UID.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore.collection(usersCollection).doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Ensures a user profile document exists in Firestore upon registration or login.
  Future<UserModel> createOrSyncUserDoc(User user, {String? displayName}) async {
    final docRef = _firestore.collection(usersCollection).doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }

    final resolvedName = displayName?.trim().isNotEmpty == true
        ? displayName!.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (user.email != null && user.email!.contains('@')
                ? user.email!.split('@').first
                : 'Chef'));

    final newUser = UserModel(
      uid: user.uid,
      name: resolvedName,
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
      bio: '',
      themeMode: 'system',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(newUser.toFirestore());
    return newUser;
  }

  /// Updates user profile name and bio in Firestore and Firebase Auth.
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String bio,
  }) async {
    final trimmedName = name.trim();
    final trimmedBio = bio.trim();

    await _firestore.collection(usersCollection).doc(uid).set({
      'name': trimmedName,
      'bio': trimmedBio,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.updateDisplayName(trimmedName);
    }
  }

  /// Uploads a new profile photo to Firebase Storage and updates user document.
  Future<String> uploadProfilePhoto({
    required String uid,
    required XFile file,
  }) async {
    final bytes = await file.readAsBytes();
    final storageRef = _storage.ref().child('users/$uid/profile.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedBy': uid},
    );

    await storageRef.putData(bytes, metadata);
    final downloadUrl = await storageRef.getDownloadURL();

    await _firestore.collection(usersCollection).doc(uid).set({
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.updatePhotoURL(downloadUrl);
    }

    return downloadUrl;
  }

  /// Removes current profile photo from Storage and clears photo URL.
  Future<void> removeProfilePhoto(String uid) async {
    try {
      final storageRef = _storage.ref().child('users/$uid/profile.jpg');
      await storageRef.delete();
    } catch (_) {
      // Ignore if file does not exist in storage
    }

    await _firestore.collection(usersCollection).doc(uid).set({
      'photoUrl': '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      await currentUser.updatePhotoURL(null);
    }
  }

  /// Changes the user's password after re-authenticating with the current password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user found.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
