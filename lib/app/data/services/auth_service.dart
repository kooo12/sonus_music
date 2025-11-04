import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'achievement_service.dart';
import 'listening_stats_service.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn(
      // scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
      // clientId:
      //     '756997181231-jjdl7c6oet3tcftf5qaef8fbqjaejs76.apps.googleusercontent.com',
      // serverClientId:
      //     '756997181231-p35l8spjeseu27m1tijvv0mgmpbdfa79.apps.googleusercontent.com',
      );
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  final Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    await _secure.read(key: 'auth_uid');
    // Firebase already restores the session internally; reading token is optional.
  }

  Future<User?> signIn(
      {required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;
    if (user != null) {
      final idToken = await user.getIdToken();
      await _secure.write(key: 'auth_id_token', value: idToken);
      await _secure.write(key: 'auth_uid', value: user.uid);
    }
    return user;
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'provider': 'password',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return user;
  }

  Future<User?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final idToken = await user.getIdToken();
      await _secure.write(key: 'auth_id_token', value: idToken);
      await _secure.write(key: 'auth_uid', value: user.uid);
    }
    return user;
  }

  // Phone auth (two-step: request code, then verify)
  Future<void> requestPhoneCode({
    required String phoneNumber,
    required void Function(PhoneAuthCredential cred) onAutoVerified,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onAutoVerified,
      verificationFailed: (e) =>
          onError(e.message ?? 'Phone verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<User?> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
        verificationId: verificationId, smsCode: smsCode);
    final cred = await _auth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'provider': 'phone',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final idToken = await user.getIdToken();
      await _secure.write(key: 'auth_id_token', value: idToken);
      await _secure.write(key: 'auth_uid', value: user.uid);
    }
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _google.signOut();
    } catch (_) {}
    await _secure.delete(key: 'auth_id_token');
    await _secure.delete(key: 'auth_uid');
  }

  /// Delete user account and all related data
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final userId = user.uid;
      debugPrint('Starting account deletion for user: $userId');

      // Delete all user-related data from Firestore
      await _deleteUserDataFromFirestore(userId);

      // Delete local data
      await _deleteLocalUserData();

      // Delete Firebase Auth account
      await user.delete();
      // await signOut();

      // Clear secure storage
      // await _secure.delete(key: 'auth_id_token');
      // await _secure.delete(key: 'auth_uid');

      // // Sign out from Google if applicable
      // try {
      //   await _google.signOut();
      // } catch (_) {}

      debugPrint('Account deletion completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  /// Delete all user-related data from Firestore
  Future<void> _deleteUserDataFromFirestore(String userId) async {
    try {
      debugPrint('Deleting user data from Firestore for user: $userId');

      // Delete user document
      await _db.collection('users').doc(userId).delete();

      // Delete user achievements
      try {
        final userAchievementsSnapshot = await _db
            .collection('user_achievements')
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in userAchievementsSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint(
            'No user achievements to delete or collection does not exist: $e');
      }

      // Delete achievement progress
      try {
        final achievementProgressSnapshot = await _db
            .collection('achievement_progress')
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in achievementProgressSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint(
            'No achievement progress to delete or collection does not exist: $e');
      }

      // Delete listening stats
      // try {
      //   final listeningStatsSnapshot = await _db
      //       .collection('listening_stats')
      //       .where('userId', isEqualTo: userId)
      //       .get();

      //   for (final doc in listeningStatsSnapshot.docs) {
      //     await doc.reference.delete();
      //   }
      // } catch (e) {
      //   debugPrint(
      //       'No listening stats to delete or collection does not exist: $e');
      // }

      // Delete play history
      // try {
      //   final playHistorySnapshot = await _db
      //       .collection('play_history')
      //       .where('userId', isEqualTo: userId)
      //       .get();

      //   for (final doc in playHistorySnapshot.docs) {
      //     await doc.reference.delete();
      //   }
      // } catch (e) {
      //   debugPrint(
      //       'No play history to delete or collection does not exist: $e');
      // }

      // Delete playlists
      // try {
      //   final playlistsSnapshot = await _db
      //       .collection('playlists')
      //       .where('userId', isEqualTo: userId)
      //       .get();

      //   for (final doc in playlistsSnapshot.docs) {
      //     await doc.reference.delete();
      //   }
      // } catch (e) {
      //   debugPrint('No playlists to delete or collection does not exist: $e');
      // }

      // // Delete songs
      // try {
      //   final songsSnapshot = await _db
      //       .collection('songs')
      //       .where('userId', isEqualTo: userId)
      //       .get();

      //   for (final doc in songsSnapshot.docs) {
      //     await doc.reference.delete();
      //   }
      // } catch (e) {
      //   debugPrint('No songs to delete or collection does not exist: $e');
      // }

      // Delete FCM tokens
      try {
        final fcmTokensSnapshot = await _db
            .collection('fcm_tokens')
            .where('userId', isEqualTo: userId)
            .get();

        for (final doc in fcmTokensSnapshot.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint('No FCM tokens to delete or collection does not exist: $e');
      }

      // Delete in-app messages (nested under users collection)
      // try {
      //   final inAppMessagesSnapshot = await _db
      //       .collection('users')
      //       .doc(userId)
      //       .collection('in_app_messages')
      //       .get();

      //   for (final doc in inAppMessagesSnapshot.docs) {
      //     await doc.reference.delete();
      //   }
      // } catch (e) {
      //   debugPrint(
      //       'No in-app messages to delete or collection does not exist: $e');
      // }

      debugPrint('Successfully deleted all user data from Firestore');
    } catch (e) {
      debugPrint('Error deleting user data from Firestore: $e');
      rethrow;
    }
  }

  /// Delete local user data
  Future<void> _deleteLocalUserData() async {
    try {
      debugPrint('Deleting local user data');

      // Clear achievement data
      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();
        final user = _auth.currentUser;
        if (user != null) {
          // Clear user-specific achievement data
          await achievementService.clearUserData(user.uid);
        }
      }

      // Clear listening stats data
      if (Get.isRegistered<ListeningStatsService>()) {
        final listeningStatsService = Get.find<ListeningStatsService>();
        await listeningStatsService.clearAllStats();
      }

      debugPrint('Successfully deleted local user data');
    } catch (e) {
      debugPrint('Error deleting local user data: $e');
      rethrow;
    }
  }
}
