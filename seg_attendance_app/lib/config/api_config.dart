class ApiConfig {
  static const String baseUrl =
      "https://seg-attendance-backend.onrender.com/api";

  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}