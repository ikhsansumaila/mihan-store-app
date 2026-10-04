import 'package:flutter_test/flutter_test.dart';
import 'package:mihan_store/app/data/models/product_model.dart';
import 'package:mihan_store/app/data/models/cart_model.dart';
import 'package:mihan_store/app/data/models/order_model.dart';
import 'package:mihan_store/app/data/models/user_model.dart';
import 'package:mihan_store/app/data/config/api_config.dart';
import 'package:mihan_store/app/modules/auth/views/register_view.dart';
import 'package:mihan_store/app/modules/checkout/views/checkout_view.dart';
import 'package:mihan_store/app/utils/phone.dart';
import 'package:mihan_store/app/utils/shop_format.dart';

void main() {
  group('ProductModel & Tier Tests', () {
    final sampleJson = {
      'id': 1,
      'name': 'Kerupuk Finna Udang',
      'category': 'kerupuk',
      'price': 100000,
      'description': 'Kerupuk udang asli dengan rasa gurih',
      'image': '/uploads/products/1/test.jpg',
      'unit': 'dus',
      'tiers': [
        {'minQty': 10, 'type': 'fixed', 'value': 98000, 'unitPrice': 98000},
        {'minQty': 50, 'type': 'fixed', 'value': 95000, 'unitPrice': 95000},
      ],
      'thumb': '/uploads/products/1/test_t.jpg',
    };

    test('Parses ProductModel correctly from JSON', () {
      final product = ProductModel.fromJson(sampleJson);
      expect(product.id, 1);
      expect(product.name, 'Kerupuk Finna Udang');
      expect(product.price, 100000);
      expect(product.unit, 'dus');
      expect(product.tiers.length, 2);
      expect(product.tiers.first.minQty, 10);
      expect(product.tiers.last.minQty, 50);
      expect(product.resolvedImageUrl,
          'https://store.mihan.web.id/uploads/products/1/test.jpg');
      expect(product.minTierPrice, 95000);
    });

    test('Calculates effectiveUnitPrice based on quantity tiers', () {
      final product = ProductModel.fromJson(sampleJson);

      // Under 10 -> regular price 100.000
      expect(product.effectiveUnitPrice(1), 100000);
      expect(product.effectiveUnitPrice(9), 100000);
      expect(product.matchedTier(9), isNull);

      // 10 to 49 -> 98.000
      expect(product.effectiveUnitPrice(10), 98000);
      expect(product.effectiveUnitPrice(25), 98000);
      expect(product.matchedTier(10)?.unitPrice, 98000);

      // 50 and above -> 95.000
      expect(product.effectiveUnitPrice(50), 95000);
      expect(product.effectiveUnitPrice(100), 95000);
      expect(product.matchedTier(100)?.unitPrice, 95000);
    });
  });

  group('Server cart parsing', () {
    test('Parses cart DTO from /api/cart', () {
      final cart = CartModel.tryParse({
        'items': [
          {
            'productId': 1,
            'name': 'Kerupuk Finna Udang',
            'image': '/uploads/products/1/test.jpg',
            'price': 100000,
            'qty': 10,
            'lineTotal': 980000,
            'available': true,
            'unit': 'dus',
            'baseUnitPrice': 100000,
            'unitPrice': 98000,
            'tierMinQty': 10,
            'nextTier': {'minQty': 20, 'unitPrice': 95000, 'moreQty': 10},
            'savings': 20000,
            'priceChanged': true,
            'previousUnitPrice': 97000,
          },
        ],
        'subtotal': 980000,
        'itemCount': 10,
        'hasUnavailable': false,
        'savings': 20000,
      })!;
      final line = cart.items.single;
      expect(cart.subtotal, 980000);
      expect(cart.itemCount, 10);
      expect(cart.priceChangedCount, 1);
      expect(line.unitPrice, 98000);
      expect(line.tierMinQty, 10);
      expect(line.nextTier?.moreQty, 10);
      expect(line.imageUrl, '${ApiConfig.imageBaseUrl}/uploads/products/1/test.jpg');
    });

    test('Rejects malformed cart response', () {
      expect(CartModel.tryParse({'items': 'x'}), isNull);
      expect(CartModel.tryParse(null), isNull);
    });
  });

  group('Phone normalization (same rules as backend)', () {
    test('Accepts 08xx, 628xx, +628xx with separators', () {
      expect(normalizePhone('0812-3456-7890').phone, '+6281234567890');
      expect(normalizePhone('62 812 3456 789').phone, '+628123456789');
      expect(normalizePhone('+62 0812 3456 789').phone, '+628123456789');
      expect(normalizePhone('').phone, '');
      expect(normalizePhone('').error, '');
    });

    test('Rejects invalid numbers', () {
      expect(normalizePhone('12345678').error, PhoneErrors.prefix);
      expect(normalizePhone('0812abc').error, PhoneErrors.chars);
      expect(normalizePhone('0812').error, PhoneErrors.short);
      expect(normalizePhone('08123456789012345').error, PhoneErrors.long);
    });
  });

  group('Register & checkout validation', () {
    test('Register validation matches web rules', () {
      String v({String name = 'Budi', String u = 'budi_1', String e = 'b@x.id', String p = '', String pw = 'rahasia123'}) =>
          validateRegister(name: name, username: u, email: e, phone: p, password: pw);
      expect(v(), '');
      expect(v(name: ' '), 'Nama wajib diisi');
      expect(v(u: 'Bu'), usernameRuleText);
      expect(v(e: 'bukan-email'), 'Format email tidak valid');
      expect(v(pw: 'pendek'), 'Password harus 8–128 karakter');
      expect(v(p: '0812'), PhoneErrors.short);
    });

    test('Checkout requires recipient, region, address and postal code', () {
      final form = CheckoutForm();
      final errs = validateCheckoutForm(form, List.filled(4, null));
      expect(errs.keys, containsAll(['recipientName', 'recipientPhone', 'provinceCode', 'villageCode', 'address', 'postalCode']));

      const r = RegionRef(code: '1', name: 'X');
      form
        ..recipientName = 'Siti'
        ..recipientPhone = '081234567890'
        ..address = 'Jl. Melati No. 9'
        ..postalCode = '12345';
      expect(validateCheckoutForm(form, [r, r, r, r]), isEmpty);

      form.postalCode = '123';
      expect(validateCheckoutForm(form, [r, r, r, r])['postalCode'], 'Kode pos harus 5 digit angka.');
    });

    test('Idempotency key is a UUID v4', () {
      expect(
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(newIdempotencyKey()),
        isTrue,
      );
    });

    test('Order address is composed like the web', () {
      final rec = OrderRecipient.fromJson({
        'name': 'Siti',
        'phone': '+6281234567890',
        'address': 'Jl. Melati No. 9\nRT 03/RW 05',
        'city': 'Kota Bandung',
        'postalCode': '40111',
        'region': {
          'province': {'code': '32', 'name': 'Jawa Barat'},
          'regency': {'code': '32.73', 'name': 'Kota Bandung'},
          'district': {'code': '32.73.01', 'name': 'Sukasari'},
          'village': {'code': '32.73.01.1001', 'name': 'Gegerkalong'},
        },
      });
      expect(rec.formatted, 'Jl. Melati No. 9, RT 03/RW 05, Gegerkalong, Kec. Sukasari, Kota Bandung, Jawa Barat 40111');
    });
  });

  group('Google Auth & Admin Access Tests', () {
    test('Google user with admin role has admin privileges', () {
      final user = UserModel.fromJson({
        'id': 'u_admin_1',
        'username': 'admin_google',
        'email': 'admin.mihanstore@gmail.com',
        'name': 'Admin Google',
        'role': 'admin',
        'googleLinked': true,
      }, isGoogle: true);

      expect(user.isAdmin, isTrue);
      expect(user.canAccessAdmin, isTrue);
      expect(user.isGoogle, isTrue);
      expect(user.role, 'admin');
    });

    test('Google user with customer role is denied admin privileges', () {
      final user = UserModel.fromJson({
        'id': 'u_cust_1',
        'username': 'customer_google',
        'email': 'customer@gmail.com',
        'name': 'Customer Google',
        'role': 'customer',
        'googleLinked': true,
      }, isGoogle: true);

      expect(user.isAdmin, isFalse);
      expect(user.canAccessAdmin, isFalse);
      expect(user.isGoogle, isTrue);
    });

    test('Regular customer without admin role is denied admin privileges', () {
      final user = UserModel.fromJson({
        'id': 'u_reg_1',
        'username': 'pelanggan_biasa',
        'email': 'pelanggan@example.com',
        'name': 'Pelanggan Biasa',
        'role': 'customer',
        'googleLinked': false,
      });

      expect(user.isAdmin, isFalse);
      expect(user.canAccessAdmin, isFalse);
      expect(user.isGoogle, isFalse);
    });

    test('Configured ADMIN_EMAILS from .env receive admin access when Google authenticated', () {
      final user1 = UserModel.fromJson({
        'id': 'u_admin_ikhsan',
        'username': 'admin_ikhsan',
        'email': ApiConfig.adminEmails.first,
        'name': 'Ikhsan Sumaila',
        'role': 'customer',
        'googleLinked': true,
      }, isGoogle: true);

      final user2 = UserModel.fromJson({
        'id': 'u_admin_qomariah',
        'username': 'admin_qomariah',
        'email': ApiConfig.adminEmails.last,
        'name': 'Qomariah Akmala',
        'role': 'customer',
        'googleLinked': true,
      }, isGoogle: true);

      expect(user1.isAdmin, isTrue);
      expect(user1.canAccessAdmin, isTrue);
      expect(user2.isAdmin, isTrue);
      expect(user2.canAccessAdmin, isTrue);
    });
  });
}
