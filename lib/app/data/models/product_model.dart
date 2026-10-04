import '../config/api_config.dart';
import 'tier_model.dart';

class ProductModel {
  final int id;
  final String name;
  final String category;
  final int price;
  final String description;
  final String image;
  final String unit;
  final List<TierModel> tiers;
  final String thumb;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.image,
    required this.unit,
    required this.tiers,
    required this.thumb,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawTiers = json['tiers'];
    final List<TierModel> parsedTiers = [];
    if (rawTiers is List) {
      for (final t in rawTiers) {
        if (t is Map<String, dynamic>) {
          parsedTiers.add(TierModel.fromJson(t));
        }
      }
    }
    // Sort tiers by minQty ascending
    parsedTiers.sort((a, b) => a.minQty.compareTo(b.minQty));

    final rawUnit = json['unit']?.toString().trim() ?? '';
    final resolvedUnit = rawUnit.isNotEmpty ? rawUnit : 'pcs';

    return ProductModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: json['price'] is int
          ? json['price'] as int
          : int.tryParse(json['price']?.toString() ?? '0') ?? 0,
      description: json['description']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      unit: resolvedUnit,
      tiers: parsedTiers,
      thumb: json['thumb']?.toString() ?? '',
    );
  }

  /// Resolved image URL for network image display
  String? get resolvedImageUrl {
    final s = (image.isNotEmpty ? image : thumb).trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return s;
    }
    if (s.startsWith('/')) {
      return '${ApiConfig.imageBaseUrl}$s';
    }
    return null;
  }

  /// Lowest wholesale unit price from tiers
  num? get minTierPrice {
    if (tiers.isEmpty) return null;
    num minP = tiers.first.unitPrice;
    for (final t in tiers) {
      if (t.unitPrice < minP) {
        minP = t.unitPrice;
      }
    }
    return minP;
  }

  /// Calculates effective unit price based on wholesale tiers for given quantity
  num effectiveUnitPrice(int qty) {
    if (tiers.isEmpty || qty <= 0) return price;
    num activePrice = price;
    for (final tier in tiers) {
      if (qty >= tier.minQty) {
        activePrice = tier.unitPrice;
      }
    }
    return activePrice;
  }

  /// Finds matched tier if any
  TierModel? matchedTier(int qty) {
    if (tiers.isEmpty || qty <= 0) return null;
    TierModel? matched;
    for (final tier in tiers) {
      if (qty >= tier.minQty) {
        matched = tier;
      }
    }
    return matched;
  }
}
