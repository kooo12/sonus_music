import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_service.dart';
import 'listening_stats_service.dart';
import 'network_manager.dart';

const String _firebaseHostingUrl = 'your firebase hosting url';
const String _androidPackageName = 'com.example.music';
const String _iosBundleId = 'com.example.music';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/userinfo.profile'],
    // clientId and serverClientId are automatically read from google-services.json
  );

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  final Rxn<User> firebaseUser = Rxn<User>();
  StreamSubscription<NetworkStatus>? _networkSubscription;
  bool _wasOffline = false;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    _restoreSession();
    _setupNetworkListener();
  }

  @override
  void onClose() {
    _networkSubscription?.cancel();
    super.onClose();
  }

  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  Future<bool> isCurrentUserSuperAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['isSuperAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking super admin status: $e');
      return false;
    }
  }

  Future<bool> isCurrentUserTester() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['isTester'] == true;
    } catch (e) {
      debugPrint('Error checking user tester status: $e');
      return false;
    }
  }

  void _setupNetworkListener() {
    try {
      if (Get.isRegistered<NetworkManager>()) {
        final networkManager = Get.find<NetworkManager>();
        _networkSubscription = networkManager.networkStatus.listen((status) {
          if (status == NetworkStatus.connected && _wasOffline) {
            debugPrint(
                'Internet connection restored, retrying pending user data');
            _retryPendingUserDataForCurrentUser();
            _wasOffline = false;
          } else if (status == NetworkStatus.disconnected) {
            _wasOffline = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error setting up network listener: $e');
    }
  }

  Future<void> _retryPendingUserDataForCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await retryPendingUserData(user.uid);
      }
    } catch (e) {
      debugPrint('Error retrying pending user data for current user: $e');
    }
  }

  Future<void> _restoreSession() async {
    try {
      await _secure.read(key: 'auth_uid');
    } on PlatformException catch (e) {
      if (e.code == 'read_failed' ||
          e.message?.contains('BadPaddingException') == true ||
          e.message?.contains('BAD_DECRYPT') == true) {
        debugPrint(
            '[AuthService] Secure storage decryption failed (likely corrupted data from debug/release mismatch). Clearing secure storage...');

        try {
          await _secure.deleteAll();
          debugPrint('[AuthService] Secure storage cleared successfully');
        } catch (deleteError) {
          debugPrint(
              '[AuthService] Error clearing secure storage: $deleteError');
        }

        debugPrint('[AuthService] PlatformException in _restoreSession: $e');
      }
    } catch (e) {
      debugPrint('[AuthService] Error in _restoreSession: $e');
    }
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
      try {
        await user.updateDisplayName(displayName);
        await user.reload();
        firebaseUser.value = _auth.currentUser;
        debugPrint(
            'Display name updated and user reloaded: ${user.displayName}');
      } catch (e) {
        debugPrint('Error updating display name: $e');
      }

      try {
        final actionCodeSettings = _getActionCodeSettings();
        await user.sendEmailVerification(actionCodeSettings);
        debugPrint('Email verification sent to: ${user.email}');
      } catch (e) {
        debugPrint('Error sending email verification: $e');
      }

      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'provider': 'password',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
        debugPrint(
            'User data saved to Firestore successfully for user: ${user.uid}');
        await _clearPendingUserData(user.uid);
      } catch (e, stackTrace) {
        debugPrint('Error saving user data to Firestore: $e');
        debugPrint('Stack trace: $stackTrace');
        if (e is FirebaseException) {
          debugPrint('Firebase error code: ${e.code}, message: ${e.message}');
        }
        await _savePendingUserData(user.uid, userData);
        debugPrint(
            'User data saved to local storage as pending for user: ${user.uid}');
      }
    }
    return user;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final actionCodeSettings = _getActionCodeSettings();
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );
      debugPrint('Password reset email sent to: $email');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        final actionCodeSettings = _getActionCodeSettings();
        await user.sendEmailVerification(actionCodeSettings);
        debugPrint('Email verification sent to: ${user.email}');
      }
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      rethrow;
    }
  }

  ActionCodeSettings _getActionCodeSettings() {
    return ActionCodeSettings(
      url: _firebaseHostingUrl,
      // Set to true to open the link in the app instead of browser
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      iOSBundleId: _iosBundleId,
      androidInstallApp: true,
    );
  }

  Future<bool> handleEmailActionLink(String link) async {
    try {
      debugPrint('Handling email action link: $link');

      final actionCode = _extractActionCode(link);
      if (actionCode == null) {
        debugPrint('Invalid action code in link');
        return false;
      }

      try {
        await _auth.verifyPasswordResetCode(actionCode);
        debugPrint('Password reset link verified');
        return true;
      } catch (e) {
        try {
          await _auth.applyActionCode(actionCode);
          debugPrint('Email verification link applied');
          await reloadUser();
          return true;
        } catch (e2) {
          debugPrint('Error applying action code: $e2');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error handling email action link: $e');
      return false;
    }
  }

  String? _extractActionCode(String link) {
    try {
      final uri = Uri.parse(link);
      final oobCode = uri.queryParameters['oobCode'];
      if (oobCode != null && oobCode.isNotEmpty) {
        return oobCode;
      }
      if (uri.queryParameters.containsKey('mode')) {
        return uri.toString();
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting action code: $e');
      return null;
    }
  }

  Future<void> confirmPasswordReset(
      String actionCode, String newPassword) async {
    try {
      await _auth.confirmPasswordReset(
        code: actionCode,
        newPassword: newPassword,
      );
      debugPrint('Password reset confirmed successfully');
    } catch (e) {
      debugPrint('Error confirming password reset: $e');
      rethrow;
    }
  }

  Future<void> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        firebaseUser.value = _auth.currentUser;
      }
    } catch (e) {
      debugPrint('Error reloading user: $e');
    }
  }

  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
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
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
        debugPrint('User data saved to Firestore successfully');
        await _clearPendingUserData(user.uid);
      } catch (e) {
        debugPrint('Error saving user data to Firestore: $e');
        await _savePendingUserData(user.uid, userData);
        debugPrint('User data saved to local storage as pending');
      }

      final idToken = await user.getIdToken();
      await _secure.write(key: 'auth_id_token', value: idToken);
      await _secure.write(key: 'auth_uid', value: user.uid);
    }
    return user;
  }

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
      final userData = {
        'uid': user.uid,
        'phone': user.phoneNumber,
        'provider': 'phone',
        'createdAt': FieldValue.serverTimestamp(),
      };

      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .set(userData, SetOptions(merge: true));
        debugPrint('User data saved to Firestore successfully');
        await _clearPendingUserData(user.uid);
      } catch (e) {
        debugPrint('Error saving user data to Firestore: $e');
        await _savePendingUserData(user.uid, userData);
        debugPrint('User data saved to local storage as pending');
      }

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

  Future<void> _savePendingUserData(
      String userId, Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataToSave = Map<String, dynamic>.from(userData);
      if (dataToSave.containsKey('createdAt') &&
          dataToSave['createdAt'] is FieldValue) {
        dataToSave['createdAt'] = 'SERVER_TIMESTAMP';
      }
      await prefs.setString(
          'pending_user_data_$userId', jsonEncode(dataToSave));
      debugPrint('Pending user data saved for: $userId');
    } catch (e) {
      debugPrint('Error saving pending user data: $e');
    }
  }

  Future<void> _clearPendingUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_user_data_$userId');
      debugPrint('Pending user data cleared for: $userId');
    } catch (e) {
      debugPrint('Error clearing pending user data: $e');
    }
  }

  Future<Map<String, dynamic>?> _getPendingUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingDataJson = prefs.getString('pending_user_data_$userId');
      if (pendingDataJson != null && pendingDataJson.isNotEmpty) {
        final pendingData = jsonDecode(pendingDataJson) as Map<String, dynamic>;
        if (pendingData.containsKey('createdAt') &&
            pendingData['createdAt'] == 'SERVER_TIMESTAMP') {
          pendingData['createdAt'] = FieldValue.serverTimestamp();
        }
        return pendingData;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting pending user data: $e');
      return null;
    }
  }

  Future<bool> retryPendingUserData(String userId) async {
    try {
      final pendingData = await _getPendingUserData(userId);
      if (pendingData == null) {
        debugPrint('No pending user data found for: $userId');
        return true;
      }

      debugPrint('Retrying to save pending user data for: $userId');
      await _db
          .collection('users')
          .doc(userId)
          .set(pendingData, SetOptions(merge: true));

      await _clearPendingUserData(userId);
      debugPrint('Pending user data saved successfully for: $userId');
      return true;
    } catch (e) {
      debugPrint('Error retrying pending user data: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user data from Firestore for $userId: $e');
      return null;
    }
  }

  Future<void> ensureUserDataExists(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint(
            'User data not found in Firestore for: $userId, checking for pending data');

        final pendingData = await _getPendingUserData(userId);
        if (pendingData != null) {
          debugPrint('Found pending user data, saving to Firestore');
          await retryPendingUserData(userId);
        } else {
          final user = _auth.currentUser;
          if (user != null && user.uid == userId) {
            debugPrint('Creating user data from Firebase Auth info');
            final userData = {
              'uid': user.uid,
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              'phone': user.phoneNumber,
              'provider': user.providerData.isNotEmpty
                  ? user.providerData.first.providerId
                  : 'unknown',
              'createdAt': FieldValue.serverTimestamp(),
            };

            try {
              await _db
                  .collection('users')
                  .doc(userId)
                  .set(userData, SetOptions(merge: true));
              debugPrint('User data created in Firestore');
            } catch (e) {
              debugPrint('Error creating user data in Firestore: $e');
              await _savePendingUserData(userId, userData);
            }
          }
        }
      } else {
        final pendingData = await _getPendingUserData(userId);
        if (pendingData != null) {
          debugPrint('User data exists, but found pending data, merging...');
          await retryPendingUserData(userId);
        }
      }
    } catch (e) {
      debugPrint('Error ensuring user data exists: $e');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final userId = user.uid;
      debugPrint('Starting account deletion for user: $userId');

      await _deleteUserDataFromFirestore(userId);

      await _deleteLocalUserData();

      await user.delete();

      debugPrint('Account deletion completed successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  Future<void> _deleteUserDataFromFirestore(String userId) async {
    try {
      debugPrint('Deleting user data from Firestore for user: $userId');

      await _db.collection('users').doc(userId).delete();

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

      debugPrint('Successfully deleted all user data from Firestore');
    } catch (e) {
      debugPrint('Error deleting user data from Firestore: $e');
      rethrow;
    }
  }

  Future<void> _deleteLocalUserData() async {
    try {
      debugPrint('Deleting local user data');

      if (Get.isRegistered<AchievementService>()) {
        final achievementService = Get.find<AchievementService>();
        final user = _auth.currentUser;
        if (user != null) {
          await achievementService.clearUserData(user.uid);
        }
      }

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
