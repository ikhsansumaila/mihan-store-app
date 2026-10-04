import '../config/api_config.dart';
import '../models/cart_model.dart';
import '../models/order_model.dart';
import 'api_client.dart';

/// Data yang dikirim saat checkout. Wilayah berupa KODE; nama diambil server dari DB.
class CheckoutInput {
  final String recipientName;
  final String recipientPhone;
  final String provinceCode;
  final String regencyCode;
  final String districtCode;
  final String villageCode;
  final String address;
  final String postalCode;
  final String note;
  final String idempotencyKey;
  final int expectedTotal;

  const CheckoutInput({
    required this.recipientName,
    required this.recipientPhone,
    required this.provinceCode,
    required this.regencyCode,
    required this.districtCode,
    required this.villageCode,
    required this.address,
    required this.postalCode,
    required this.note,
    required this.idempotencyKey,
    required this.expectedTotal,
  });

  Map<String, dynamic> toJson() => {
        'recipientName': recipientName,
        'recipientPhone': recipientPhone,
        'provinceCode': provinceCode,
        'regencyCode': regencyCode,
        'districtCode': districtCode,
        'villageCode': villageCode,
        'address': address,
        'postalCode': postalCode,
        'note': note,
        'idempotencyKey': idempotencyKey,
        'expectedTotal': expectedTotal,
      };
}

/// API pelanggan: keranjang, pesanan, info toko, dan data wilayah
/// (sama dengan frontend/src/shop/api.js & regionsApi.js di mihan-store-web).
class ShopService {
  final ApiClient _api = ApiClient.instance;

  CartModel _cart(dynamic data) {
    final c = CartModel.tryParse(data);
    if (c == null) throw const ApiException(500);
    return c;
  }

  Future<CartModel> getCart() async => _cart(await _api.get(ApiConfig.cart));

  Future<CartModel> addItem(int productId, [int qty = 1]) async =>
      _cart(await _api.post(ApiConfig.cartItems, {'productId': productId, 'qty': qty}));

  Future<CartModel> setQty(int productId, int qty) async =>
      _cart(await _api.put(ApiConfig.cartItems, {'productId': productId, 'qty': qty}));

  Future<CartModel> removeItem(int productId) async =>
      _cart(await _api.delete('${ApiConfig.cartItems}/$productId'));

  /// "Mengerti": harga yang terlihat disetel ke harga terkini (penanda perubahan harga hilang).
  Future<CartModel> ackPrices() async => _cart(await _api.post(ApiConfig.cartAckPrices, const {}));

  /// Mengembalikan nomor pesanan yang baru dibuat.
  Future<String> createOrder(CheckoutInput input) async {
    final data = await _api.post(ApiConfig.orders, input.toJson());
    return data is Map ? asStr(data['orderNo']) : '';
  }

  Future<OrderPage> listOrders(int page) async {
    final data = await _api.get('${ApiConfig.orders}?page=$page&per_page=10');
    final Map j = data is Map ? data : const {};
    return OrderPage(
      items: (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(OrderSummary.fromJson).toList(),
      total: asInt(j['total']),
      perPage: asInt(j['perPage'], 10),
    );
  }

  Future<OrderModel> getOrder(String orderNo) async =>
      OrderModel.fromJson(await _api.get('${ApiConfig.orders}/${Uri.encodeComponent(orderNo)}'));

  Future<OrderModel> cancelOrder(String orderNo, String reason) async => OrderModel.fromJson(
      await _api.post('${ApiConfig.orders}/${Uri.encodeComponent(orderNo)}/cancel', {'reason': reason}));

  Future<StoreInfo> getStoreInfo() async => StoreInfo.fromJson(await _api.get(ApiConfig.storeInfo));

  // Wilayah dimuat PER INDUK dan disimpan di memori selama app berjalan (galat tidak di-cache).
  static final Map<String, Future<List<RegionRef>>> _regionCache = {};

  static const regionPaths = ['provinces', 'regencies', 'districts', 'villages'];

  Future<List<RegionRef>> loadRegions(int level, String? parent) {
    final path = level == 0 ? regionPaths[0] : '${regionPaths[level]}/$parent';
    return _regionCache.putIfAbsent(path, () async {
      try {
        final data = await _api.get('${ApiConfig.regions}/$path', auth: false);
        final items = (data is Map && data['data'] is List) ? data['data'] as List : const [];
        final list = items
            .whereType<Map>()
            .where((it) => it['code'] is String && it['name'] is String)
            .map((it) => RegionRef(code: it['code'] as String, name: it['name'] as String))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      } catch (_) {
        _regionCache.remove(path);
        rethrow;
      }
    });
  }

  static String regionErrorMessage(Object err, String lower) {
    final st = err is ApiException ? err.status : 0;
    if (st == 503) return 'Data wilayah belum tersedia. Silakan coba lagi nanti atau hubungi toko.';
    if (st == 404) return 'Daftar $lower tidak ditemukan. Pilih ulang wilayah di atasnya.';
    if (st == 429) return 'Terlalu banyak permintaan. Tunggu sebentar lalu coba lagi.';
    return 'Gagal memuat daftar $lower. Periksa koneksi lalu coba lagi.';
  }
}
