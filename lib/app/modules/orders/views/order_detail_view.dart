import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/order_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/shop_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/shop_format.dart';
import '../../../widgets/ui.dart';
import '../../auth/controllers/auth_controller.dart';
import 'my_orders_view.dart';

/// Teks konfirmasi pelanggan -> toko (sama dengan buildCustomerConfirmText di web).
/// Nama = nama PENERIMA di pesanan; nama akun hanya cadangan bila penerima kosong.
String buildCustomerConfirmText(OrderModel order, String? accountName) {
  final r = order.recipient.name.trim();
  final a = (accountName ?? '').trim();
  final name = r.isNotEmpty ? r : (a.isNotEmpty ? a : '-');
  final lines = <String>[
    'Halo Mihan Store, saya ingin konfirmasi pesanan:',
    '',
    'No. pesanan: ${order.orderNo}',
    'Nama: $name',
    '',
    'Item:',
  ];
  for (final it in order.items) {
    final qty = it.unit != null ? '${it.qty} ${it.unit}' : '${it.qty}';
    lines.add('- ${it.name} x$qty = ${rupiah(it.lineTotal)}${it.tierMinQty != null ? ' (harga grosir)' : ''}');
  }
  lines.add('');
  if (order.discount > 0) lines.add('Diskon: -${rupiah(order.discount)}');
  if (order.shippingFee > 0) lines.add('Ongkir: ${rupiah(order.shippingFee)}');
  lines.add('Total: ${rupiah(order.total)}');
  lines.add('Status: ${statusLabel(order.status)}');
  lines.add('');
  if (order.orderNo.isNotEmpty) {
    lines.add('Buka di admin: https://store.mihan.web.id/admin/orders/${Uri.encodeComponent(order.orderNo)}');
    lines.add('');
  }
  lines.add('Terima kasih.');
  return lines.join('\n');
}

class OrderDetailView extends StatefulWidget {
  final String orderNo;
  final bool isNew;

  const OrderDetailView({super.key, required this.orderNo, this.isNew = false});

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  final shop = ShopService();
  final auth = Get.find<AuthController>();
  final reasonCtrl = TextEditingController();
  OrderModel? order;
  StoreInfo? info;
  String error = '';
  bool notFound = false;
  bool confirming = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  void _handleErr(Object err, String fallback) {
    if (err is ApiException && err.isUnauthorized) {
      auth.handleUnauthorized();
      Get.back();
      return;
    }
    if (!mounted) return;
    setState(() {
      if (err is ApiException && err.status == 404) {
        notFound = true;
      } else {
        error = apiErrorMessage(err, fallback);
      }
    });
  }

  Future<void> _load() async {
    setState(() => error = '');
    try {
      final o = await shop.getOrder(widget.orderNo);
      if (mounted) setState(() => order = o);
    } catch (err) {
      _handleErr(err, 'Gagal memuat pesanan');
    }
    try {
      final i = await shop.getStoreInfo();
      if (mounted) setState(() => info = i);
    } catch (_) {
      // Info toko opsional.
    }
  }

  Future<void> _cancel() async {
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final o = await shop.cancelOrder(widget.orderNo, reasonCtrl.text.trim());
      if (mounted) {
        setState(() {
          order = o;
          confirming = false;
        });
      }
    } catch (err) {
      _handleErr(err, 'Gagal membatalkan pesanan');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _openWa(String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok) Get.snackbar('Gagal', 'Tidak dapat membuka WhatsApp', snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: purpleAppBar(widget.isNew ? 'Pesanan berhasil' : 'Detail pesanan'),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (notFound) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Notice.text('Pesanan tidak ditemukan.', kind: NoticeKind.error),
          PrimaryButton(label: 'Lihat semua pesanan', onPressed: () => Get.off(() => const MyOrdersView())),
        ]),
      );
    }
    final o = order;
    if (o == null) {
      return error.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Notice.text(error, kind: NoticeKind.error),
                PrimaryButton(label: 'Coba lagi', onPressed: _load),
              ]),
            )
          : const Center(child: CircularProgressIndicator());
    }

    final wa = info?.storeWhatsapp != null
        ? waLink(info!.storeWhatsapp, buildCustomerConfirmText(o, auth.currentUser.value?.name))
        : '';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.isNew)
            Notice(
              kind: NoticeKind.success,
              child: Text.rich(TextSpan(children: [
                const TextSpan(text: 'Pesanan berhasil dibuat! ', style: TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: 'Nomor pesanan Anda '),
                TextSpan(text: o.orderNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(
                  text: '. Silakan transfer sesuai total di bawah, lalu konfirmasi ke toko. Admin akan menambahkan '
                      'ongkir (bila ada) dan memperbarui status.',
                ),
              ])),
            ),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  o.orderNo,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              StatusBadge(status: o.status, label: statusLabel(o.status)),
            ],
          ),
          const SizedBox(height: 12),
          if (error.isNotEmpty) Notice.text(error, kind: NoticeKind.error),
          if (o.status == 'pending_payment' && info != null) ...[
            _PaymentInfo(info: info!),
            const SizedBox(height: 12),
          ],
          _items(o),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Dikirim ke',
            children: [
              Text(o.recipient.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(o.recipient.phone),
              Text(o.recipient.formatted),
              if (o.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Catatan: ${o.note}', style: const TextStyle(color: AppColors.textMuted)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _history(o),
          const SizedBox(height: 16),
          if (wa.isNotEmpty) ...[
            PrimaryButton(
              label: 'Konfirmasi via WhatsApp',
              color: const Color(0xFF22C55E),
              onPressed: () => _openWa(wa),
            ),
            const SizedBox(height: 10),
          ],
          if (o.canCancel && !confirming)
            OutlinedButton(
              onPressed: () => setState(() => confirming = true),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                side: BorderSide(color: Colors.red.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Batalkan pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          if (confirming) _cancelBox(o),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Get.off(() => const MyOrdersView()),
            child: const Text('‹ Semua pesanan'),
          ),
        ],
      ),
    );
  }

  Widget _items(OrderModel o) {
    const muted = TextStyle(fontSize: 12, color: AppColors.textLight);
    return SectionCard(
      title: 'Item',
      children: [
        for (final it in o.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.name),
                      Text(
                        '${it.qty}${it.unit != null ? ' ${it.unit}' : ''} x ${perUnit(it.unitPrice, it.unit)}',
                        style: muted,
                      ),
                      if (it.tierMinQty != null)
                        Text(
                          tierNote(it.tierMinQty),
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                        ),
                    ],
                  ),
                ),
                Text(rupiah(it.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const Divider(),
        _row('Subtotal', rupiah(o.subtotal)),
        if (o.discount > 0)
          _row(
            'Diskon${o.discountNote != null ? ' (${o.discountNote})' : ''}',
            '-${rupiah(o.discount)}',
            style: TextStyle(color: Colors.green.shade700),
          ),
        _row(
          'Ongkir',
          o.shippingFee > 0
              ? rupiah(o.shippingFee)
              : o.status == 'pending_payment'
                  ? 'menunggu admin'
                  : 'Rp 0',
        ),
        const SizedBox(height: 4),
        _row(
          'Total',
          rupiah(o.total),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
        ),
      ],
    );
  }

  Widget _history(OrderModel o) {
    return SectionCard(
      title: 'Riwayat status',
      children: [
        for (final h in o.history)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.only(left: 14, bottom: 12),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: AppColors.purple100, width: 2))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(h.toLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${fmtDateTime(h.createdAt)} · oleh ${h.actor}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                if (h.note != null) Text('Alasan: ${h.note}', style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cancelBox(OrderModel o) {
    return SectionCard(
      children: [
        Text('Yakin membatalkan pesanan ${o.orderNo}? Tindakan ini tidak bisa dibatalkan.'),
        const SizedBox(height: 10),
        TextField(
          controller: reasonCtrl,
          maxLength: 255,
          decoration: inputDeco(hint: 'Alasan (opsional)'),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: busy ? null : () => setState(() => confirming = false),
              child: const Text('Tidak'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: busy ? null : _cancel,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
              child: Text(busy ? 'Membatalkan...' : 'Ya, batalkan'),
            ),
          ],
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

class _PaymentInfo extends StatelessWidget {
  final StoreInfo info;

  const _PaymentInfo({required this.info});

  @override
  Widget build(BuildContext context) {
    if (!info.paymentConfigured) {
      return Notice.text(
        'Info rekening toko belum diatur. Silakan tunggu konfirmasi dari Mihan Store'
        '${info.storeWhatsapp != null ? ' atau hubungi toko lewat WhatsApp' : ''} sebelum melakukan transfer.',
        kind: NoticeKind.warn,
      );
    }
    const bold = TextStyle(fontWeight: FontWeight.bold);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purple50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.purple100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transfer ke rekening berikut',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.purpleDark),
          ),
          const SizedBox(height: 6),
          Text.rich(TextSpan(children: [const TextSpan(text: 'Bank: '), TextSpan(text: info.bankName, style: bold)])),
          Row(
            children: [
              Text.rich(TextSpan(children: [
                const TextSpan(text: 'No. rekening: '),
                TextSpan(text: info.bankAccountNumber, style: bold.copyWith(letterSpacing: 0.8)),
              ])),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                visualDensity: VisualDensity.compact,
                tooltip: 'Salin nomor rekening',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: info.bankAccountNumber ?? ''));
                  Get.snackbar('Disalin', 'Nomor rekening disalin', snackPosition: SnackPosition.BOTTOM);
                },
              ),
            ],
          ),
          Text.rich(TextSpan(children: [
            const TextSpan(text: 'Atas nama: '),
            TextSpan(text: info.bankAccountHolder, style: bold),
          ])),
          if (info.paymentNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(info.paymentNote!, style: const TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}
