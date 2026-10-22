class ApiEndpoints {
  // Auth
  static const String register = '/Auth/register';
  static const String verifyRegistrationOtp = '/Auth/verify-registration-otp';
  static const String login = '/Auth/login';
  static const String verifyLoginOtp = '/Auth/verify-login-otp';
  static const String latestOtp = '/Auth/latest-otp';
  static const String refreshToken = '/Auth/refresh-token';
  static const String me = '/Auth/me';

  // Devices & Pairing
  static const String generatePairQr = '/Devices/generate-pair-qr';
  static const String pairByQr = '/Devices/pair-by-qr';
  static const String myChildren = '/Devices/my-children';
  static String setDeviceLock(String deviceId) => '/Devices/$deviceId/lock';
  static String updateHeartbeat(String deviceId) => '/Devices/$deviceId/heartbeat';

  // Location
  static const String reportLocation = '/Location/report';
  static String latestLocation(String deviceId) => '/Location/$deviceId/latest';
  static String locationHistory(String deviceId) => '/Location/$deviceId/history';

  // Sensors
  static const String reportSensor = '/Sensors/report';
  static String realtimeSensor(String deviceId) => '/Sensors/$deviceId/realtime';
  static String sensorLogs(String deviceId) => '/Sensors/$deviceId/logs';

  // Rules & Focus
  static String childRules(String childId) => '/Rules/$childId';
  static const String createRule = '/Rules';
  static String updateRule(String ruleId) => '/Rules/$ruleId';
  static String deleteRule(String ruleId) => '/Rules/$ruleId';
  static String toggleAppBlock(String appId) => '/Rules/apps/$appId/toggle-block';

  static String focusSchedules(String childId) => '/FocusSchedules/$childId';
  static const String createFocusSchedule = '/FocusSchedules';
  static String toggleFocusSchedule(String id) => '/FocusSchedules/$id/toggle';
  static String deleteFocusSchedule(String id) => '/FocusSchedules/$id';

  // Analytics
  static const String syncApps = '/Analytics/sync-apps';
  static String deviceApps(String deviceId) => '/Analytics/apps/$deviceId';
  static const String reportUsage = '/Analytics/report-usage';
  static String dailySummary(String childId) => '/Analytics/$childId/daily-summary';

  // SOS
  static const String triggerSos = '/Sos/trigger';
  static const String activeSos = '/Sos/active';
  static String resolveSos(String alertId) => '/Sos/$alertId/resolve';

  // Admin
  static const String adminDashboardStats = '/Admin/dashboard-stats';
  static const String adminUsers = '/Admin/users';
  static const String adminToggleUserStatus = '/Admin/users/toggle-status';
  static const String adminCategories = '/Admin/categories';
}
