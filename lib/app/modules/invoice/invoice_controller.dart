import 'package:get/get.dart';

import 'cart_item_model.dart';

class InvoiceController extends GetxController {
  var customerName = ''.obs;
  var items = <CartItemModel>[].obs;

  void addItem(CartItemModel item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  int get total => items.fold(0, (sum, item) => sum + item.total);

  void clear() {
    items.clear();
  }
}
