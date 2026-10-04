import 'package:flutter/foundation.dart';

import 'env.dart';

class ApiConfig {
  static final String baseUrl = Env.apiBaseUrl;
  static const String imageBaseUrl = "https://store.mihan.web.id";

  // Turnstile dimuat di WebView dengan origin situs toko agar lolos daftar hostname site key.
  static const String turnstileBaseUrl = "https://store.mihan.web.id/";
  static final String turnstileSiteKey = Env.turnstileSiteKey;

  static const String products = "/products";
  static const String categories = "/categories";
  static const String authLogin = "/auth/login";
  static const String authLogout = "/auth/logout";
  static const String authRegister = "/auth/register";
  static const String authVerify = "/auth/verify";
  static const String authMe = "/auth/me";
  static const String authGoogle = "/auth/google";
  static const String authGoogleComplete = "/auth/google/complete";

  static const String cart = "/cart";
  static const String cartItems = "/cart/items";
  static const String cartAckPrices = "/cart/ack-prices";
  static const String orders = "/orders";
  static const String storeInfo = "/store-info";
  static const String regions = "/regions";

  // Google OAuth Client ID dari mihan-store-web (dibaca dari .env via envied)
  static final String _googleClientIdDebug = Env.googleClientIdDebug;
  static final String _googleClientIdRelease = Env.googleClientIdRelease;

  static String get googleClientId => kDebugMode ? _googleClientIdDebug : _googleClientIdRelease;

  // Email Admin dari .env via envied (dipisah koma)
  static final String _adminEmailsEnv = Env.adminEmails;

  static List<String> get adminEmails => _adminEmailsEnv
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .where((e) => e.isNotEmpty)
      .toList();

  static bool isAdminEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    return adminEmails.contains(email.trim().toLowerCase());
  }

  static const int timeoutDuration = 15; // seconds
}
