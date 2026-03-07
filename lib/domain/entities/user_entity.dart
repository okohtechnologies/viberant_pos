// lib/domain/entities/user_entity.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, user }

class UserEntity {
  final String id;
  final String email;
  final String displayName;
  final String businessId;
  final String businessName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastActive;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    required this.businessId,
    required this.businessName,
    required this.role,
    required this.createdAt,
    this.lastActive,
    required this.isActive,
  });

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      role: _roleFromString(map['role'] ?? 'user'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'businessId': businessId,
      'businessName': businessName,
      'role': _roleToString(role),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'isActive': isActive,
    };
  }

  static UserRole _roleFromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'user':
        return UserRole.user;
      default:
        return UserRole.user;
    }
  }

  static String _roleToString(UserRole role) {
    return role.toString().split('.').last;
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isUser => role == UserRole.user;

  UserEntity copyWith({
    String? email,
    String? displayName,
    String? businessName,
    UserRole? role,
    DateTime? lastActive,
    bool? isActive,
  }) {
    return UserEntity(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      businessId: businessId,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
      isActive: isActive ?? this.isActive,
    );
  }
}
