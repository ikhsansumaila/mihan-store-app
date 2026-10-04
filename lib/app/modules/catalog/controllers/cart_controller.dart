import 'package:get/get.dart';

import '../../../data/models/cart_model.dart';
import '../../../data/services/api_client.dart';
import '../../../data/services/shop_service.dart';
import '../../auth/controllers/auth_controller.dart';

/// Keranjang tersimpan di server per akun (sama dengan CartContext di mihan-store-web):
/// harga, harga grosir, dan ketersediaan dihitung server. Wajib login.
class CartController extends GetxController {
  final ShopService _shop = ShopService();
  AuthController get _auth => Get.find<AuthController>();

  final cart = Rxn<CartModel>();
  final isLoading = false.obs;
  final busyProductId = RxnInt();
  final acking = false.obs;
  final errorMessage = RxnString();

  int get totalCount => cart.value?.itemCount ?? 0;
  List<CartLine> get items => cart.value?.items ?? const [];

  @override
  void onInit() {
    super.onInit();
    // Muat ulang keranjang saat login/logout.
    ever<String?>(_auth.authToken, (_) => refreshCart());
    refreshCart();
  }

  /// true bila galat sudah ditangani sebagai sesi berakhir.
  bool _handleUnauthorized(Object err) {
    if (err is ApiException && err.isUnauthorized) {
      cart.value = null;
      _auth.handleUnauthorized();
      return true;
    }
    return false;
  }

  void setCart(CartModel? c) {
    if (c != null) cart.value = c;
  }

  Future<CartModel?> refreshCart() async {
    if (!_auth.isLoggedIn) {
      cart.value = null;
      return null;
    }
    isLoading.value = true;
    try {
      final c = await _shop.getCart();
      cart.value = c;
      return c;
    } catch (err) {
      _handleUnauthorized(err);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Tambah 1 produk. Mengembalikan pesan galat, atau null bila berhasil.
  Future<String?> addItem(int productId, [int qty = 1]) async {
    try {
      cart.value = await _shop.addItem(productId, qty);
      return null;
    } catch (err) {
      if (_handleUnauthorized(err)) return 'Sesi berakhir, silakan masuk lagi.';
      return apiErrorMessage(err, 'Gagal menambah ke keranjang');
    }
  }

  Future<void> _run(int productId, Future<CartModel> Function() fn) async {
    busyProductId.value = productId;
    errorMessage.value = null;
    try {
      cart.value = await fn();
    } catch (err) {
      if (_handleUnauthorized(err)) return;
      errorMessage.value = apiErrorMessage(err, 'Gagal memperbarui keranjang');
      refreshCart();
    } finally {
      busyProductId.value = null;
    }
  }

  Future<void> setQty(int productId, int qty) =>
      _run(productId, () => _shop.setQty(productId, qty.clamp(0, cart.value?.maxQty ?? 999)));

  Future<void> removeItem(int productId) => _run(productId, () => _shop.removeItem(productId));

  /// "Mengerti": tandai harga terbaru sudah dilihat.
  Future<void> ackPrices() async {
    acking.value = true;
    errorMessage.value = null;
    try {
      cart.value = await _shop.ackPrices();
    } catch (err) {
      if (!_handleUnauthorized(err)) {
        errorMessage.value = apiErrorMessage(err, 'Gagal memperbarui keranjang');
      }
    } finally {
      acking.value = false;
    }
  }
}
