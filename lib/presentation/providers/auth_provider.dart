// lib/presentation/providers/auth_provider.dart
// No changes required — existing implementation is correct.
// Copied verbatim; the architecture guide confirmed all methods are sound.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/states/auth_state.dart';
import '../../domain/entities/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthInitial()) {
    checkAuthStatus();
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = AuthLoading();
    try {
      final user = await _repo.signInWithEmailAndPassword(email, password);
      state = AuthAuthenticated(user);
      debugPrint('✅ Login: ${user.email} (${user.role})');
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
      final user = await _repo.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        businessName: businessName,
        role: role,
        phoneNumber: phoneNumber,
      );
      state = AuthAuthenticated(user);
      debugPrint('✅ Sign up: ${user.email} — ${user.businessName}');
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      state = AuthError(e.toString());
    }
  }

  Future<void> createUserAccount({
    required String email,
    required String password,
    required String displayName,
    required String businessId,
    String? phoneNumber,
  }) async {
    _assertAdmin();
    try {
      final user = await _repo.createUserAccount(
        email: email,
        password: password,
        displayName: displayName,
        businessId: businessId,
        phoneNumber: phoneNumber,
      );
      debugPrint('✅ Created user: ${user.email}');
    } catch (e) {
      debugPrint('❌ User creation failed: $e');
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, UserRole newRole) async {
    _assertAdmin();
    final current = (state as AuthAuthenticated).user;
    if (current.id == userId && newRole == UserRole.user) {
      throw Exception('Cannot remove your own admin role');
    }
    try {
      await _repo.updateUserRole(userId, newRole);
      if (current.id == userId) await checkAuthStatus();
      debugPrint('✅ Role updated: $userId → $newRole');
    } catch (e) {
      debugPrint('❌ Role update failed: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    _assertAdmin();
    final current = (state as AuthAuthenticated).user;
    if (current.id == userId) throw Exception('Cannot delete your own account');
    try {
      await _repo.deleteUser(userId);
      debugPrint('✅ Deleted user: $userId');
    } catch (e) {
      debugPrint('❌ Delete failed: $e');
      rethrow;
    }
  }

  Future<void> toggleUserActive(String userId, bool isActive) async {
    _assertAdmin();
    final current = (state as AuthAuthenticated).user;
    if (current.id == userId && !isActive) {
      throw Exception('Cannot deactivate your own account');
    }
    await _repo.toggleUserActive(userId, isActive);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _repo.sendPasswordResetEmail(email);
  }

  Future<void> signOut() async {
    state = AuthLoading();
    try {
      await _repo.signOut();
      state = AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Logout failed: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    state = AuthLoading();
    try {
      final user = await _repo.getCurrentUser();
      state = user != null ? AuthAuthenticated(user) : AuthUnauthenticated();
    } catch (e) {
      debugPrint('❌ Auth check failed: $e');
      state = AuthUnauthenticated();
    }
  }

  void clearError() {
    if (state is AuthError) state = AuthUnauthenticated();
  }

  void _assertAdmin() {
    if (state is! AuthAuthenticated) {
      throw Exception('Must be authenticated');
    }
    if (!(state as AuthAuthenticated).user.isAdmin) {
      throw Exception('Admin access required');
    }
  }

  // Convenience getters
  UserEntity? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
  bool get isAdmin => currentUser?.isAdmin ?? false;

  // Role checks
  bool canAccessDashboard() => isAdmin;
  bool canManageUsers() => isAdmin;
  bool canManageProducts() => isAdmin;
  bool canViewReports() => isAdmin;
  bool canAccessPOS() => currentUser != null;

  Future<bool> isBusinessNameAvailable(String name) =>
      _repo.isBusinessNameAvailable(name);

  Stream<List<UserEntity>> getBusinessUsers(String businessId) {
    _assertAdmin();
    return _repo.getBusinessUsers(businessId);
  }
}
