// lib/presentation/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/states/auth_state.dart';
import '../../domain/entities/user_entity.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return AuthNotifier(authRepository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(AuthInitial()) {
    // Check if user is already logged in when provider initializes
    checkAuthStatus();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = AuthLoading();

    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      state = AuthAuthenticated(user);
      debugPrint('✅ Login successful for: ${user.email}');
      debugPrint('👤 User role: ${user.role}');
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      state = AuthError(e.toString());
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    required String businessName,
    required UserRole role,
    String? phoneNumber,
  }) async {
    state = AuthLoading();

    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        businessName: businessName,
        role: role,
        phoneNumber: phoneNumber,
      );
      state = AuthAuthenticated(user);
      debugPrint('✅ Sign up successful for: ${user.email}');
      debugPrint('👤 User role: ${user.role}');
      debugPrint('🏢 Business: ${user.businessName}');
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      state = AuthError(e.toString());
    }
  }

  // Method for admins to create user accounts - UPDATED
  Future<void> createUserAccount({
    required String email,
    required String password,
    required String displayName,
    required String businessId,
    String? phoneNumber,
  }) async {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated to create user accounts');
    }

    final currentUser = (state as AuthAuthenticated).user;
    if (!currentUser.isAdmin) {
      throw Exception('Only admins can create user accounts');
    }

    try {
      final user = await _authRepository.createUserAccount(
        email: email,
        password: password,
        displayName: displayName,
        businessId: businessId,
        phoneNumber: phoneNumber,
      );
      debugPrint('✅ User account created: ${user.email}');
      debugPrint('🏢 User assigned to business: ${user.businessId}');
    } catch (e) {
      debugPrint('❌ User creation failed: $e');
      rethrow;
    }
  }

  // Delete user (admin only)
  Future<void> deleteUser(String userId) async {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated to delete users');
    }

    final currentUser = (state as AuthAuthenticated).user;
    if (!currentUser.isAdmin) {
      throw Exception('Only admins can delete users');
    }

    // Prevent self-deletion
    if (currentUser.id == userId) {
      throw Exception('Cannot delete your own account');
    }

    try {
      await _authRepository.deleteUser(userId);
      debugPrint('✅ User deleted successfully: $userId');
    } catch (e) {
      debugPrint('❌ User deletion failed: $e');
      rethrow;
    }
  }

  // Toggle user active status (admin only)
  Future<void> toggleUserActive(String userId, bool isActive) async {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated to update user status');
    }

    final currentUser = (state as AuthAuthenticated).user;
    if (!currentUser.isAdmin) {
      throw Exception('Only admins can update user status');
    }

    // Prevent self-deactivation
    if (currentUser.id == userId && !isActive) {
      throw Exception('Cannot deactivate your own account');
    }

    try {
      await _authRepository.toggleUserActive(userId, isActive);
      debugPrint('✅ User active status updated: $userId -> $isActive');
    } catch (e) {
      debugPrint('❌ User status update failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = AuthLoading();
    try {
      await _authRepository.signOut();
      state = AuthUnauthenticated();
      debugPrint('✅ Signed out successfully');
    } catch (e) {
      state = AuthError('Logout failed: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    state = AuthLoading();
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthAuthenticated(user);
        debugPrint('✅ User already authenticated: ${user.email}');
        debugPrint('👤 User role: ${user.role}');
      } else {
        state = AuthUnauthenticated();
        debugPrint('🔐 No user authenticated');
      }
    } catch (e) {
      debugPrint('❌ Auth check failed: $e');
      state = AuthUnauthenticated();
    }
  }

  void clearError() {
    if (state is AuthError) {
      state = AuthUnauthenticated();
    }
  }

  // Role-based access check methods
  bool canAccessDashboard() {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;
    return user.isAdmin;
  }

  bool canAccessPOS() {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;
    return user.isAdmin || user.isUser;
  }

  bool canManageUsers() {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;
    return user.isAdmin;
  }

  bool canManageProducts() {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;
    return user.isAdmin;
  }

  bool canViewReports() {
    if (state is! AuthAuthenticated) return false;
    final user = (state as AuthAuthenticated).user;
    return user.isAdmin;
  }

  // Get current user (convenience method)
  UserEntity? get currentUser {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    }
    return null;
  }

  // Check if user is admin
  bool get isAdmin {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user.isAdmin;
    }
    return false;
  }

  // Check if user is regular user
  bool get isUser {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user.isUser;
    }
    return false;
  }

  // Business name availability check
  Future<bool> isBusinessNameAvailable(String businessName) async {
    try {
      return await _authRepository.isBusinessNameAvailable(businessName);
    } catch (e) {
      debugPrint('❌ Business name check failed: $e');
      return false;
    }
  }

  // Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole newRole) async {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated to update user roles');
    }

    final currentUser = (state as AuthAuthenticated).user;
    if (!currentUser.isAdmin) {
      throw Exception('Only admins can update user roles');
    }

    // Prevent self-demotion if it's the only admin
    if (currentUser.id == userId && newRole == UserRole.user) {
      throw Exception('Cannot remove admin role from yourself');
    }

    try {
      await _authRepository.updateUserRole(userId, newRole);

      // Refresh current user data if it's the same user
      if (currentUser.id == userId) {
        await checkAuthStatus(); // Refresh auth state
      }

      debugPrint('✅ User role updated to: $newRole');
    } catch (e) {
      debugPrint('❌ Role update failed: $e');
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      debugPrint('✅ Password reset email sent to: $email');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      rethrow;
    }
  }

  // Get business users (admin only)
  Stream<List<UserEntity>> getBusinessUsers(String businessId) {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated to get business users');
    }

    final currentUser = (state as AuthAuthenticated).user;
    if (!currentUser.isAdmin || currentUser.businessId != businessId) {
      throw Exception('Access denied');
    }

    return _authRepository.getBusinessUsers(businessId);
  }

  // Migration method to fix existing users with wrong business IDs
  Future<void> migrateUserBusinessIds() async {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated to migrate users');
    }

    final currentUser = (state as AuthAuthenticated).user;
    if (!currentUser.isAdmin) {
      throw Exception('Only admins can migrate users');
    }

    try {
      await _authRepository.migrateUserBusinessIds(
        currentUser.businessId,
        currentUser.businessName,
      );
      debugPrint('✅ User migration completed successfully');
    } catch (e) {
      debugPrint('❌ User migration failed: $e');
      rethrow;
    }
  }
}
