import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../data/config/api_config.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/auth_service.dart';

enum AuthOutcome { success, needsProfile, failed }

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? ApiConfig.googleClientId : null,
    serverClientId: ApiConfig.googleClientId,
    scopes: ['email', 'profile'],
  );

  final Rxn<UserModel> currentUser = Rxn<UserModel>();
  // Token sesi hanya disimpan di memori (tidak pernah ditulis ke disk).
  final RxnString authToken = RxnString();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  /// Diisi saat login Google pertama kali: akun belum ada, profil harus dilengkapi.
  GoogleProfilePending? pendingGoogleProfile;

  bool get isLoggedIn => currentUser.value != null && (authToken.value?.isNotEmpty ?? false);
  bool get isAdmin => currentUser.value?.canAccessAdmin ?? false;
  bool get isGoogleUser => currentUser.value?.isGoogle ?? false;

  String get displayName => currentUser.value?.name ?? 'Pengguna';

  String get shortName {
    final name = currentUser.value?.name;
    if (name == null || name.trim().isEmpty) return 'User';
    return name.trim().split(' ').first;
  }

  String get userRole => currentUser.value?.role ?? 'Tamu';

  @override
  void onInit() {
    super.onInit();
    ApiClient.tokenProvider = () => authToken.value;
  }

  void _startSession(AuthResult result, String title, String message) {
    currentUser.value = result.user;
    authToken.value = result.token;
    errorMessage.value = null;
    pendingGoogleProfile = null;
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  Future<bool> login(String identifier, String password, String? turnstileToken) async {
    if (identifier.trim().isEmpty || password.isEmpty) {
      errorMessage.value = 'Email/Username dan Password wajib diisi';
      return false;
    }
    if (turnstileToken == null || turnstileToken.isEmpty) {
      errorMessage.value = 'Harap selesaikan verifikasi keamanan';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;
    final result = await _authService.login(
      identifier: identifier,
      password: password,
      turnstileToken: turnstileToken,
    );
    isLoading.value = false;

    if (result.success && result.user != null && result.token != null) {
      _startSession(result, 'Login Berhasil', 'Selamat datang, ${result.user!.name}!');
      return true;
    }
    errorMessage.value = result.message;
    return false;
  }

  /// Field sudah divalidasi & dinormalkan oleh form pendaftaran.
  /// true = akun dibuat dan langsung masuk.
  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String turnstileToken,
  }) async {
    isLoading.value = true;
    errorMessage.value = null;
    final result = await _authService.register(
      name: name,
      username: username,
      email: email,
      phone: phone,
      password: password,
      turnstileToken: turnstileToken,
    );
    isLoading.value = false;

    if (result.success && result.user != null && result.token != null) {
      _startSession(result, 'Registrasi Berhasil', 'Selamat datang, ${result.user!.name}!');
      return true;
    }
    if (result.success) {
      // Akun dibuat tanpa sesi (server meminta login manual).
      errorMessage.value = null;
      Get.snackbar('Registrasi Berhasil', result.message, snackPosition: SnackPosition.TOP);
      return false;
    }
    errorMessage.value = result.message;
    return false;
  }

  Future<AuthOutcome> signInWithGoogle() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        isLoading.value = false;
        return AuthOutcome.failed;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        errorMessage.value = 'Tidak mendapatkan ID Token Google dari akun yang dipilih';
        isLoading.value = false;
        return AuthOutcome.failed;
      }

      final result = await _authService.loginWithGoogle(credential: idToken);
      isLoading.value = false;

      if (result.pendingProfile != null) {
        pendingGoogleProfile = result.pendingProfile;
        return AuthOutcome.needsProfile;
      }
      if (result.success && result.user != null && result.token != null) {
        _startSession(result, 'Login Google Berhasil', 'Selamat datang, ${result.user!.name}!');
        return AuthOutcome.success;
      }

      errorMessage.value = result.message;
      return AuthOutcome.failed;
    } on PlatformException catch (pe) {
      isLoading.value = false;
      final msg = pe.message ?? pe.code;
      if (pe.code.contains('10') || msg.contains('10')) {
        errorMessage.value = 'Google Sign-In: SHA-1 aplikasi belum didaftarkan di Google Cloud Console.';
      } else {
        errorMessage.value = 'Google Sign-In gagal ($msg)';
      }
      return AuthOutcome.failed;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Gagal login Google: $e';
      return AuthOutcome.failed;
    }
  }

  /// Layar "Lengkapi profil" setelah login Google pertama kali. Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> completeGoogleProfile({required String username, required String phone}) async {
    final pending = pendingGoogleProfile;
    if (pending == null) return 'Sesi pengisian profil tidak ditemukan atau sudah berakhir.';
    isLoading.value = true;
    final result = await _authService.completeGoogleProfile(
      profileToken: pending.profileToken,
      username: username,
      phone: phone,
    );
    isLoading.value = false;
    if (result.success && result.user != null && result.token != null) {
      _startSession(result, 'Pendaftaran Berhasil', 'Selamat datang, ${result.user!.name}!');
      return null;
    }
    return result.success ? 'Pendaftaran gagal, coba lagi.' : result.message;
  }

  void loginGoogleDemo({bool asAdmin = true}) {
    if (!kDebugMode) return;
    currentUser.value = UserModel(
      id: asAdmin ? 'google_admin_01' : 'google_customer_01',
      username: asAdmin ? 'admin_demo' : 'pelanggan_google',
      email: asAdmin ? 'admin.demo@example.com' : 'customer.mihan@gmail.com',
      name: asAdmin ? 'Admin Demo' : 'Pelanggan Google',
      phone: '08123456789',
      role: asAdmin ? 'admin' : 'customer',
      googleLinked: true,
      isGoogleAuth: true,
    );
    authToken.value = asAdmin ? 'demo_google_admin_token_active' : 'demo_google_customer_token_active';
    errorMessage.value = null;
  }

  void loginDemo({String role = 'customer'}) {
    if (!kDebugMode) return;
    currentUser.value = UserModel(
      id: 'demo_001',
      username: 'pelanggan_demo',
      email: 'demo@mihan.web.id',
      name: 'Pelanggan Setia',
      phone: '08123456789',
      role: role,
    );
    authToken.value = 'demo_token_mobile_12345';
    errorMessage.value = null;
  }

  void _clearSession() {
    currentUser.value = null;
    authToken.value = null;
    errorMessage.value = null;
    pendingGoogleProfile = null;
  }

  Future<void> logout() async {
    if (authToken.value != null) await _authService.logout();
    _clearSession();

    Get.snackbar(
      'Logout',
      'Anda telah keluar dari akun',
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
    );
  }

  /// Server menolak token (401): hapus sesi lokal dan minta login ulang.
  void handleUnauthorized() {
    if (!isLoggedIn) return;
    _clearSession();
    Get.snackbar(
      'Sesi berakhir',
      'Silakan masuk lagi untuk melanjutkan.',
      backgroundColor: Colors.orange.shade800,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}
