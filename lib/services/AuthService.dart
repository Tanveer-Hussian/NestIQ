// lib/services/auth_service.dart


import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/models/UserModel.dart';
import 'package:fyp/utils/AppConstants.dart';
import 'package:get/get.dart';


class AuthService extends GetxService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Blocks authStateChanges listener during registration to prevent race condition
  bool isRegistering = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ────────────────────────────────────────────────────────────────────────────
  // FR-1.1 & FR-1.2: Register new user
  // ────────────────────────────────────────────────────────────────────────────
  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String phone,
    String? university,
    String? cnicImageUrl,
  }) async {

    print('── AuthService.registerUser() START ──────────────────');
    print('   email: $email | role: $role');

    isRegistering = true;
    print('   [1] isRegistering = true');

    try {
      // ── Step 1: Create Firebase Auth account ────────────────────────────────
      // IMPORTANT: On mismatched firebase_auth versions, createUserWithEmailAndPassword
      // crashes with PigeonUserDetails decode error even though the account IS
      // created on Firebase servers. The fallback below handles this case.
      print('   [2] createUserWithEmailAndPassword...');

      User? firebaseUser;

      try {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        firebaseUser = credential.user;
        print('   [2] Auth account created via credential. UID: ${firebaseUser?.uid}');

      } catch (pigeonError) {
        // The pigeon decode crash happens AFTER the account is created on the server.
        // Check if _auth.currentUser is now set — if yes, account was created successfully
        // and we just lost the credential object due to the decode bug.
        print('   [2] createUserWithEmailAndPassword threw: $pigeonError');
        print('   [2] Checking if account was created despite error...');

        if (_auth.currentUser != null) {
          // Account was created — the pigeon bug just corrupted the response object
          firebaseUser = _auth.currentUser;
          print('   [2] RECOVERED: account exists. UID: ${firebaseUser!.uid}');
        } else {
          // Try signing in — sometimes currentUser is null but account exists
          print('   [2] currentUser null, trying signIn to recover...');
          try {
            final signInCred = await _auth.signInWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
            firebaseUser = signInCred.user;
            print('   [2] RECOVERED via signIn. UID: ${firebaseUser?.uid}');
          } catch (signInError) {
            // Account was not created at all — rethrow original error
            print('   [2] signIn also failed: $signInError');
            rethrow;
          }
        }
      }

      // At this point firebaseUser must be non-null
      if (firebaseUser == null) {
        throw Exception('Failed to get Firebase user after registration');
      }

      final uid = firebaseUser.uid;

      // ── Step 2: Build UserModel ──────────────────────────────────────────────
      print('   [3] Building UserModel for UID: $uid');
      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        role: role,
        phone: phone.trim(),
        university: university,
        cnicImageUrl: cnicImageUrl,
        isActive: true,
        createdAt: DateTime.now(),
      );

      // ── Step 3: Write Firestore document ────────────────────────────────────
      // toMap() uses FieldValue.serverTimestamp() — NOT raw DateTime
      print('   [4] Writing Firestore /users/$uid ...');
      await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .set(user.toMap());
      print('   [4] Firestore write SUCCESS ✓');

      // ── Step 4: Release flag ─────────────────────────────────────────────────
      isRegistering = false;
      print('   [5] isRegistering = false');
      print('── AuthService.registerUser() DONE ✓ ─────────────────');

      return user;

    } catch (e, stack) {
      isRegistering = false;
      print('   [ERROR] registerUser failed: $e');
      print('   [STACK] $stack');

      // Sign out any partial auth state
      try {
        if (_auth.currentUser != null) {
          print('   [CLEANUP] Signing out...');
          await _auth.signOut();
        }
      } catch (_) {}

      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-1.3: Login
  // ────────────────────────────────────────────────────────────────────────────
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    print('── AuthService.loginUser() $email');
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = credential.user!.uid;
    print('   Login success. UID: $uid');
    return await getUserById(uid);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-1.4: Password reset
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Fetch Firestore user document by UID
  // ────────────────────────────────────────────────────────────────────────────
  Future<UserModel?> getUserById(String uid) async {
    try {
      print('   AuthService.getUserById($uid)');
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        print('   getUserById: document NOT found');
        return null;
      }
      print('   getUserById: document found ✓');
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      print('   AuthService.getUserById ERROR: $e');
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-2.1: Update user profile
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> updateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update(updates);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // FR-8.2: Admin suspends / reactivates account
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> setUserActiveStatus(String uid, bool isActive) async {
    await _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update({'isActive': isActive});
  }

  // ── Stream all users (admin only) — sort client-side ───────────────────────
  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection(AppConstants.colUsers)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) { final aTime = a.createdAt; final bTime = b.createdAt; return bTime.compareTo(aTime); });
          return list;
        });
  }
}
