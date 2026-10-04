import 'dart:math';

import 'package:intl/intl.dart';

import 'currency_format.dart';

// Utilitas tampilan toko (sama dengan frontend/src/shop/format.js di mihan-store-web).

String rupiah(num? n) => CurrencyFormat.convertToIdr(n ?? 0);

/// "Rp 42.000 / pak" (tanpa satuan: "Rp 42.000").
String perUnit(num? price, String? unit) =>
    (unit != null && unit.isNotEmpty) ? '${rupiah(price)} / $unit' : rupiah(price);

/// Catatan harga grosir untuk item pesanan/keranjang yang memakai jenjang.
String tierNote(int? minQty) => minQty != null && minQty > 0 ? 'harga grosir (min. $minQty)' : '';

const orderStatusLabels = {
  'pending_payment': 'Menunggu pembayaran',
  'paid': 'Dibayar',
  'completed': 'Selesai',
  'cancelled': 'Dibatalkan',
};

String statusLabel(String? s) => orderStatusLabels[s] ?? ((s == null || s.isEmpty) ? '-' : s);

String fmtDateTime(DateTime? d) {
  if (d == null) return '-';
  // Waktu toko: WIB (UTC+7).
  final wib = d.toUtc().add(const Duration(hours: 7));
  return '${DateFormat('d MMM yyyy HH.mm', 'id').format(wib)} WIB';
}

/// Nomor untuk wa.me: hanya digit, format internasional 62xxxx. '' bila tidak valid.
String waNumber(String? phone) {
  if (phone == null || phone.isEmpty) return '';
  var d = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) d = '62${d.substring(1)}';
  if (!RegExp(r'^628[0-9]{6,13}$').hasMatch(d)) return '';
  return d;
}

String waLink(String? phone, String text) {
  final n = waNumber(phone);
  if (n.isEmpty) return '';
  return 'https://wa.me/$n?text=${Uri.encodeComponent(text)}';
}

/// UUID v4 untuk idempotencyKey checkout.
String newIdempotencyKey() {
  final rnd = Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
