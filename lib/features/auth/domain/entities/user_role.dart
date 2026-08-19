enum UserRole {
  citizen('CITIZEN', 'Citizen / General Public'),
  responder('RESPONDER', 'Emergency Responder'),
  dispatcher('DISPATCHER', 'Emergency Dispatcher'),
  hospital('HOSPITAL', 'Hospital Staff'),
  admin('ADMIN', 'Super Admin');

  final String value;
  final String label;

  const UserRole(this.value, this.label);

  static UserRole fromString(String? roleStr) {
    switch (roleStr?.toUpperCase()) {
      case 'RESPONDER':
        return UserRole.responder;
      case 'DISPATCHER':
        return UserRole.dispatcher;
      case 'HOSPITAL':
        return UserRole.hospital;
      case 'ADMIN':
        return UserRole.admin;
      case 'CITIZEN':
      default:
        return UserRole.citizen;
    }
  }
}

enum ServiceType {
  ambulance('AMBULANCE', 'Ambulance Service'),
  police('POLICE', 'Police Response'),
  fireBrigade('FIRE_BRIGADE', 'Fire Brigade');

  final String value;
  final String label;

  const ServiceType(this.value, this.label);

  static ServiceType fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'POLICE':
        return ServiceType.police;
      case 'FIRE_BRIGADE':
      case 'FIRE':
        return ServiceType.fireBrigade;
      case 'AMBULANCE':
      default:
        return ServiceType.ambulance;
    }
  }
}
