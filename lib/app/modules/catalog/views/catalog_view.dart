import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../admin/views/admin_view.dart';

import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/views/login_dialog.dart';
import '../controllers/catalog_controller.dart';
import '../widgets/cart_bottom_sheet.dart';
import '../widgets/catalog_grid_widget.dart';
import '../widgets/catalog_header_widget.dart';

class CatalogView extends StatelessWidget {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CatalogController());
    final authController = Get.find<AuthController>();
    final searchCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.purpleGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'MihanStore',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            actions: [
            Obx(() {
              if (authController.isAdmin) {
                return Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shield, size: 14),
                    label: const Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Get.to(() => const AdminView()),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

              Obx(() {
                final isLoggedIn = authController.isLoggedIn;
                return IconButton(
                  icon: Icon(
                    isLoggedIn ? Icons.account_circle : Icons.account_circle_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                  tooltip: isLoggedIn
                      ? authController.displayName
                      : 'Masuk Akun',
                  onPressed: () => LoginDialog.show(context),
                );
              }),
              Obx(() {
                final total = controller.cartController.totalCount;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: Colors.white),
                      tooltip: 'Keranjang Belanja',
                      onPressed: () => CartBottomSheet.show(context),
                    ),
                    if (total > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFACC15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            total > 99 ? '99+' : '$total',
                            style: const TextStyle(
                              color: AppColors.purpleDark,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryPurple,
        onRefresh: controller.loadData,
        child: Column(
          children: [
            CatalogHeaderWidget(
              controller: controller,
              searchCtrl: searchCtrl,
            ),
            Expanded(
              child: CatalogGridWidget(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

