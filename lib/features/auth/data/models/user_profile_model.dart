import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_role.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.id,
    required super.fullName,
    required super.email,
    required super.phone,
    required super.bloodGroup,
    required super.allergies,
    required super.medicalNotes,
    required super.emergencyContact1,
    required super.emergencyContact2,
    super.role = UserRole.citizen,
    super.serviceType,
    super.profileImage = '',
    super.fcmToken = '',
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String?;
    final serviceTypeStr = json['service_type'] as String?;
    return UserProfileModel(
      id: (json['id'] ?? json['firebase_uid']) as String? ?? '',
      fullName: (json['full_name'] ?? json['fullName']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bloodGroup: (json['blood_group'] ?? json['bloodGroup']) as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      medicalNotes: (json['medical_notes'] ?? json['medicalNotes']) as String? ?? '',
      emergencyContact1: (json['emergency_contact_1'] ?? json['emergencyContact1']) as String? ?? '',
      emergencyContact2: (json['emergency_contact_2'] ?? json['emergencyContact2']) as String? ?? '',
      role: UserRole.fromString(roleStr),
      serviceType: serviceTypeStr != null ? ServiceType.fromString(serviceTypeStr) : null,
      profileImage: (json['profile_image'] ?? json['profileImage']) as String? ?? '',
      fcmToken: (json['fcm_token'] ?? json['fcmToken']) as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebase_uid': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'service_type': serviceType?.value,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'medical_notes': medicalNotes,
      'emergency_contact_1': emergencyContact1,
      'emergency_contact_2': emergencyContact2,
      'profile_image': profileImage,
      'fcm_token': fcmToken,
    };
  }

  factory UserProfileModel.fromEntity(UserProfile profile) {
    return UserProfileModel(
      id: profile.id,
      fullName: profile.fullName,
      email: profile.email,
      phone: profile.phone,
      bloodGroup: profile.bloodGroup,
      allergies: profile.allergies,
      medicalNotes: profile.medicalNotes,
      emergencyContact1: profile.emergencyContact1,
      emergencyContact2: profile.emergencyContact2,
      role: profile.role,
      serviceType: profile.serviceType,
      profileImage: profile.profileImage,
      fcmToken: profile.fcmToken,
    );
  }
}

