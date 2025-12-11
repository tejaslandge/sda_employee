class ApiConstants {
  // Change to your server
  static const String baseUrl = "http://10.79.20.103:8000";
  // File URL base (used to render images stored in public folder)
  static const String fileURL = "$baseUrl";

  // Authentication endpoints
  static const String requestOtp = "$baseUrl/api/auth/request-otp";
  static const String verifyOtp  = "$baseUrl/api/auth/verify-otp";

  // Profile update (employee controller)
  static const String updateProfile = "$baseUrl/api/employee/update-profile";

  // Convenience headers
  static Map<String, String> jsonHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  static Map<String, String> authHeaders(String token) {
    if (token.isEmpty) return jsonHeaders;
    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }
}
