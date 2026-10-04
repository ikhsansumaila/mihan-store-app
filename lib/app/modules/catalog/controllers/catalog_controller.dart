import 'package:get/get.dart';

import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import '../../auth/views/login_dialog.dart';
import 'cart_controller.dart';

class CatalogController extends GetxController {
  final ProductService _service = ProductService();

  final products = <ProductModel>[].obs;
  final categories = <CategoryModel>[].obs;

  final isLoading = true.obs;
  final errorMessage = RxnString();

  final searchQuery = ''.obs;
  final selectedCategory = ''.obs; // Empty string means "Semua"

  // Set of product IDs whose tier accordions are currently opened
  final expandedTierProductIds = <int>{}.obs;

  // Feedback state for Add To Cart buttons ('idle' | 'busy' | 'done')
  final buttonStates = <int, String>{}.obs;

  CartController get cartController => Get.find<CartController>();

  @override
  void onInit() {
    super.onInit();
    // Ensure CartController is registered
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final results = await Future.wait([
        _service.fetchProducts(),
        _service.fetchCategories(),
      ]);

      products.value = results[0] as List<ProductModel>;
      categories.value = results[1] as List<CategoryModel>;
    } catch (e) {
      errorMessage.value =
          'Gagal memuat produk. Silakan periksa koneksi internet Anda.';
    } finally {
      isLoading.value = false;
    }
  }

  List<ProductModel> get filteredProducts {
    final query = searchQuery.value.trim().toLowerCase();
    final cat = selectedCategory.value.trim().toLowerCase();

    return products.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);

      final matchesCategory = cat.isEmpty || p.category.toLowerCase() == cat;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void selectCategory(String slug) {
    if (selectedCategory.value == slug) {
      selectedCategory.value = ''; // Toggle back to all
    } else {
      selectedCategory.value = slug;
    }
  }

  void toggleTier(int productId) {
    if (expandedTierProductIds.contains(productId)) {
      expandedTierProductIds.remove(productId);
    } else {
      expandedTierProductIds.add(productId);
    }
  }

  bool isTierExpanded(int productId) =>
      expandedTierProductIds.contains(productId);

  String getButtonState(int productId) =>
      buttonStates[productId] ?? 'idle';

  Future<void> addToCart(ProductModel product) async {
    // Keranjang tersimpan di akun: wajib masuk dulu (sama dengan web yang mengarahkan ke /login).
    final ctx = Get.context;
    if (ctx == null || !await LoginDialog.requireLogin(ctx)) return;

    buttonStates[product.id] = 'busy';
    final err = await cartController.addItem(product.id, 1);
    buttonStates[product.id] = err == null ? 'done' : 'error';
    if (err != null) {
      Get.snackbar('Gagal', err, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 3));
    }

    // Kembali ke status awal setelah 2,5 detik (sama dengan mihan-store-web)
    Future.delayed(const Duration(milliseconds: 2500), () {
      final s = buttonStates[product.id];
      if (s == 'done' || s == 'error') buttonStates[product.id] = 'idle';
    });
  }

  void clearSearch() {
    searchQuery.value = '';
  }
}
