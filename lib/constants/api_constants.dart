class ApiConstants {
  // Change to your server
  static const String baseUrl = "https://brandodigitech.com";
  // static const String baseUrl = "http://10.52.246.103:8000";
  // File URL base (used to render images stored in public folder)
  static const String fileURL = "$baseUrl";

  // Authentication endpoints
  static const String requestOtp = "$baseUrl/api/auth/request-otp";
  static const String verifyOtp = "$baseUrl/api/auth/verify-otp";

  // Profile update (employee controller)
  static const String updateProfile = "$baseUrl/api/employee/update-profile";

  // Leads endpoints
  static const String leads = "$baseUrl/api/leads";
  static const String leadsCreate = "$baseUrl/api/createlead";
  static const String clients = "$baseUrl/api/clients";

  // Client Ads
  static const String clientAds = "$baseUrl/api/clients";
  // usage: /clients/{clientId}/ads

  // Upload Ad
  static const String uploadAd = "$baseUrl/api/ads";

  // ---------------- FOLLOW UPS ----------------
  static const String addFollowUp = "$baseUrl/api/lead-followups";
  static const String getFollowUps = "$baseUrl/api/lead-followups";
  // usage: /lead-followups/{lead_id}

  // ---------------- HEADERS ----------------

  /// Base JSON headers
  static const Map<String, String> jsonHeaders = {
    "Content-Type": "application/json",
    "Accept": "application/json",
  };

  /// Auth headers (always includes JSON headers)
  static Map<String, String> authHeaders(String token) {
    return {
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
  }
}
