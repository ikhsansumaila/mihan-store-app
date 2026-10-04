import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/shop_format.dart';
import '../../checkout/views/checkout_view.dart';
import '../controllers/cart_controller.dart';

class CartFooterWidget extends StatelessWidget {
  final CartController cart;

  const CartFooterWidget({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = cart.cart.value;
      if (c == null || c.items.isEmpty) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (${c.itemCount} item)',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  Text(
                    rupiah(c.subtotal),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
                  ),
                ],
              ),
              if (c.savings > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Hemat harga grosir', style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                      Text(rupiah(c.savings), style: TextStyle(fontSize: 13, color: Colors.green.shade700)),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'Harga mengikuti harga terkini (harga grosir otomatis sesuai jumlah per produk). Ongkir dan diskon '
                '(bila ada) ditetapkan admin setelah pesanan dibuat.',
                style: TextStyle(fontSize: 11, color: AppColors.textLight),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: c.hasUnavailable || c.itemCount == 0
                    ? null
                    : () {
                        Navigator.pop(context);
                        Get.to(() => const CheckoutView());
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                child: const Text('Lanjut ke checkout'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
