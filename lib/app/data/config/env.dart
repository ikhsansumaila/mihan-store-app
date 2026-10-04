import 'package:envied/envied.dart';

part 'env.g.dart';

/// Nilai dibaca dari file `.env` saat build_runner dijalankan, lalu di-obfuscate
/// (XOR + random key) di `env.g.dart` agar tidak muncul sebagai plain text di binary.
@Envied(path: '.env', obfuscate: true)
abstract class Env {
  @EnviedField(varName: 'API_BASE_URL')
  static final String apiBaseUrl = _Env.apiBaseUrl;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID')
  static final String googleClientId = _Env.googleClientId;

  @EnviedField(varName: 'ADMIN_EMAILS')
  static final String adminEmails = _Env.adminEmails;

  // Site key Cloudflare Turnstile (sama dengan TURNSTILE_SITE_KEY di mihan-store-web).
  // Kosong = login/daftar dengan password tidak tersedia (backend fail-closed).
  @EnviedField(varName: 'TURNSTILE_SITE_KEY', defaultValue: '')
  static final String turnstileSiteKey = _Env.turnstileSiteKey;
}
