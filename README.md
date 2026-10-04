# mihan_store

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Konfigurasi Environment (envied)

1. `cp .env.example .env` lalu isi nilainya (`.env` tidak di-commit).
2. Generate: `dart run build_runner build --force-jit --delete-conflicting-outputs`
3. `env.g.dart` berisi nilai yang di-obfuscate dan tidak di-commit; jalankan ulang setiap `.env` berubah.

Rilis: `flutter build apk --release --obfuscate --split-debug-info=build/symbols`
