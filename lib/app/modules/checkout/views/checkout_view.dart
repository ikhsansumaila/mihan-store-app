import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/models/cart_model.dart';
import '../../../data/models/order_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/shop_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/phone.dart';
import '../../../utils/shop_format.dart';
import '../../../widgets/ui.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../catalog/controllers/cart_controller.dart';
import '../../catalog/widgets/cart_bottom_sheet.dart';
import '../../orders/views/order_detail_view.dart';
import 'region_picker_field.dart';

class RegionLevel {
  final String key;
  final String field;
  final String label;
  final String lower;
  const RegionLevel(this.key, this.field, this.label, this.lower);
}

const regionLevels = [
  RegionLevel('province', 'provinceCode', 'Provinsi', 'provinsi'),
  RegionLevel('regency', 'regencyCode', 'Kabupaten/Kota', 'kabupaten/kota'),
  RegionLevel('district', 'districtCode', 'Kecamatan', 'kecamatan'),
  RegionLevel('village', 'villageCode', 'Kelurahan/Desa', 'kelurahan/desa'),
];

class CheckoutForm {
  String recipientName = '';
  String recipientPhone = '';
  String address = '';
  String postalCode = '';
  String note = '';
}

/// Validasi klien (server tetap memvalidasi ulang). Semua wajib kecuali catatan — sama dengan
/// validateCheckoutForm di Checkout.js (mihan-store-web).
Map<String, String> validateCheckoutForm(CheckoutForm form, List<RegionRef?> region) {
  final e = <String, String>{};
  final name = form.recipientName.trim();
  if (name.isEmpty) {
    e['recipientName'] = 'Nama penerima wajib diisi.';
  } else if (name.length > 100) {
    e['recipientName'] = 'Nama penerima maksimal 100 karakter.';
  }
  final phone = normalizePhone(form.recipientPhone);
  if (phone.error.isNotEmpty) {
    e['recipientPhone'] = phone.error;
  } else if (phone.phone.isEmpty) {
    e['recipientPhone'] = 'Nomor telepon wajib diisi.';
  }
  for (var i = 0; i < regionLevels.length; i++) {
    if (region[i] == null) e[regionLevels[i].field] = 'Pilih ${regionLevels[i].lower}.';
  }
  if (form.address.trim().length < 5) {
    e['address'] = 'Alamat lengkap wajib diisi (min. 5 karakter): jalan, RT/RW, nomor rumah.';
  }
  final pc = form.postalCode.trim();
  if (pc.isEmpty) {
    e['postalCode'] = 'Kode pos wajib diisi.';
  } else if (!RegExp(r'^[0-9]{5}$').hasMatch(pc)) {
    e['postalCode'] = 'Kode pos harus 5 digit angka.';
  }
  if (form.note.trim().length > 500) e['note'] = 'Catatan maksimal 500 karakter.';
  return e;
}

const _fieldOrder = [
  'recipientName',
  'recipientPhone',
  'provinceCode',
  'regencyCode',
  'districtCode',
  'villageCode',
  'address',
  'postalCode',
  'note',
];

class _RegionList {
  List<RegionRef> items = const [];
  bool loading = false;
  String error = '';
  int seq = 0; // abaikan respons lama bila induk sudah berganti
}

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final shop = ShopService();
  final cart = Get.find<CartController>();
  final auth = Get.find<AuthController>();
  final form = CheckoutForm();

  late final nameCtrl = TextEditingController();
  // Nama penerima SENGAJA kosong (penerima bisa berbeda dari pemilik akun); telepon boleh diisi dari akun.
  late final phoneCtrl = TextEditingController(text: auth.currentUser.value?.phone ?? '');
  final addressCtrl = TextEditingController();
  final postalCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final focus = {for (final k in ['recipientName', 'recipientPhone', 'address', 'postalCode', 'note']) k: FocusNode()};
  final scroll = ScrollController();

  final region = List<RegionRef?>.filled(4, null);
  final lists = List.generate(4, (_) => _RegionList());

  Map<String, String> errors = {};
  String error = '';
  bool submitting = false;
  bool loadingCart = true;
  // Server menjawab 409 price_changed: keranjang terkini ditampilkan, pelanggan harus konfirmasi ulang.
  bool priceChanged = false;
  // Satu kunci per percobaan checkout: ketuk ganda / kirim ulang -> pesanan yang sama.
  final idemKey = newIdempotencyKey();

  @override
  void initState() {
    super.initState();
    cart.refreshCart().whenComplete(() {
      if (mounted) setState(() => loadingCart = false);
    });
    _loadLevel(0);
  }

  @override
  void dispose() {
    for (final c in [nameCtrl, phoneCtrl, addressCtrl, postalCtrl, noteCtrl]) {
      c.dispose();
    }
    for (final f in focus.values) {
      f.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  Future<void> _loadLevel(int level) async {
    final parent = level == 0 ? null : region[level - 1]?.code;
    final l = lists[level];
    final seq = ++l.seq;
    if (level > 0 && parent == null) {
      setState(() {
        l.items = const [];
        l.loading = false;
        l.error = '';
      });
      return;
    }
    setState(() {
      l.items = const [];
      l.loading = true;
      l.error = '';
    });
    try {
      final items = await shop.loadRegions(level, parent);
      if (!mounted || seq != l.seq) return;
      setState(() {
        l.items = items;
        l.loading = false;
      });
    } catch (err) {
      if (!mounted || seq != l.seq) return;
      setState(() {
        l.loading = false;
        l.error = ShopService.regionErrorMessage(err, regionLevels[level].lower);
      });
    }
  }

  // Memilih tingkat atas mengosongkan semua tingkat di bawahnya.
  void _pickRegion(int level, RegionRef item) {
    if (region[level]?.code == item.code) return;
    setState(() {
      region[level] = item;
      for (var i = level + 1; i < 4; i++) {
        region[i] = null;
        lists[i].items = const [];
        lists[i].error = '';
      }
      errors.remove(regionLevels[level].field);
    });
    if (level < 3) _loadLevel(level + 1);
  }

  void _clearErr(String k) {
    if (errors.containsKey(k)) setState(() => errors.remove(k));
  }

  void _focusFirst(Map<String, String> errs) {
    final k = _fieldOrder.firstWhereOrNull(errs.containsKey);
    final f = k == null ? null : focus[k];
    if (f != null) {
      f.requestFocus();
    } else if (scroll.hasClients) {
      scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _syncForm() {
    form
      ..recipientName = nameCtrl.text
      ..recipientPhone = phoneCtrl.text
      ..address = addressCtrl.text
      ..postalCode = postalCtrl.text
      ..note = noteCtrl.text;
  }

  Future<void> _submit() async {
    if (submitting) return;
    FocusScope.of(context).unfocus();
    _syncForm();
    final errs = validateCheckoutForm(form, region);
    if (errs.isNotEmpty) {
      setState(() {
        errors = errs;
        error = 'Lengkapi data yang ditandai merah.';
      });
      _focusFirst(errs);
      return;
    }
    setState(() {
      errors = {};
      error = '';
      submitting = true;
    });

    try {
      // Konfirmasi ulang setelah "Harga berubah": harga terbaru dianggap sudah dilihat, total terbaru dikirim.
      CartModel? shown = cart.cart.value;
      if (priceChanged) {
        await cart.ackPrices();
        shown = cart.cart.value;
      }
      // Hanya data penerima + kunci idempotensi + total yang DITAMPILKAN; item & harga dihitung server.
      final orderNo = await shop.createOrder(CheckoutInput(
        recipientName: form.recipientName.trim(),
        recipientPhone: normalizePhone(form.recipientPhone).phone,
        provinceCode: region[0]!.code,
        regencyCode: region[1]!.code,
        districtCode: region[2]!.code,
        villageCode: region[3]!.code,
        address: form.address.trim(),
        postalCode: form.postalCode.trim(),
        note: form.note.trim(),
        idempotencyKey: idemKey,
        expectedTotal: shown?.subtotal ?? 0,
      ));
      cart.refreshCart();
      Get.off(() => OrderDetailView(orderNo: orderNo, isNew: true));
    } on ApiException catch (err) {
      if (err.isUnauthorized) {
        auth.handleUnauthorized();
        Get.back();
        return;
      }
      setState(() => submitting = false);
      final data = err.data;
      if (err.status == 409 && err.error == 'price_changed') {
        final c = data is Map ? CartModel.tryParse(data['cart']) : null;
        if (c != null) {
          cart.setCart(c);
        } else {
          cart.refreshCart();
        }
        setState(() {
          priceChanged = true;
          error = '';
        });
        if (scroll.hasClients) scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        return;
      }
      final field = data is Map ? data['field'] : null;
      if (err.status == 422 && field is String && _fieldOrder.contains(field)) {
        final errs = {field: err.error ?? 'Periksa kembali isian ini.'};
        setState(() {
          errors = errs;
          error = 'Periksa kembali data yang ditandai merah.';
        });
        _focusFirst(errs);
        return;
      }
      setState(() => error = apiErrorMessage(err, 'Gagal membuat pesanan, coba lagi.'));
      if (err.status == 409 || err.status == 400) cart.refreshCart();
    } catch (err) {
      setState(() {
        submitting = false;
        error = apiErrorMessage(err, 'Gagal membuat pesanan, coba lagi.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: purpleAppBar('Checkout'),
      body: SafeArea(
        child: Obx(() {
          final c = cart.cart.value;
          if (c == null && (loadingCart || cart.isLoading.value)) {
            return const Center(child: CircularProgressIndicator());
          }
          if (c == null || c.itemCount == 0) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Notice.text('Keranjang Anda kosong.'),
                PrimaryButton(label: 'Kembali belanja', onPressed: () => Get.back()),
              ]),
            );
          }
          return ListView(
            controller: scroll,
            padding: const EdgeInsets.all(16),
            children: [
              if (priceChanged)
                Notice(
                  kind: NoticeKind.warn,
                  child: Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Harga berubah. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Total terbaru '),
                    TextSpan(text: rupiah(c.subtotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '. Periksa ringkasan pesanan, lalu tekan '),
                    const TextSpan(
                      text: 'Konfirmasi & buat pesanan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' untuk melanjutkan dengan harga terbaru.'),
                  ])),
                )
              else
                PriceChangeBanner(cart: cart),
              if (c.hasUnavailable)
                Notice(
                  kind: NoticeKind.warn,
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Ada produk yang tidak tersedia di keranjang. '),
                      InkWell(
                        onTap: () {
                          Get.back();
                          CartBottomSheet.show(Get.context!);
                        },
                        child: const Text(
                          'Perbarui keranjang',
                          style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Text(' dulu.'),
                    ],
                  ),
                ),
              _buildForm(c),
              const SizedBox(height: 16),
              _buildSummary(c),
              const SizedBox(height: 24),
            ],
          );
        }),
      ),
    );
  }

  Widget _text(
    String key,
    TextEditingController ctrl, {
    int maxLength = 100,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    Iterable<String>? autofill,
    TextCapitalization caps = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      focusNode: focus[key],
      maxLength: maxLength,
      maxLines: maxLines,
      minLines: 1,
      keyboardType: keyboard,
      inputFormatters: formatters,
      autofillHints: autofill,
      textCapitalization: caps,
      decoration: inputDeco(hint: hint, invalid: errors.containsKey(key)),
      onChanged: (_) => _clearErr(key),
    );
  }

  Widget _buildForm(CartModel c) {
    return SectionCard(
      title: 'Data penerima',
      children: [
        if (error.isNotEmpty) Notice.text(error, kind: NoticeKind.error),
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Semua kolom bertanda '),
              TextSpan(text: '*', style: TextStyle(color: AppColors.errorRed)),
              TextSpan(text: ' wajib diisi.'),
            ]),
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ),
        LabeledField(
          label: 'Nama penerima',
          required: true,
          error: errors['recipientName'],
          child: _text(
            'recipientName',
            nameCtrl,
            hint: 'Nama lengkap penerima paket',
            autofill: const [AutofillHints.name],
            caps: TextCapitalization.words,
          ),
        ),
        LabeledField(
          label: 'Nomor telepon/WhatsApp',
          hint: '08xx / +628xx',
          required: true,
          error: errors['recipientPhone'],
          child: _text(
            'recipientPhone',
            phoneCtrl,
            maxLength: 32,
            keyboard: TextInputType.phone,
            autofill: const [AutofillHints.telephoneNumber],
          ),
        ),
        for (var i = 0; i < regionLevels.length; i++)
          RegionPickerField(
            label: regionLevels[i].label,
            lower: regionLevels[i].lower,
            value: region[i],
            items: lists[i].items,
            loading: lists[i].loading,
            loadError: lists[i].error,
            onRetry: () => _loadLevel(i),
            onChanged: (it) => _pickRegion(i, it),
            disabled: i > 0 && region[i - 1] == null,
            disabledHint: i > 0 ? 'Pilih ${regionLevels[i - 1].lower} dulu' : '',
            errorText: errors[regionLevels[i].field],
          ),
        LabeledField(
          label: 'Alamat lengkap',
          hint: 'Jalan, RT/RW, nomor rumah',
          required: true,
          error: errors['address'],
          child: _text(
            'address',
            addressCtrl,
            maxLength: 500,
            maxLines: 3,
            hint: 'Contoh: Jl. Melati No. 9, RT 03/RW 05',
            autofill: const [AutofillHints.fullStreetAddress],
          ),
        ),
        LabeledField(
          label: 'Kode pos',
          hint: '5 digit',
          required: true,
          error: errors['postalCode'],
          child: SizedBox(
            width: 160,
            child: _text(
              'postalCode',
              postalCtrl,
              maxLength: 5,
              keyboard: TextInputType.number,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              autofill: const [AutofillHints.postalCode],
            ),
          ),
        ),
        LabeledField(
          label: 'Catatan',
          optional: true,
          error: errors['note'],
          child: _text('note', noteCtrl, maxLength: 500, maxLines: 2),
        ),
        const Text(
          'Pembayaran dengan transfer bank manual. Ongkir ditetapkan admin setelah pesanan dibuat; total akhir '
          'terlihat di halaman pesanan. Data penerima dipakai untuk pengiriman sesuai Kebijakan Privasi.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textLight),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: submitting
              ? 'Membuat pesanan...'
              : priceChanged
                  ? 'Konfirmasi & buat pesanan'
                  : 'Buat pesanan',
          onPressed: submitting || c.hasUnavailable ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildSummary(CartModel c) {
    final items = c.items.where((i) => i.available).toList();
    const muted = TextStyle(fontSize: 12, color: AppColors.textLight);
    return SectionCard(
      title: 'Ringkasan',
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: it.name),
                        TextSpan(text: ' x${it.qty}', style: const TextStyle(color: AppColors.textLight)),
                      ])),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: perUnit(it.unitPrice, it.unit)),
                          if (it.tierMinQty != null)
                            TextSpan(
                              text: ' · ${tierNote(it.tierMinQty)}',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700),
                            ),
                        ]),
                        style: muted,
                      ),
                      if (it.priceChanged)
                        Text(
                          'Harga berubah dari ${rupiah(it.previousUnitPrice)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown.shade700),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(rupiah(it.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const Divider(),
        _row('Subtotal', rupiah(c.subtotal)),
        _row('Ongkir', 'ditetapkan admin', style: muted),
        const SizedBox(height: 4),
        _row(
          'Total sementara',
          rupiah(c.subtotal),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
        ),
      ],
    );
  }

  Widget _row(String a, String b, {TextStyle? style}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(a, style: style), Text(b, style: style)],
        ),
      );
}
