import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_dialog.dart';
import '../controllers/cart_controller.dart';
import 'cart_footer_widget.dart';
import 'cart_item_tile.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  static void show(BuildContext context) {
    Get.find<CartController>().refreshCart();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final auth = Get.find<AuthController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildHeader(cart),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (!auth.isLoggedIn) return _buildLoginPrompt(context);
              return _buildItemList(cart);
            }),
          ),
          CartFooterWidget(cart: cart),
        ],
      ),
    );
  }

  Widget _buildHeader(CartController cart) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Keranjang',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${cart.totalCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Spacer(),
          Obx(() => cart.isLoading.value
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildEmpty({required String title, required String subtitle, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_shopping_cart_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            if (action != null) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    return _buildEmpty(
      title: 'Masuk untuk berbelanja',
      subtitle: 'Keranjang tersimpan di akun Anda, jadi bisa dilanjutkan di web maupun aplikasi.',
      action: SizedBox(
        width: 200,
        child: PrimaryButton(label: 'Masuk / Daftar', onPressed: () => LoginDialog.requireLogin(context)),
      ),
    );
  }

  Widget _buildItemList(CartController cart) {
    final c = cart.cart.value;
    if (c == null && cart.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c == null || c.items.isEmpty) {
      return _buildEmpty(
        title: 'Keranjang Anda masih kosong',
        subtitle: 'Tambahkan produk dari katalog toko',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cart.errorMessage.value != null) Notice.text(cart.errorMessage.value!, kind: NoticeKind.error),
        PriceChangeBanner(cart: cart),
        if (c.hasUnavailable)
          Notice.text(
            'Ada produk yang sudah tidak tersedia. Hapus produk bertanda “Tidak tersedia” sebelum checkout.',
            kind: NoticeKind.warn,
          ),
        for (var i = 0; i < c.items.length; i++) ...[
          if (i > 0) const Divider(height: 20),
          CartItemTile(item: c.items[i], cart: cart),
        ],
      ],
    );
  }
}

/// Banner di atas keranjang/checkout bila ada baris yang harganya berubah.
class PriceChangeBanner extends StatelessWidget {
  final CartController cart;

  const PriceChangeBanner({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final n = cart.cart.value?.priceChangedCount ?? 0;
      if (n == 0) return const SizedBox.shrink();
      return Notice(
        kind: NoticeKind.warn,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(TextSpan(children: [
              const TextSpan(text: 'Harga berubah', style: TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' untuk $n produk sejak terakhir Anda lihat. Periksa harga terbaru di bawah.'),
            ])),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: cart.acking.value ? null : cart.ackPrices,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    });
  }
}
