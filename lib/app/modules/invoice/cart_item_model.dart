class CartItemModel {
  String name;
  int qty;
  int price;

  CartItemModel({required this.name, required this.qty, required this.price});

  int get total => qty * price;
}
