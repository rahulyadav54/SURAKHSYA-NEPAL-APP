import '../../domain/entities/user_profile.dart';

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
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      medicalNotes: json['medical_notes'] as String? ?? '',
      emergencyContact1: json['emergency_contact_1'] as String? ?? '',
      emergencyContact2: json['emergency_contact_2'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'blood_group': bloodGroup,
      'allergies': allergies,
      'medical_notes': medicalNotes,
      'emergency_contact_1': emergencyContact1,
      'emergency_contact_2': emergencyContact2,
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
    );
  }
}
