// API Constants
// Constants yang digunakan untuk API communication

class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://dopply.my.id/api/v1';
  static const String staticBaseUrl = 'https://dopply.my.id/static';

  // Authentication Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String refreshToken = '/refresh';
  static const String verifyToken = '/token/verify';
  static const String uploadPhoto = '/user/photo';

  // User Management Endpoints
  static const String userRecords = '/records';
  static const String updateEmail = '/account/email';
  static const String updatePassword = '/account/password';
  static const String users = '/users'; // Admin only

  // Medical Monitoring Endpoints
  static const String monitoring = '/monitoring';
  static const String classifyBmp = '/classify_bmp';
  static const String monitoringRecord = '/monitoring_record';
  static const String patientMonitoring = '/patient/monitoring';
  static const String patientMonitoringHistory = '/patient/monitoring/history';
  static const String shareMonitoring = '/patient/share_monitoring';

  // Doctor Management Endpoints
  static const String doctorList = '/doctor/list';
  static const String patientsByDoctor = '/patients/by-doctor';
  static const String doctorValidationCount =
      '/doctor/validation-requests/count';
  static const String doctorValidationList = '/doctor/validation-requests';

  // Patient Management Endpoints
  static const String patients = '/patients';
  static const String patientProfile = '/patient/profile';

  // Role Constants
  static const String roleAdmin = 'admin';
  static const String roleDoctor = 'doctor';
  static const String rolePatient = 'patient';

  // Classification Constants
  static const String classificationNormal = 'normal';
  static const String classificationAbnormal = 'abnormal';
  static const String classificationWarning = 'warning';
  static const String classificationCritical = 'critical';

  // Monitoring Status
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // HTTP Status Codes
  static const int statusOk = 200;
  static const int statusCreated = 201;
  static const int statusBadRequest = 400;
  static const int statusUnauthorized = 401;
  static const int statusForbidden = 403;
  static const int statusNotFound = 404;
  static const int statusInternalServerError = 500;

  // Request Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';
  static const String bearerPrefix = 'Bearer ';

  // Content Types
  static const String applicationJson = 'application/json';
  static const String multipartFormData = 'multipart/form-data';
}
