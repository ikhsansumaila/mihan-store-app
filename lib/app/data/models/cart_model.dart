import '../config/api_config.dart';
import '../services/api_client.dart';

class NextTier {
  final int minQty;
  final int unitPrice;
  final int moreQty;

  const NextTier({required this.minQty, required this.unitPrice, required this.moreQty});

  factory NextTier.fromJson(Map<String, dynamic> j) =>
      NextTier(minQty: asInt(j['minQty']), unitPrice: asInt(j['unitPrice']), moreQty: asInt(j['moreQty']));
}

/// Satu baris keranjang dari server (GET /api/cart). Harga dihitung server.
class CartLine {
  final int productId;
  final String name;
  final String category;
  final String image;
  final int price;
  final int qty;
  final int lineTotal;
  final bool available;
  final String unit;
  final int baseUnitPrice;
  final int unitPrice;
  final int? tierMinQty;
  final NextTier? nextTier;
  final int savings;
  final bool priceChanged;
  final int? previousUnitPrice;

  const CartLine({
    required this.productId,
    required this.name,
    required this.category,
    required this.image,
    required this.price,
    required this.qty,
    required this.lineTotal,
    required this.available,
    required this.unit,
    required this.baseUnitPrice,
    required this.unitPrice,
    this.tierMinQty,
    this.nextTier,
    required this.savings,
    required this.priceChanged,
    this.previousUnitPrice,
  });

  factory CartLine.fromJson(Map<String, dynamic> j) {
    final unit = asStr(j['unit']).trim();
    final price = asInt(j['price']);
    return CartLine(
      productId: asInt(j['productId']),
      name: asStr(j['name']),
      category: asStr(j['category']),
      image: asStr(j['image']),
      price: price,
      qty: asInt(j['qty']),
      lineTotal: asInt(j['lineTotal']),
      available: j['available'] == true,
      unit: unit.isEmpty ? 'pcs' : unit,
      baseUnitPrice: asInt(j['baseUnitPrice'], price),
      unitPrice: asInt(j['unitPrice'] ?? j['price']),
      tierMinQty: asIntOrNull(j['tierMinQty']),
      nextTier: j['nextTier'] is Map<String, dynamic> ? NextTier.fromJson(j['nextTier']) : null,
      savings: asInt(j['savings']),
      priceChanged: j['priceChanged'] == true,
      previousUnitPrice: asIntOrNull(j['previousUnitPrice']),
    );
  }

  String? get imageUrl {
    final s = image.trim();
    if (s.startsWith('https://') || s.startsWith('http://')) return s;
    if (s.startsWith('/')) return '${ApiConfig.imageBaseUrl}$s';
    return null;
  }
}

class CartModel {
  final List<CartLine> items;
  final int subtotal;
  final int itemCount;
  final int lineCount;
  final bool hasUnavailable;
  final int maxQty;
  final int savings;
  final bool hasPriceChanges;

  const CartModel({
    required this.items,
    required this.subtotal,
    required this.itemCount,
    required this.lineCount,
    required this.hasUnavailable,
    required this.maxQty,
    required this.savings,
    required this.hasPriceChanges,
  });

  /// null bila bentuk respons tidak sesuai (sama seperti pemeriksaan Array.isArray di web).
  static CartModel? tryParse(dynamic j) {
    if (j is! Map<String, dynamic> || j['items'] is! List) return null;
    return CartModel(
      items: (j['items'] as List).whereType<Map<String, dynamic>>().map(CartLine.fromJson).toList(),
      subtotal: asInt(j['subtotal']),
      itemCount: asInt(j['itemCount']),
      lineCount: asInt(j['lineCount']),
      hasUnavailable: j['hasUnavailable'] == true,
      maxQty: asInt(j['maxQty'], 999),
      savings: asInt(j['savings']),
      hasPriceChanges: j['hasPriceChanges'] == true,
    );
  }

  int get priceChangedCount => items.where((i) => i.priceChanged).length;
}
