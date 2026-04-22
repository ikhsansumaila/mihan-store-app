import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'cart_item_model.dart';
import 'invoice_controller.dart';
import 'invoice_service.dart';

class InvoicePage extends StatelessWidget {
  final c = Get.put(InvoiceController());

  final nameC = TextEditingController();
  final productC = TextEditingController();
  final qtyC = TextEditingController();
  final priceC = TextEditingController();

  InvoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// CUSTOMER
            TextField(
              decoration: InputDecoration(labelText: "Customer"),
              onChanged: (v) => c.customerName.value = v,
            ),

            SizedBox(height: 16),

            /// INPUT ITEM
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: productC,
                    decoration: InputDecoration(labelText: "Produk"),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: qtyC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Qty"),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: priceC,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: "Harga"),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    c.addItem(
                      CartItemModel(
                        name: productC.text,
                        qty: int.parse(qtyC.text),
                        price: int.parse(priceC.text),
                      ),
                    );
                    productC.clear();
                    qtyC.clear();
                    priceC.clear();
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            /// LIST ITEM
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: c.items.length,
                  itemBuilder: (_, i) {
                    final item = c.items[i];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text("${item.qty} x ${item.price} = ${item.total}"),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => c.removeItem(i),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// TOTAL
            Obx(
              () => Text(
                "TOTAL: Rp ${c.total}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 10),

            /// BUTTONS
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    child: Text("Preview PDF"),
                    onPressed: () async {
                      await InvoiceService.generateAndPreview(c);
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    child: Text("Kirim WhatsApp"),
                    onPressed: () async {
                      await InvoiceService.generateAndShare(c);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
