import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/phone.dart';
import '../controllers/auth_controller.dart';
import '../../../widgets/ui.dart';
import 'turnstile_field.dart';

final usernameRe = RegExp(r'^[a-z0-9_]{3,30}$');
final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

const usernameRuleText = 'Username harus 3–30 karakter, hanya huruf kecil, angka, atau garis bawah (_)';

/// Validasi ringan di sisi klien (validasi utama tetap di server) — sama dengan Register.js di web.
String validateRegister({
  required String name,
  required String username,
  required String email,
  required String phone,
  required String password,
}) {
  if (name.trim().isEmpty) return 'Nama wajib diisi';
  if (name.trim().length > 100) return 'Nama maksimal 100 karakter';
  if (!usernameRe.hasMatch(username.trim().toLowerCase())) return usernameRuleText;
  if (!_emailRe.hasMatch(email.trim()) || email.trim().length > 254) return 'Format email tidak valid';
  final pe = phoneError(phone);
  if (pe.isNotEmpty) return pe;
  if (password.length < 8 || password.length > 128) return 'Password harus 8–128 karakter';
  return '';
}

/// Halaman Daftar. Hasil Get.to: true = akun dibuat dan langsung masuk.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final auth = Get.find<AuthController>();
  final nameCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final turnstile = TurnstileController();
  String? turnstileToken;
  String error = '';
  bool hidePass = true;

  @override
  void dispose() {
    for (final c in [nameCtrl, usernameCtrl, emailCtrl, phoneCtrl, passCtrl]) {
      c.dispose();
    }
    turnstile.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final msg = validateRegister(
      name: nameCtrl.text,
      username: usernameCtrl.text,
      email: emailCtrl.text,
      phone: phoneCtrl.text,
      password: passCtrl.text,
    );
    if (msg.isNotEmpty) return setState(() => error = msg);
    if (turnstileToken == null) return setState(() => error = 'Harap selesaikan verifikasi keamanan');

    setState(() => error = '');
    final ok = await auth.register(
      name: nameCtrl.text.trim(),
      username: usernameCtrl.text.trim().toLowerCase(),
      email: emailCtrl.text.trim(),
      phone: normalizePhone(phoneCtrl.text).phone,
      password: passCtrl.text,
      turnstileToken: turnstileToken!,
    );
    if (!mounted) return;
    if (ok) {
      Get.back(result: true);
      return;
    }
    setState(() {
      error = auth.errorMessage.value ?? '';
      turnstileToken = null;
    });
    auth.errorMessage.value = null;
    turnstile.refreshToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: purpleAppBar('Daftar'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SectionCard(
            children: [
              if (error.isNotEmpty) Notice.text(error, kind: NoticeKind.error),
              LabeledField(
                label: 'Nama Lengkap',
                child: TextField(
                  controller: nameCtrl,
                  maxLength: 100,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  decoration: inputDeco(),
                ),
              ),
              LabeledField(
                label: 'Username',
                hint: '3–30 karakter: huruf kecil, angka, atau garis bawah (_).',
                child: TextField(
                  controller: usernameCtrl,
                  maxLength: 30,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.newUsername],
                  inputFormatters: [LowerCaseFormatter()],
                  decoration: inputDeco(),
                ),
              ),
              LabeledField(
                label: 'Email',
                child: TextField(
                  controller: emailCtrl,
                  maxLength: 254,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: inputDeco(),
                ),
              ),
              LabeledField(
                label: 'No. Telepon/WhatsApp',
                optional: true,
                hint: 'Format: 08xx, 628xx, atau +628xx. Boleh dikosongkan.',
                child: TextField(
                  controller: phoneCtrl,
                  maxLength: 32,
                  keyboardType: TextInputType.phone,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: inputDeco(hint: '08123456789'),
                ),
              ),
              LabeledField(
                label: 'Password',
                hint: 'Minimal 8 karakter.',
                child: TextField(
                  controller: passCtrl,
                  maxLength: 128,
                  obscureText: hidePass,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: inputDeco().copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(hidePass ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setState(() => hidePass = !hidePass),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              TurnstileField(
                controller: turnstile,
                onToken: (t) => setState(() => turnstileToken = t),
                unavailableText: 'Verifikasi keamanan belum dikonfigurasi. Pendaftaran sementara tidak tersedia.',
              ),
              const SizedBox(height: 16),
              Obx(() => PrimaryButton(
                    label: auth.isLoading.value ? 'Sedang mendaftar...' : 'Daftar',
                    onPressed: auth.isLoading.value || !turnstileConfigured ? null : _submit,
                  )),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun?', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Login di sini', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
