import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class ProductService {
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: ApiConfig.timeoutDuration);

  Future<List<ProductModel>> fetchProducts() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.products}');
      final request = await _client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
            const Duration(seconds: ApiConfig.timeoutDuration),
          );

      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is List) {
        return decoded
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.categories}');
      final request = await _client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
            const Duration(seconds: ApiConfig.timeoutDuration),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is List) {
        final list = decoded
            .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
            .toList();
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
