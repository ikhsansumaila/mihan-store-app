import 'package:cloudflare_turnstile/cloudflare_turnstile.dart';
import 'package:flutter/material.dart';

import '../../../data/config/api_config.dart';

bool get turnstileConfigured => ApiConfig.turnstileSiteKey.isNotEmpty;

/// Verifikasi keamanan Cloudflare Turnstile (wajib untuk login & daftar dengan password,
/// sama dengan web). Token dikirim lewat [onToken]; null = kedaluwarsa/galat.
class TurnstileField extends StatelessWidget {
  final TurnstileController controller;
  final ValueChanged<String?> onToken;
  final String unavailableText;

  const TurnstileField({
    super.key,
    required this.controller,
    required this.onToken,
    this.unavailableText = 'Verifikasi keamanan belum dikonfigurasi. Fitur ini sementara tidak tersedia.',
  });

  @override
  Widget build(BuildContext context) {
    if (!turnstileConfigured) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.yellow.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.yellow.shade300),
        ),
        child: Text(unavailableText, style: TextStyle(fontSize: 12, color: Colors.yellow.shade900)),
      );
    }
    return Center(
      child: CloudflareTurnstile(
        siteKey: ApiConfig.turnstileSiteKey,
        baseUrl: ApiConfig.turnstileBaseUrl,
        controller: controller,
        options: TurnstileOptions(language: 'id', theme: TurnstileTheme.light),
        onTokenReceived: (token) => onToken(token),
        onTokenExpired: () => onToken(null),
        onError: (_) => onToken(null),
      ),
    );
  }
}
