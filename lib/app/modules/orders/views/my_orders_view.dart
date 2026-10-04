import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/order_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/shop_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/shop_format.dart';
import '../../../widgets/ui.dart';
import '../../auth/controllers/auth_controller.dart';
import 'order_detail_view.dart';

class MyOrdersView extends StatefulWidget {
  const MyOrdersView({super.key});

  @override
  State<MyOrdersView> createState() => _MyOrdersViewState();
}

class _MyOrdersViewState extends State<MyOrdersView> {
  final shop = ShopService();
  int page = 1;
  OrderPage? data;
  String error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => error = '');
    try {
      final d = await shop.listOrders(page);
      if (mounted) setState(() => data = d);
    } catch (err) {
      if (err is ApiException && err.isUnauthorized) {
        Get.find<AuthController>().handleUnauthorized();
        Get.back();
        return;
      }
      if (mounted) setState(() => error = apiErrorMessage(err, 'Gagal memuat pesanan'));
    }
  }

  void _go(int p) {
    setState(() {
      page = p;
      data = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = data;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: purpleAppBar('Pesanan Saya'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (error.isNotEmpty) Notice.text(error, kind: NoticeKind.error),
              if (d == null && error.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (d != null && d.items.isEmpty)
                SectionCard(children: [
                  const Text('Belum ada pesanan.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  PrimaryButton(label: 'Mulai belanja', onPressed: () => Get.back()),
                ]),
              if (d != null)
                for (final o in d.items) ...[
                  _OrderCard(
                    order: o,
                    onTap: () async {
                      await Get.to(() => OrderDetailView(orderNo: o.orderNo));
                      _load();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              if (d != null && d.pages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(onPressed: page <= 1 ? null : () => _go(page - 1), child: const Text('‹ Sebelumnya')),
                    Text('Halaman $page dari ${d.pages}', style: const TextStyle(fontSize: 12.5)),
                    OutlinedButton(
                      onPressed: page >= d.pages ? null : () => _go(page + 1),
                      child: const Text('Berikutnya ›'),
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

class _OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(order.orderNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  StatusBadge(status: order.status, label: statusLabel(order.status)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.firstItem ?? ''}${order.itemCount > 1 ? ' dan lainnya' : ''} · ${order.itemCount} item',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fmtDateTime(order.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                  Text(
                    rupiah(order.total),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
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
