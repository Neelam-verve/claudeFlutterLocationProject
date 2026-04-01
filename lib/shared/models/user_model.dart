import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;
  final bool isActive;
  final bool isListening;
  final String agoraChannel;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.latitude,
    this.longitude,
    this.lastSeen,
    this.isActive = true,
    this.isListening = false,
    this.agoraChannel = '',
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'user',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] ?? true,
      isListening: map['isListening'] ?? false,
      agoraChannel: map['agoraChannel'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'latitude': latitude,
      'longitude': longitude,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isActive': isActive,
      'isListening': isListening,
      'agoraChannel': agoraChannel,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    double? latitude,
    double? longitude,
    DateTime? lastSeen,
    bool? isActive,
    bool? isListening,
    String? agoraChannel,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      isActive: isActive ?? this.isActive,
      isListening: isListening ?? this.isListening,
      agoraChannel: agoraChannel ?? this.agoraChannel,
    );
  }
}
