enum Environment { local, uat, prod }

class ApiConstants {
  /// Change only here for juniors / builds.
  static Environment current = Environment.uat;

  static String get baseUrl {
    switch (current) {
      case Environment.local:
        // Android emulator → host machine: use 10.0.2.2 instead of localhost.
        // iOS simulator can use localhost.
        return 'http://localhost:3004/api';
      case Environment.uat:
        return 'https://erp-uat.immortalgroup.in/api';
      case Environment.prod:
        return 'https://hrms.immortaltechnovation.com/api-hrms/api';
    }
  }

  static String get imageBaseUrl => '$baseUrl/uploads/';
  static String get selfieBaseUrl => '$baseUrl/uploads/attendance/';
  static String get companyLogoBaseUrl => '$baseUrl/uploads/company/';
}
