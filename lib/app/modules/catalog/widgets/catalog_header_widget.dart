import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../controllers/catalog_controller.dart';

class CatalogHeaderWidget extends StatelessWidget {
  final CatalogController controller;
  final TextEditingController searchCtrl;

  const CatalogHeaderWidget({
    super.key,
    required this.controller,
    required this.searchCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        children: [
          // Search Input
          Obx(() {
            final hasQuery = controller.searchQuery.value.isNotEmpty;
            return TextField(
              controller: searchCtrl,
              onChanged: (val) => controller.searchQuery.value = val,
              decoration: InputDecoration(
                hintText: 'Cari produk berdasarkan nama atau deskripsi...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.primaryPurple, size: 20),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          controller.clearSearch();
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                filled: true,
                fillColor: AppColors.background,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderInput),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: AppColors.primaryPurple, width: 1.5),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),

          // Horizontal Category Chips
          SizedBox(
            height: 34,
            child: Obx(() {
              final activeCategory = controller.selectedCategory.value;
              return ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildChip(
                    label: 'Semua Kategori',
                    isSelected: activeCategory.isEmpty,
                    onTap: () => controller.selectCategory(''),
                  ),
                  ...controller.categories.map((cat) {
                    return _buildChip(
                      label: cat.name,
                      isSelected: activeCategory == cat.slug,
                      onTap: () => controller.selectCategory(cat.slug),
                    );
                  }),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPurple : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPurple
                  : AppColors.borderInput,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
