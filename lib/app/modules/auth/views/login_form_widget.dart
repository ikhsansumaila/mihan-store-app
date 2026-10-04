import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import 'complete_profile_view.dart';
import 'register_view.dart';
import 'turnstile_field.dart';

class LoginFormWidget extends StatefulWidget {
  final AuthController auth;

  const LoginFormWidget({super.key, required this.auth});

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TurnstileController turnstile = TurnstileController();
  String? turnstileToken;
  bool hidePass = true;

  @override
  void dispose() {
    userCtrl.dispose();
    passCtrl.dispose();
    turnstile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Masuk Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.auth.errorMessage.value != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    widget.auth.errorMessage.value!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              _buildGoogleButton(context),
              const SizedBox(height: 14),
              _buildDivider(),
              const SizedBox(height: 12),
              _buildInputs(),
              const SizedBox(height: 12),
              TurnstileField(
                controller: turnstile,
                onToken: (t) => setState(() => turnstileToken = t),
                unavailableText: 'Verifikasi keamanan belum dikonfigurasi. Login dengan password sementara '
                    'tidak tersedia, gunakan Masuk dengan Google.',
              ),
              const SizedBox(height: 12),
              _buildSubmitButton(context),
              const SizedBox(height: 8),
              _buildRegisterLink(context),
            ],
          ),
        ));
  }

  Widget _buildGoogleButton(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.auth.isLoading.value
          ? null
          : () async {
              final nav = Navigator.of(context);
              final outcome = await widget.auth.signInWithGoogle();
              if (!mounted) return;
              if (outcome == AuthOutcome.success) {
                nav.pop(true);
              } else if (outcome == AuthOutcome.needsProfile) {
                final ok = await Get.to<bool>(() => const CompleteProfileView());
                if (ok == true && mounted) nav.pop(true);
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(image: AssetImage('assets/google-icon.png'), width: 22, height: 22),
          SizedBox(width: 8),
          Text('Masuk dengan Google', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('atau password', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }

  Widget _buildInputs() {
    return Column(
      children: [
        TextField(
          controller: userCtrl,
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
          decoration: const InputDecoration(
            labelText: 'Email atau Username',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passCtrl,
          obscureText: hidePass,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(hidePass ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => hidePass = !hidePass),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final disabled = widget.auth.isLoading.value || !turnstileConfigured;
    return ElevatedButton(
      onPressed: disabled
          ? null
          : () async {
              final nav = Navigator.of(context);
              final ok = await widget.auth.login(userCtrl.text, passCtrl.text, turnstileToken);
              if (!mounted) return;
              if (ok) {
                nav.pop(true);
              } else if (turnstileToken != null) {
                // Token Turnstile hanya sekali pakai: minta yang baru untuk percobaan berikutnya.
                setState(() => turnstileToken = null);
                turnstile.refreshToken();
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: widget.auth.isLoading.value
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text('Masuk'),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Belum punya akun?', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        TextButton(
          onPressed: () async {
            final nav = Navigator.of(context);
            widget.auth.errorMessage.value = null;
            final ok = await Get.to<bool>(() => const RegisterView());
            if (ok == true && mounted) nav.pop(true);
          },
          child: const Text('Daftar di sini', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

