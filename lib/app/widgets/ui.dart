import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

// Komponen UI bersama untuk halaman akun, keranjang, checkout, dan pesanan.

PreferredSizeWidget purpleAppBar(String title, {List<Widget>? actions}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.purpleGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: actions,
      ),
    ),
  );
}

/// Kartu putih berisi kolom-kolom.
class SectionCard extends StatelessWidget {
  final List<Widget> children;
  final String? title;

  const SectionCard({super.key, required this.children, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }
}

enum NoticeKind { info, warn, error, success }

/// Kotak pemberitahuan (sama dengan komponen Notice di web).
class Notice extends StatelessWidget {
  final NoticeKind kind;
  final Widget child;

  const Notice({super.key, this.kind = NoticeKind.info, required this.child});

  Notice.text(String text, {super.key, this.kind = NoticeKind.info}) : child = Text(text);

  @override
  Widget build(BuildContext context) {
    final (MaterialColor c, Color fg) = switch (kind) {
      NoticeKind.info => (Colors.blue, Colors.blue.shade900),
      NoticeKind.warn => (Colors.amber, Colors.brown.shade900),
      NoticeKind.error => (Colors.red, Colors.red.shade800),
      NoticeKind.success => (Colors.green, Colors.green.shade900),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.shade200),
      ),
      child: DefaultTextStyle.merge(style: TextStyle(fontSize: 13, color: fg, height: 1.35), child: child),
    );
  }
}

class LabeledField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool required;
  final bool optional;
  final String? error;
  final Widget child;

  const LabeledField({
    super.key,
    required this.label,
    this.hint,
    this.required = false,
    this.optional = false,
    this.error,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              children: [
                if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.errorRed)),
                if (optional)
                  const TextSpan(
                    text: ' (opsional)',
                    style: TextStyle(fontWeight: FontWeight.normal, color: AppColors.textLight),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (error != null && error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.errorRed)),
            )
          else if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(hint!, style: const TextStyle(fontSize: 11.5, color: AppColors.textLight)),
            ),
        ],
      ),
    );
  }
}

InputDecoration inputDeco({String? hint, bool invalid = false}) {
  OutlineInputBorder border(Color c, [double w = 1.5]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: hint,
    isDense: true,
    counterText: '',
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    enabledBorder: border(invalid ? AppColors.errorRed : AppColors.borderInput),
    focusedBorder: border(invalid ? AppColors.errorRed : AppColors.primaryPurple, 2),
    disabledBorder: border(AppColors.border),
    border: border(AppColors.borderInput),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const PrimaryButton({super.key, required this.label, this.onPressed, this.color = AppColors.primaryPurple});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Lencana status pesanan.
class StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const StatusBadge({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final MaterialColor c = switch (status) {
      'pending_payment' => Colors.amber,
      'paid' => Colors.blue,
      'completed' => Colors.green,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.shade300),
      ),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: c.shade900)),
    );
  }
}
