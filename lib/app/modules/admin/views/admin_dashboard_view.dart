import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../catalog/controllers/catalog_controller.dart';
import '../../invoice/invoice_page.dart';
import '../widgets/admin_menu_items.dart';
import '../widgets/admin_product_sheet.dart';
import '../widgets/admin_profile_header_widget.dart';

class AdminDashboardView extends StatelessWidget {
  final dynamic user;

  const AdminDashboardView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final catalog = Get.isRegistered<CatalogController>()
        ? Get.find<CatalogController>()
        : Get.put(CatalogController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Panel Admin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: catalog.loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminProfileHeaderWidget(user: user),
            const SizedBox(height: 16),
            _buildStats(catalog),
            const SizedBox(height: 20),
            const Text(
              'Menu Admin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            AdminMenuItemWidget(
              title: 'Pembuat Invoice',
              subtitle: 'Buat nota pesanan pelanggan, cetak PDF / WhatsApp',
              icon: Icons.receipt_long,
              badge: 'Aktif',
              color: const Color(0xFF1B5E20),
              onTap: () => Get.to(() => InvoicePage()),
            ),
            const SizedBox(height: 10),
            Obx(() => AdminMenuItemWidget(
                  title: 'Katalog & Stok',
                  subtitle: 'Pantau harga dan tingkat diskon grosir produk',
                  icon: Icons.inventory_2_outlined,
                  badge: '${catalog.products.length} Item',
                  color: AppColors.primaryPurple,
                  onTap: () => AdminProductSheet.show(context, catalog),
                )),
            const SizedBox(height: 10),
            AdminMenuItemWidget(
              title: 'Status Google Admin',
              subtitle: 'Email Google terverifikasi dalam ADMIN_EMAILS server',
              icon: Icons.verified_user_outlined,
              badge: 'Terverifikasi',
              color: Colors.blue.shade700,
              onTap: () => _showDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(CatalogController catalog) {
    return Obx(() => Row(
          children: [
            AdminStatItemWidget(
              label: 'Produk',
              value: '${catalog.products.length}',
              icon: Icons.inventory_2,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 8),
            AdminStatItemWidget(
              label: 'Kategori',
              value: '${catalog.categories.length}',
              icon: Icons.category,
              color: Colors.purple.shade700,
            ),
            const SizedBox(width: 8),
            const AdminStatItemWidget(
              label: 'Status',
              value: 'Aktif',
              icon: Icons.shield,
              color: Color(0xFF1B5E20),
            ),
          ],
        ));
  }

  void _showDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Info Google Admin'),
        content: Text(
          'Email terdaftar: ${user.email}\nRole: Administrator\nOtorisasi server: store.mihan.web.id',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
