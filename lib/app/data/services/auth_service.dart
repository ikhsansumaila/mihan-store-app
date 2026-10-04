import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Profil Google yang belum punya akun (login Google pertama kali -> layar "Lengkapi profil").
class GoogleProfilePending {
  final String profileToken;
  final String email;
  final String name;
  final String? avatarUrl;
  final String suggestedUsername;

  const GoogleProfilePending({
    required this.profileToken,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.suggestedUsername,
  });
}

class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;
  final GoogleProfilePending? pendingProfile;

  const AuthResult({
    required this.success,
    required this.message,
    this.user,
    this.token,
    this.pendingProfile,
  });
}

class AuthService {
  final ApiClient _api = ApiClient.instance;

  AuthResult _session(dynamic data, String fallbackMsg, {bool isGoogle = false}) {
    final Map j = data is Map ? data : const {};
    final userData = j['user'];
    return AuthResult(
      success: j['success'] == true,
      message: asStrOrNull(j['message']) ?? fallbackMsg,
      user: userData is Map<String, dynamic> ? UserModel.fromJson(userData, isGoogle: isGoogle) : null,
      token: asStrOrNull(j['token']),
    );
  }

  Future<AuthResult> login({
    required String identifier,
    required String password,
    required String turnstileToken,
  }) async {
    try {
      final data = await _api.post(
        ApiConfig.authLogin,
        {'identifier': identifier.trim(), 'password': password, 'turnstileToken': turnstileToken},
        false,
      );
      return _session(data, 'Login berhasil');
    } catch (e) {
      return AuthResult(success: false, message: apiErrorMessage(e, 'Login gagal, coba lagi.'));
    }
  }

  /// Field sudah dinormalkan pemanggil (username huruf kecil, telepon +628xx atau '').
  Future<AuthResult> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String turnstileToken,
  }) async {
    try {
      final data = await _api.post(
        ApiConfig.authRegister,
        {
          'username': username,
          'email': email,
          'phone': phone,
          'name': name,
          'password': password,
          'turnstileToken': turnstileToken,
        },
        false,
      );
      final r = _session(data, 'Registrasi berhasil');
      return r.success ? r : AuthResult(success: false, message: r.message);
    } catch (e) {
      return AuthResult(success: false, message: apiErrorMessage(e, 'Terjadi kesalahan saat registrasi'));
    }
  }

  /// GET /auth/me (role dibaca dari database). null = server tidak bisa dihubungi.
  Future<UserModel?> me() async {
    final data = await _api.get(ApiConfig.authMe);
    final u = data is Map ? data['user'] : null;
    return u is Map<String, dynamic> ? UserModel.fromJson(u) : null;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.authLogout);
    } catch (_) {
      // Abaikan: sesi lokal tetap dihapus.
    }
  }

  Future<AuthResult> loginWithGoogle({required String credential}) async {
    try {
      final data = await _api.post(ApiConfig.authGoogle, {'credential': credential}, false);
      final Map j = data is Map ? data : const {};
      if (j['needsProfile'] == true && asStr(j['profileToken']).isNotEmpty) {
        final Map p = j['profile'] is Map ? j['profile'] : const {};
        return AuthResult(
          success: false,
          message: 'Lengkapi profil untuk melanjutkan',
          pendingProfile: GoogleProfilePending(
            profileToken: asStr(j['profileToken']),
            email: asStr(p['email']),
            name: asStr(p['name']),
            avatarUrl: asStrOrNull(p['avatarUrl']),
            suggestedUsername: asStr(j['suggestedUsername']),
          ),
        );
      }
      return _session(data, 'Login Google berhasil', isGoogle: true);
    } catch (e) {
      return AuthResult(success: false, message: apiErrorMessage(e, 'Login Google gagal, coba lagi.'));
    }
  }

  Future<AuthResult> completeGoogleProfile({
    required String profileToken,
    required String username,
    String phone = '',
  }) async {
    try {
      final data = await _api.post(
        ApiConfig.authGoogleComplete,
        {'profileToken': profileToken, 'username': username, 'phone': phone},
        false,
      );
      return _session(data, 'Pendaftaran berhasil', isGoogle: true);
    } catch (e) {
      return AuthResult(success: false, message: apiErrorMessage(e, 'Pendaftaran gagal, coba lagi.'));
    }
  }
}
