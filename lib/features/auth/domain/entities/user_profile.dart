import 'user_role.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String bloodGroup;
  final String allergies;
  final String medicalNotes;
  final String emergencyContact1;
  final String emergencyContact2;
  final UserRole role;
  final ServiceType? serviceType;
  final String profileImage;
  final String fcmToken;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.bloodGroup,
    required this.allergies,
    required this.medicalNotes,
    required this.emergencyContact1,
    required this.emergencyContact2,
    this.role = UserRole.citizen,
    this.serviceType,
    this.profileImage = '',
    this.fcmToken = '',
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? bloodGroup,
    String? allergies,
    String? medicalNotes,
    String? emergencyContact1,
    String? emergencyContact2,
    UserRole? role,
    ServiceType? serviceType,
    String? profileImage,
    String? fcmToken,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      emergencyContact1: emergencyContact1 ?? this.emergencyContact1,
      emergencyContact2: emergencyContact2 ?? this.emergencyContact2,
      role: role ?? this.role,
      serviceType: serviceType ?? this.serviceType,
      profileImage: profileImage ?? this.profileImage,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

