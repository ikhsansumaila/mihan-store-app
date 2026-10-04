import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/product_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_format.dart';
import '../controllers/catalog_controller.dart';
import 'product_image_widget.dart';
import 'tier_badge_widget.dart';

class ProductCardWidget extends StatelessWidget {
  final ProductModel product;

  const ProductCardWidget({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CatalogController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImageWidget(product: product),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            product.category.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.purpleLight,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: CurrencyFormat.convertToIdr(product.price),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryPurple,
                  ),
                ),
                TextSpan(
                  text: ' / ${product.unit}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Obx(() {
            final isExpanded = controller.isTierExpanded(product.id);
            return TierBadgeWidget(
              product: product,
              isExpanded: isExpanded,
              onToggle: () => controller.toggleTier(product.id),
            );
          }),
          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              product.description,
              style: const TextStyle(
                fontSize: 10.5,
                color: AppColors.textMuted,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          const SizedBox(height: 6),
          Obx(() {
            final state = controller.getButtonState(product.id);
            final isBusy = state == 'busy';
            final isDone = state == 'done';

            return SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: isBusy ? null : () => controller.addToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDone ? AppColors.successGreen : AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isBusy) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Menambahkan...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ] else if (isDone) ...[
                      const Icon(Icons.check, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Ditambahkan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ] else ...[
                      const Icon(Icons.shopping_cart_outlined, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Tambah',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
