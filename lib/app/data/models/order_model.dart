import '../services/api_client.dart';

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

/// Wilayah (provinsi/kab-kota/kecamatan/kelurahan) dari /api/regions/*.
class RegionRef {
  final String code;
  final String name;

  const RegionRef({required this.code, required this.name});

  factory RegionRef.fromJson(dynamic j) =>
      j is Map ? RegionRef(code: asStr(j['code']), name: asStr(j['name'])) : const RegionRef(code: '', name: '');
}

class OrderItem {
  final String name;
  final int unitPrice;
  final int qty;
  final int lineTotal;
  final String? unit;
  final int? tierMinQty;

  const OrderItem({
    required this.name,
    required this.unitPrice,
    required this.qty,
    required this.lineTotal,
    this.unit,
    this.tierMinQty,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: asStr(j['name']),
        unitPrice: asInt(j['unitPrice']),
        qty: asInt(j['qty']),
        lineTotal: asInt(j['lineTotal']),
        unit: asStrOrNull(j['unit']),
        tierMinQty: asIntOrNull(j['tierMinQty']),
      );
}

class OrderHistory {
  final String toLabel;
  final String actor;
  final String? note;
  final DateTime? createdAt;

  const OrderHistory({required this.toLabel, required this.actor, this.note, this.createdAt});

  factory OrderHistory.fromJson(Map<String, dynamic> j) => OrderHistory(
        toLabel: asStr(j['toLabel']),
        actor: asStr(j['actor']),
        note: asStrOrNull(j['note']),
        createdAt: _date(j['createdAt']),
      );
}

class OrderRecipient {
  final String name;
  final String phone;
  final String address;
  final String city;
  final String? postalCode;
  final RegionRef? province;
  final RegionRef? regency;
  final RegionRef? district;
  final RegionRef? village;

  const OrderRecipient({
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    this.postalCode,
    this.province,
    this.regency,
    this.district,
    this.village,
  });

  factory OrderRecipient.fromJson(dynamic raw) {
    final Map j = raw is Map ? raw : const {};
    final reg = j['region'];
    return OrderRecipient(
      name: asStr(j['name']),
      phone: asStr(j['phone']),
      address: asStr(j['address']),
      city: asStr(j['city']),
      postalCode: asStrOrNull(j['postalCode']),
      province: reg is Map ? RegionRef.fromJson(reg['province']) : null,
      regency: reg is Map ? RegionRef.fromJson(reg['regency']) : null,
      district: reg is Map ? RegionRef.fromJson(reg['district']) : null,
      village: reg is Map ? RegionRef.fromJson(reg['village']) : null,
    );
  }

  /// `alamat, kelurahan/desa, Kec. kecamatan, kab/kota, provinsi kodepos` (sama dengan formatFullAddress
  /// di web; pesanan lama tanpa wilayah: `alamat, kota kodepos`).
  String get formatted {
    final parts = <String>[];
    final a = address
        .split(RegExp(r'\r\n|\r|\n'))
        .map((p) => p.split(RegExp(r'\s+')).join(' ').trim().replaceAll(RegExp(r'^[,\s]+|[,\s]+$'), ''))
        .where((p) => p.isNotEmpty)
        .join(', ');
    if (a.isNotEmpty) parts.add(a);
    String last;
    if (village != null && village!.name.isNotEmpty) {
      parts.addAll([village!.name, 'Kec. ${district?.name ?? ''}', regency?.name ?? '']);
      last = province?.name ?? '';
    } else {
      last = city.trim();
    }
    final pc = (postalCode ?? '').trim();
    if (pc.isNotEmpty) last = '$last $pc'.trim();
    if (last.isNotEmpty) parts.add(last);
    return parts.where((p) => p.isNotEmpty).join(', ');
  }
}

class OrderModel {
  final String orderNo;
  final String status;
  final int subtotal;
  final int discount;
  final String? discountNote;
  final int shippingFee;
  final int total;
  final OrderRecipient recipient;
  final String? note;
  final List<OrderItem> items;
  final List<OrderHistory> history;
  final bool canCancel;

  const OrderModel({
    required this.orderNo,
    required this.status,
    required this.subtotal,
    required this.discount,
    this.discountNote,
    required this.shippingFee,
    required this.total,
    required this.recipient,
    this.note,
    required this.items,
    required this.history,
    required this.canCancel,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        orderNo: asStr(j['orderNo']),
        status: asStr(j['status']),
        subtotal: asInt(j['subtotal']),
        discount: asInt(j['discount']),
        discountNote: asStrOrNull(j['discountNote']),
        shippingFee: asInt(j['shippingFee']),
        total: asInt(j['total']),
        recipient: OrderRecipient.fromJson(j['recipient']),
        note: asStrOrNull(j['note']),
        items: (j['items'] as List? ?? const []).whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList(),
        history:
            (j['history'] as List? ?? const []).whereType<Map<String, dynamic>>().map(OrderHistory.fromJson).toList(),
        canCancel: j['canCancel'] == true,
      );
}

/// Ringkasan pesanan di daftar "Pesanan Saya".
class OrderSummary {
  final String orderNo;
  final String status;
  final int total;
  final int itemCount;
  final String? firstItem;
  final DateTime? createdAt;

  const OrderSummary({
    required this.orderNo,
    required this.status,
    required this.total,
    required this.itemCount,
    this.firstItem,
    this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        orderNo: asStr(j['orderNo']),
        status: asStr(j['status']),
        total: asInt(j['total']),
        itemCount: asInt(j['itemCount']),
        firstItem: asStrOrNull(j['firstItem']),
        createdAt: _date(j['createdAt']),
      );
}

class OrderPage {
  final List<OrderSummary> items;
  final int total;
  final int perPage;

  const OrderPage({required this.items, required this.total, required this.perPage});

  int get pages {
    final pp = perPage > 0 ? perPage : 10;
    final p = (total / pp).ceil();
    return p < 1 ? 1 : p;
  }
}

class StoreInfo {
  final String? storeWhatsapp;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountHolder;
  final String? paymentNote;
  final bool paymentConfigured;

  const StoreInfo({
    this.storeWhatsapp,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountHolder,
    this.paymentNote,
    required this.paymentConfigured,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> j) => StoreInfo(
        storeWhatsapp: asStrOrNull(j['storeWhatsapp']),
        bankName: asStrOrNull(j['bankName']),
        bankAccountNumber: asStrOrNull(j['bankAccountNumber']),
        bankAccountHolder: asStrOrNull(j['bankAccountHolder']),
        paymentNote: asStrOrNull(j['paymentNote']),
        paymentConfigured: j['paymentConfigured'] == true,
      );
}
