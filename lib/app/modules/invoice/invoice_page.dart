import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/currency_format.dart';
import '../../utils/currency_input_formatter.dart';
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
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: InputDecoration(labelText: "Harga", prefixText: "Rp "),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    c.addItem(
                      CartItemModel(
                        name: productC.text,
                        qty: int.tryParse(qtyC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
                        price: int.tryParse(priceC.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
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
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -4),
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.name, style: TextStyle(fontSize: 16)),
                      subtitle: Text(
                        "${item.qty} x ${CurrencyFormat.convertToIdr(item.price)} = ${CurrencyFormat.convertToIdr(item.total)}",
                        style: TextStyle(fontSize: 14),
                      ),
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
                "TOTAL: ${CurrencyFormat.convertToIdr(c.total)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 10),

            /// CHECKBOX LUNAS
            Obx(
              () => CheckboxListTile(
                title: Text("Pembayaran Sudah Lunas?"),
                value: c.isLunas.value,
                onChanged: (val) {
                  if (val != null) c.isLunas.value = val;
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),

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
