class TierModel {
  final int minQty;
  final String type; // 'fixed' or 'percent'
  final num value;
  final num unitPrice;

  TierModel({
    required this.minQty,
    required this.type,
    required this.value,
    required this.unitPrice,
  });

  factory TierModel.fromJson(Map<String, dynamic> json) {
    return TierModel(
      minQty: json['minQty'] is int
          ? json['minQty'] as int
          : int.tryParse(json['minQty']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'fixed',
      value: json['value'] is num
          ? json['value'] as num
          : num.tryParse(json['value']?.toString() ?? '0') ?? 0,
      unitPrice: json['unitPrice'] is num
          ? json['unitPrice'] as num
          : num.tryParse(json['unitPrice']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'minQty': minQty,
        'type': type,
        'value': value,
        'unitPrice': unitPrice,
      };
}
