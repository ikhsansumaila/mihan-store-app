// Nomor telepon/WhatsApp: aturan SAMA dengan backend (NormalizePhone di backend/validate.go) dan
// frontend/src/phone.js di mihan-store-web. Menerima 08xx, 628xx, +628xx; spasi, titik, tanda hubung,
// dan kurung diabaikan. Hasil: +628xx dengan 8-15 digit (tanpa '+').

class PhoneErrors {
  static const chars = 'Nomor telepon ada karakter yang tidak valid. Gunakan angka saja (boleh diawali +62).';
  static const prefix = 'Nomor telepon harus diawali 08, 62, atau +62 (nomor HP, mis. 0812...).';
  static const short = 'Nomor telepon terlalu pendek, minimal 8 digit.';
  static const long = 'Nomor telepon terlalu panjang, maksimal 15 digit.';
}

class PhoneResult {
  final String phone;
  final String error;
  const PhoneResult(this.phone, this.error);
}

bool _isSpace(int c) =>
    (c >= 0x09 && c <= 0x0d) ||
    c == 0x20 ||
    c == 0x85 ||
    c == 0xa0 ||
    c == 0x1680 ||
    (c >= 0x2000 && c <= 0x200a) ||
    c == 0x2028 ||
    c == 0x2029 ||
    c == 0x202f ||
    c == 0x205f ||
    c == 0x3000;

bool _isBidiControl(int c) =>
    (c >= 0x202a && c <= 0x202e) || (c >= 0x2066 && c <= 0x2069) || c == 0x200e || c == 0x200f;

// Karakter ASCII pengganti, '' untuk dibuang, atau karakter aslinya.
String _foldChar(int c) {
  if ((c >= 0x2010 && c <= 0x2015) || c == 0x2212 || c == 0xfe58 || c == 0xfe63 || c == 0xff0d) return '-';
  if (_isSpace(c)) return ' ';
  if (c >= 0xff10 && c <= 0xff19) return '${c - 0xff10}';
  if (c >= 0x0660 && c <= 0x0669) return '${c - 0x0660}';
  if (c >= 0x06f0 && c <= 0x06f9) return '${c - 0x06f0}';
  if (c == 0xff0b) return '+';
  if (c == 0xff08) return '(';
  if (c == 0xff09) return ')';
  if (c == 0xff0e) return '.';
  if ((c >= 0x200b && c <= 0x200f) || (c >= 0x2060 && c <= 0x2064) || c == 0xfeff || _isBidiControl(c)) return '';
  return String.fromCharCode(c);
}

/// Hasil phone '' + error '' = kosong (tidak diisi).
PhoneResult normalizePhone(String? s) {
  final buf = StringBuffer();
  for (final r in (s ?? '').runes) {
    final f = _foldChar(r);
    if (f != ' ' && f != '-' && f != '.' && f != '(' && f != ')') buf.write(f);
  }
  var p = buf.toString();
  if (p.isEmpty) return const PhoneResult('', '');
  if (!RegExp(r'^\+?[0-9]*$').hasMatch(p)) return const PhoneResult('', PhoneErrors.chars);
  if (p.startsWith('+62')) {
    p = p.substring(1);
  } else if (p.startsWith('62')) {
    // tetap
  } else if (p.startsWith('0')) {
    p = '62${p.substring(1)}';
  } else {
    return const PhoneResult('', PhoneErrors.prefix);
  }
  if (p.startsWith('620')) p = '62${p.substring(3)}'; // "+62 0812..." -> "62812..."
  if (!p.startsWith('628')) return const PhoneResult('', PhoneErrors.prefix);
  if (p.length < 8) return const PhoneResult('', PhoneErrors.short);
  if (p.length > 15) return const PhoneResult('', PhoneErrors.long);
  return PhoneResult('+$p', '');
}

/// Pesan galat untuk nomor yang diisi ('' bila valid atau kosong).
String phoneError(String? s) => normalizePhone(s).error;
