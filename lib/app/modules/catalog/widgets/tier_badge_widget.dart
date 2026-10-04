import 'package:flutter/material.dart';

import '../../../data/models/product_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/currency_format.dart';

class TierBadgeWidget extends StatelessWidget {
  final ProductModel product;
  final bool isExpanded;
  final VoidCallback onToggle;

  const TierBadgeWidget({
    super.key,
    required this.product,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (product.tiers.isEmpty) return const SizedBox.shrink();

    final minPrice = product.minTierPrice ?? product.price;

    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge Button
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amberBadgeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.amberBadgeBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Grosir · mulai ${CurrencyFormat.convertToIdr(minPrice)}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amberBadgeText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.amberBadgeText,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Tier List
          if (isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.amberAccordionBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.amberAccordionBorder),
              ),
              child: Column(
                children: product.tiers.map((t) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${t.minQty}+ ${product.unit}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${CurrencyFormat.convertToIdr(t.unitPrice)} / ${product.unit}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
