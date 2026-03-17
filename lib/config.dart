class AppConfig {
  // Local test: Android emulator → 'http://10.0.2.2:3000'
  //             iOS simulator    → 'http://localhost:3000'
  // Production: DigitalOcean / Render URL
  static const String backendUrl = 'https://stingray-app-dyiy2.ondigitalocean.app';

  static const String chatEndpoint     = '$backendUrl/api/chat';
  static const String usersEndpoint    = '$backendUrl/api/users';
  static const String bookingsEndpoint = '$backendUrl/api/bookings';
  static const String scheduleEndpoint = '$backendUrl/api/schedule';
}
