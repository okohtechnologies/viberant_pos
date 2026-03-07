// lib/domain/entities/business_entity.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessEntity {
  final String id;
  final String name;
  final String ownerId;
  final String ownerEmail;
  final String? phoneNumber;
  final String? address;
  final DateTime createdAt;
  final bool isActive;
  final int userCount;

  const BusinessEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerEmail,
    this.phoneNumber,
    this.address,
    required this.createdAt,
    required this.isActive,
    required this.userCount,
  });

  factory BusinessEntity.fromMap(Map<String, dynamic> map) {
    return BusinessEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerEmail: map['ownerEmail'] ?? '',
      phoneNumber: map['phoneNumber'],
      address: map['address'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      userCount: (map['userCount'] ?? 1).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'userCount': userCount,
    };
  }
}
