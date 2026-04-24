// lib/data/repositories/auth_repository.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/user_entity.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<UserEntity?> get userStream {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!userDoc.exists) return null;

      return UserEntity.fromMap(userDoc.data()!);
    });
  }

  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return UserEntity.fromMap(userDoc.data()!);
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  Future<UserEntity> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User document not found');
      }

      final userData = userDoc.data()!;
      if (userData['isActive'] == false) {
        throw Exception('Account is deactivated');
      }

      // Update last active timestamp
      await _firestore.collection('users').doc(userCredential.user!.uid).update(
        {'lastActive': Timestamp.now()},
      );

      return UserEntity.fromMap(userData);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String businessName,
    required UserRole role,
    String? phoneNumber,
    String? businessId, // For adding users to existing business
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user!;

      // FIX: Determine business ID properly
      String finalBusinessId;
      String finalBusinessName;

      if (role == UserRole.admin) {
        // Admin creates new business - use user ID as business ID
        finalBusinessId = user.uid;
        finalBusinessName = businessName;
      } else {
        // User joins existing business - use provided business ID
        if (businessId == null || businessId.isEmpty) {
          throw Exception('Business ID is required for user accounts');
        }
        finalBusinessId = businessId;

        // Get the actual business name from the business document
        final businessDoc = await _firestore
            .collection('businesses')
            .doc(businessId)
            .get();
        if (!businessDoc.exists) {
          throw Exception('Business not found with ID: $businessId');
        }
        finalBusinessName = businessDoc.data()!['name'] ?? businessName;
      }

      // Create user document in Firestore
      final userEntity = UserEntity(
        id: user.uid,
        email: email,
        displayName: displayName,
        businessId: finalBusinessId, // Use the correct business ID
        businessName: finalBusinessName, // Use the correct business name
        role: role,
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        isActive: true,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userEntity.toMap());

      // If this is an admin, create business document
      if (role == UserRole.admin) {
        await _createBusinessDocument(
          businessId: finalBusinessId,
          businessName: finalBusinessName,
          ownerId: user.uid,
          ownerEmail: email,
          phoneNumber: phoneNumber,
        );
      } else {
        // For users, increment user count in business document
        await _incrementBusinessUserCount(finalBusinessId);
      }

      debugPrint('✅ User created: $email with role: $role');
      debugPrint('🏢 Business ID: $finalBusinessId');
      debugPrint('🏢 Business Name: $finalBusinessName');

      if (role == UserRole.admin) {
        debugPrint('✅ Business created: $businessName (ID: $finalBusinessId)');
      }

      return userEntity;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e));
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<void> _createBusinessDocument({
    required String businessId,
    required String businessName,
    required String ownerId,
    required String ownerEmail,
    String? phoneNumber,
  }) async {
    await _firestore.collection('businesses').doc(businessId).set({
      'id': businessId,
      'name': businessName,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'isActive': true,
      'userCount': 1,
      'plan': 'starter', // Free starter plan
      'settings': {
        'currency': 'GHS',
        'taxRate': 0.03, // 3% default tax
        'receiptFooter': 'Thank you for your business!',
      },
    });
  }

  Future<void> _incrementBusinessUserCount(String businessId) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'userCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });
  }

  // Method for admins to create user accounts - UPDATED
  Future<UserEntity> createUserAccount({
    required String email,
    required String password,
    required String displayName,
    required String businessId, // Admin must provide their business ID
    String? phoneNumber,
  }) async {
    // First, get the business name from the business document
    final businessDoc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .get();
    if (!businessDoc.exists) {
      throw Exception('Business not found with ID: $businessId');
    }

    final businessName = businessDoc.data()!['name'] ?? 'Unknown Business';

    return signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
      businessName: businessName,
      businessId: businessId, // Pass the existing business ID
      role: UserRole.user,
      phoneNumber: phoneNumber,
    );
  }

  // Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    try {
      // First, get user data to check if it's the last admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final user = UserEntity.fromMap(userDoc.data()!);

      // Check if this is the last admin in the business
      if (user.isAdmin) {
        final adminCount = await _getAdminCount(user.businessId);
        if (adminCount <= 1) {
          throw Exception('Cannot delete the last admin user in the business');
        }
      }

      // Delete user from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Decrement user count in business
      await _decrementBusinessUserCount(user.businessId);

      debugPrint('✅ User deleted from Firestore: $userId');
    } catch (e) {
      debugPrint('❌ Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  // Toggle user active status (admin only)
  Future<void> toggleUserActive(String userId, bool isActive) async {
    try {
      // First, get user data to check if it's the last admin
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final user = UserEntity.fromMap(userDoc.data()!);

      // Check if trying to deactivate the last admin
      if (user.isAdmin && !isActive) {
        final adminCount = await _getAdminCount(user.businessId);
        if (adminCount <= 1) {
          throw Exception(
            'Cannot deactivate the last admin user in the business',
          );
        }
      }

      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'lastActive': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      debugPrint('✅ User active status updated: $userId -> $isActive');
    } catch (e) {
      debugPrint('❌ Error updating user active status: $e');
      throw Exception('Failed to update user status: $e');
    }
  }

  // Helper method to get admin count for a business
  Future<int> _getAdminCount(String businessId) async {
    final query = await _firestore
        .collection('users')
        .where('businessId', isEqualTo: businessId)
        .where('role', isEqualTo: 'admin')
        .where('isActive', isEqualTo: true)
        .get();

    return query.docs.length;
  }

  // Helper method to decrement user count in business
  Future<void> _decrementBusinessUserCount(String businessId) async {
    await _firestore.collection('businesses').doc(businessId).update({
      'userCount': FieldValue.increment(-1),
      'updatedAt': Timestamp.now(),
    });
  }

  // Check if business name is available
  Future<bool> isBusinessNameAvailable(String businessName) async {
    final query = await _firestore
        .collection('businesses')
        .where('name', isEqualTo: businessName)
        .limit(1)
        .get();

    return query.docs.isEmpty;
  }

  // Get business by ID
  Future<Map<String, dynamic>?> getBusiness(String businessId) async {
    final doc = await _firestore.collection('businesses').doc(businessId).get();
    return doc.data();
  }

  // Get all users for a business (admin only)
  Stream<List<UserEntity>> getBusinessUsers(String businessId) {
    return _firestore
        .collection('users')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserEntity.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<void> updateUserProfile(UserEntity user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    await _firestore.collection('users').doc(userId).update({
      'role': newRole.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deactivateUser(String userId) async {
    await toggleUserActive(userId, false);
  }

  Future<void> deleteUserAccount(String userId) async {
    final user = _firebaseAuth.currentUser;
    if (user != null && user.uid == userId) {
      await _firestore.collection('users').doc(userId).delete();
      await user.delete();
    }
  }

  // Update last active timestamp
  Future<void> updateLastActive(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastActive': Timestamp.now(),
    });
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Migration method to fix existing users with wrong business IDs
  Future<void> migrateUserBusinessIds(
    String correctBusinessId,
    String correctBusinessName,
  ) async {
    try {
      // Get all users that might have wrong business IDs
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'user')
          .get();

      int fixedCount = 0;

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final currentBusinessId = userData['businessId'];

        // If business ID is the user's own ID (wrong), fix it
        if (currentBusinessId == userDoc.id) {
          debugPrint('🔄 Fixing user: ${userData['email']}');

          await _firestore.collection('users').doc(userDoc.id).update({
            'businessId': correctBusinessId,
            'businessName': correctBusinessName,
            'updatedAt': Timestamp.now(),
          });

          debugPrint('✅ Fixed user: ${userData['email']}');
          fixedCount++;
        }
      }

      debugPrint('🎉 Migration complete: Fixed $fixedCount users');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
      throw Exception('Migration failed: $e');
    }
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
