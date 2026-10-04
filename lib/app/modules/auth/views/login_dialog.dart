import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'login_form_widget.dart';
import 'user_profile_widget.dart';

class LoginDialog extends StatelessWidget {
  const LoginDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LoginDialog(),
    );
  }

  /// Pastikan pengguna sudah masuk (mis. sebelum menambah ke keranjang, seperti web yang
  /// mengarahkan ke /login). true = sudah/berhasil masuk (password, Google, atau daftar baru).
  static Future<bool> requireLogin(BuildContext context) async {
    final auth = Get.find<AuthController>();
    if (auth.isLoggedIn) return true;
    await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const LoginDialog(),
    );
    return auth.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Obx(() => auth.isLoggedIn
              ? UserProfileWidget(auth: auth)
              : LoginFormWidget(auth: auth)),
        ),
      ),
    );
  }
}
