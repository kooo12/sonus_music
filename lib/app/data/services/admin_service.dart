import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

/// Service for managing admin users and admin-specific operations
class AdminService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Check if a specific user is admin
  Future<bool> isUserAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data();
      return userData?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin status for user $userId: $e');
      return false;
    }
  }

  /// Promote a user to admin
  Future<bool> promoteToAdmin(String userId) async {
    try {
      // Check if current user is admin
      if (!await isCurrentUserAdmin()) {
        debugPrint('Only admins can promote users to admin');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isAdmin': true,
        'promotedAt': FieldValue.serverTimestamp(),
        'promotedBy': auth.currentUser?.uid,
      });

      debugPrint('User $userId promoted to admin');
      return true;
    } catch (e) {
      debugPrint('Error promoting user to admin: $e');
      return false;
    }
  }

  /// Demote an admin to regular user
  Future<bool> demoteFromAdmin(String userId) async {
    try {
      // Check if current user is admin
      if (!await isCurrentUserAdmin()) {
        debugPrint('Only admins can demote users from admin');
        return false;
      }

      // Prevent self-demotion
      if (userId == auth.currentUser?.uid) {
        debugPrint('Cannot demote yourself from admin');
        return false;
      }

      await _firestore.collection('users').doc(userId).update({
        'isAdmin': false,
        'demotedAt': FieldValue.serverTimestamp(),
        'demotedBy': auth.currentUser?.uid,
      });

      debugPrint('User $userId demoted from admin');
      return true;
    } catch (e) {
      debugPrint('Error demoting user from admin: $e');
      return false;
    }
  }

  /// Get all admin users
  Future<List<UserModel>> getAllAdmins() async {
    try {
      if (!await isCurrentUserAdmin()) {
        debugPrint('Only admins can view all admins');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all admins: $e');
      return [];
    }
  }

  /// Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      if (!await isCurrentUserAdmin()) {
        debugPrint('Only admins can view all users');
        return [];
      }

      final querySnapshot = await _firestore.collection('users').get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  /// Create admin account (for initial setup)
  Future<bool> createAdminAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);

        // Create user document with admin privileges
        final adminUser = UserModel.admin(
          id: userCredential.user!.uid,
          name: displayName,
          email: email,
          provider: 'password',
        );

        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(adminUser.toJson());

        debugPrint('Admin account created for $email');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error creating admin account: $e');
      return false;
    }
  }

  /// Get admin statistics
  Future<AdminStats> getAdminStats() async {
    try {
      if (!await isCurrentUserAdmin()) {
        debugPrint('Only admins can view admin stats');
        return AdminStats(
          totalUsers: 0,
          totalAdmins: 0,
          totalFcmTokens: 0,
          activeFcmTokens: 0,
        );
      }

      final usersSnapshot = await _firestore.collection('users').get();
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('isAdmin', isEqualTo: true)
          .get();
      final fcmTokensSnapshot = await _firestore.collection('fcm_tokens').get();
      final activeFcmTokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .where('isActive', isEqualTo: true)
          .get();

      return AdminStats(
        totalUsers: usersSnapshot.docs.length,
        totalAdmins: adminsSnapshot.docs.length,
        totalFcmTokens: fcmTokensSnapshot.docs.length,
        activeFcmTokens: activeFcmTokensSnapshot.docs.length,
      );
    } catch (e) {
      debugPrint('Error getting admin stats: $e');
      return AdminStats(
        totalUsers: 0,
        totalAdmins: 0,
        totalFcmTokens: 0,
        activeFcmTokens: 0,
      );
    }
  }
}

/// Statistics for admin dashboard
class AdminStats {
  final int totalUsers;
  final int totalAdmins;
  final int totalFcmTokens;
  final int activeFcmTokens;

  AdminStats({
    required this.totalUsers,
    required this.totalAdmins,
    required this.totalFcmTokens,
    required this.activeFcmTokens,
  });

  @override
  String toString() {
    return 'AdminStats{users: $totalUsers, admins: $totalAdmins, fcmTokens: $totalFcmTokens, activeFcmTokens: $activeFcmTokens}';
  }
}
