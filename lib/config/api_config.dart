
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiConfig {
  // Your Render backend URL (NO trailing slash)
  static const String baseUrl =
      "https://straycare-y6h7.onrender.com";

  // API timeout (set to 120s to account for Render cold-starts + vision AI processing)
  static const Duration requestTimeout = Duration(seconds: 120);

  // Common API endpoints
  static const String health = "$baseUrl/api/health";
  static const String login = "$baseUrl/api/auth/login";
  static const String signup = "$baseUrl/api/auth/signup";
  static const String report = "$baseUrl/api/reports";
  static const String aiAnalyze = "$baseUrl/api/ai/analyze";

  /// Silently wakes up Render backend if it is sleeping on free tier
  static void prewarmServer() {
    try {
      http.get(Uri.parse(health)).timeout(const Duration(seconds: 10)).catchError((_) => http.Response('', 500));
    } catch (_) {}
  }

  // Friendly error messages
  static String messageFor(Object error, {String? fallback}) {
    if (error is TimeoutException) {
      return "Request timed out. The server might be waking up, please try again.";
    }

    if (error is SocketException) {
      return "Cannot connect to the server. Check your internet connection.";
    }

    return fallback ?? "Something went wrong. Please try again.";
  }
}