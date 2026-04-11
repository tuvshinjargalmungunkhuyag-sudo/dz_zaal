class AppConfig {
  // Local test: Android emulator → 'http://10.0.2.2:3000'
  //             iOS simulator    → 'http://localhost:3000'
  // Production: AWS EC2 (ap-northeast-1, Tokyo)
  static const String backendUrl = 'http://13.112.91.27:3000';

  static const String chatEndpoint     = '$backendUrl/api/chat';
  static const String usersEndpoint    = '$backendUrl/api/users';
  static const String bookingsEndpoint = '$backendUrl/api/bookings';
  static const String scheduleEndpoint = '$backendUrl/api/schedule';
  static const String authEndpoint     = '$backendUrl/api/auth';
}
