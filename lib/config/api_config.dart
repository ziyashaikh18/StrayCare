
import 'dart:async';
import 'dart:io';

class ApiConfig {
  // Your Render backend URL (NO trailing slash)
  static const String baseUrl =
      "https://straycare-y6h7.onrender.com";

  // API timeout
  static const Duration requestTimeout = Duration(seconds: 60);

  // Common API endpoints
  static const String login = "$baseUrl/api/auth/login";
  static const String signup = "$baseUrl/api/auth/signup";
  static const String report = "$baseUrl/api/reports";
  static const String aiAnalyze = "$baseUrl/api/ai/analyze";

  // Friendly error messages
  static String messageFor(Object error, {String? fallback}) {
    if (error is TimeoutException) {
      return "Request timed out. Please try again.";
    }

    if (error is SocketException) {
      return "Cannot connect to the server. Check your internet connection.";
    }

    return fallback ?? "Something went wrong. Please try again.";
  }
}