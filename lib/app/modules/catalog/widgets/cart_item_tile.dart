import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/cart_model.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/shop_format.dart';
import '../controllers/cart_controller.dart';

class CartItemTile extends StatelessWidget {
  final CartLine item;
  final CartController cart;

  const CartItemTile({super.key, required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = cart.busyProductId.value == item.productId;
      return Opacity(
        opacity: item.available ? 1 : 0.7,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _image(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  CartItemPricing(item: item, cart: cart),
                  if (!item.available)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Tidak tersedia',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.available)
                        _QtyControl(item: item, busy: busy, onSet: (q) => cart.setQty(item.productId, q))
                      else
                        Text('x${item.qty}', style: const TextStyle(color: AppColors.textLight)),
                      const Spacer(),
                      Text(
                        rupiah(item.lineTotal),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: item.available ? AppColors.primaryPurple : AppColors.textLight,
                          decoration: item.available ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : () => cart.removeItem(item.productId),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Hapus', style: TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _image() {
    final url = item.imageUrl;
    final fallback = Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: AppColors.imageGradient)),
      child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
    );
    if (url == null) return fallback;
    return Image.network(url, fit: BoxFit.cover, errorBuilder: (context, error, stack) => fallback);
  }
}

/// Penanda harga per baris: harga efektif per satuan, info grosir (hemat), petunjuk jenjang berikutnya,
/// dan "Harga berubah" bila harga sekarang berbeda dari yang terakhir dilihat pelanggan.
class CartItemPricing extends StatelessWidget {
  final CartLine item;
  final CartController cart;

  const CartItemPricing({super.key, required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 12, color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(
            text: perUnit(item.unitPrice, item.unit),
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          if (item.tierMinQty != null && item.baseUnitPrice > item.unitPrice)
            TextSpan(
              text: '  ${perUnit(item.baseUnitPrice, item.unit)}',
              style: const TextStyle(color: AppColors.textLight, decoration: TextDecoration.lineThrough),
            ),
        ]), style: small),
        if (item.tierMinQty != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Wrap(spacing: 4, runSpacing: 4, children: [
              _chip(tierNote(item.tierMinQty), Colors.green.shade100, Colors.green.shade800),
              if (item.savings > 0) _chip('hemat ${rupiah(item.savings)}', Colors.green.shade50, Colors.green.shade700),
            ]),
          ),
        if (item.available && item.nextTier != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              'Tambah ${item.nextTier!.moreQty} lagi untuk harga ${perUnit(item.nextTier!.unitPrice, item.unit)}',
              style: const TextStyle(fontSize: 11.5, color: AppColors.primaryPurple),
            ),
          ),
        if (item.priceChanged)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Harga berubah: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: 'dari ${rupiah(item.previousUnitPrice)} menjadi ${perUnit(item.unitPrice, item.unit)} ',
                    ),
                  ]),
                  style: TextStyle(fontSize: 11.5, color: Colors.brown.shade900),
                ),
                Obx(() => InkWell(
                      onTap: cart.acking.value ? null : cart.ackPrices,
                      child: Text(
                        'Mengerti',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          color: Colors.brown.shade900,
                        ),
                      ),
                    )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
      );
}

class _QtyControl extends StatefulWidget {
  final CartLine item;
  final bool busy;
  final ValueChanged<int> onSet;

  const _QtyControl({required this.item, required this.busy, required this.onSet});

  @override
  State<_QtyControl> createState() => _QtyControlState();
}

class _QtyControlState extends State<_QtyControl> {
  late final TextEditingController ctrl = TextEditingController(text: '${widget.item.qty}');
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(() {
      if (!focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant _QtyControl old) {
    super.didUpdateWidget(old);
    if (old.item.qty != widget.item.qty) ctrl.text = '${widget.item.qty}';
  }

  @override
  void dispose() {
    ctrl.dispose();
    focus.dispose();
    super.dispose();
  }

  void _commit() {
    final n = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (n == null || n == widget.item.qty) {
      ctrl.text = '${widget.item.qty}';
      return;
    }
    widget.onSet(n.clamp(0, 999));
  }

  Widget _btn(IconData icon, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 16, color: onTap == null ? Colors.grey.shade400 : AppColors.textDark),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final q = widget.item.qty;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(Icons.remove, widget.busy || q <= 1 ? null : () => widget.onSet(q - 1)),
          SizedBox(
            width: 40,
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              enabled: !widget.busy,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              onSubmitted: (_) => _commit(),
            ),
          ),
          _btn(Icons.add, widget.busy || q >= 999 ? null : () => widget.onSet(q + 1)),
        ],
      ),
    );
  }
}
