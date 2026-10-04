import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/phone.dart';
import '../../../widgets/ui.dart';
import '../controllers/auth_controller.dart';
import 'register_view.dart';

/// Layar "Lengkapi profil" setelah login Google pertama kali (sama dengan CompleteProfile.js di web).
/// Hasil Get.to: true = akun dibuat dan langsung masuk.
class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final auth = Get.find<AuthController>();
  late final TextEditingController usernameCtrl =
      TextEditingController(text: auth.pendingGoogleProfile?.suggestedUsername ?? '');
  final phoneCtrl = TextEditingController();
  String error = '';

  @override
  void dispose() {
    usernameCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final u = usernameCtrl.text.trim().toLowerCase();
    if (!usernameRe.hasMatch(u)) return setState(() => error = usernameRuleText);
    final pe = phoneError(phoneCtrl.text);
    if (pe.isNotEmpty) return setState(() => error = pe);

    setState(() => error = '');
    final err = await auth.completeGoogleProfile(username: u, phone: normalizePhone(phoneCtrl.text).phone);
    if (!mounted) return;
    if (err == null) {
      Get.back(result: true);
    } else {
      setState(() => error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = auth.pendingGoogleProfile;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: purpleAppBar('Lengkapi profil'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: profile == null
              ? SectionCard(children: [
                  const Text('Sesi pengisian profil tidak ditemukan atau sudah berakhir.'),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Kembali', onPressed: () => Get.back()),
                ])
              : SectionCard(
                  children: [
                    const Text(
                      'Satu langkah lagi untuk membuat akun Mihan Store.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.purple100,
                            backgroundImage: profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.name.isEmpty ? '(tanpa nama)' : profile.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  profile.email,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (error.isNotEmpty) Notice.text(error, kind: NoticeKind.error),
                    LabeledField(
                      label: 'Username',
                      hint: '3–30 karakter: huruf kecil, angka, atau garis bawah (_).',
                      child: TextField(
                        controller: usernameCtrl,
                        maxLength: 30,
                        autocorrect: false,
                        enableSuggestions: false,
                        inputFormatters: [LowerCaseFormatter()],
                        decoration: inputDeco(),
                      ),
                    ),
                    LabeledField(
                      label: 'No. Telepon/WhatsApp',
                      optional: true,
                      child: TextField(
                        controller: phoneCtrl,
                        maxLength: 32,
                        keyboardType: TextInputType.phone,
                        decoration: inputDeco(hint: '08123456789'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Obx(() => PrimaryButton(
                          label: auth.isLoading.value ? 'Menyimpan...' : 'Simpan dan lanjutkan',
                          onPressed: auth.isLoading.value ? null : _submit,
                        )),
                    const SizedBox(height: 10),
                    const Text(
                      'Dengan melanjutkan, Anda menyetujui Syarat & Ketentuan dan Kebijakan Privasi Mihan Store.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
