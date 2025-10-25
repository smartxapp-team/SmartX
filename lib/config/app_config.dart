class AppConfig {
  // --- API Configuration ---
  // To use the deployed backend, uncomment the Render URL.
  // To use a local backend, use the appropriate IP address for your network.

  // Publicly deployed backend URL
  // static const String apiUrl = 'https://smartx-backend-black.vercel.app/';

  // Local network backend URLs (uncomment the one you need)
  static const String apiUrl = 'http://192.168.88.86:5000'; // For physical device on same Wi-Fi
  // static const String apiUrl = 'http://10.0.2.2:5000'; // For Android Emulator
}
