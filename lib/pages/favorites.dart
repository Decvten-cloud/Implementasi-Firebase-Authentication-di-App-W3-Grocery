// lib/pages/favorites.dart
import 'package:flutter/material.dart';
import '../models/product.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    super.key,
    required this.products,            // List produk yang ditampilkan
    required this.fav,                 // Set productId yang difavoritkan
    required this.cart,                // Map productId -> qty di keranjang
    required this.onFav,               // toggle favorit
    required this.onAdd,               // +1 ke cart
    required this.onRemove,            // -1 dari cart
    required this.onOpenDetail,        // buka halaman detail
  });

  final List<Product> products;
  final Set<String> fav;
  final Map<String, int> cart;
  final void Function(Product) onFav;
  final void Function(Product) onAdd;
  final void Function(Product) onRemove;
  final void Function(Product) onOpenDetail;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ambil hanya produk yang ada di favorit
    var items = widget.products.where((p) => widget.fav.contains(_idOf(p))).toList();

    // filter pencarian
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      items = items.where((p) => _nameOf(p).toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Favourite')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Search bar =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Search here!',
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Popular Deals',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(height: 8),

          // ===== Grid =====
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('Belum ada produk favorit',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      // Lebih tinggi supaya anti “BOTTOM OVERFLOWED…”
                      childAspectRatio: 0.68,
                    ),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final p = items[i];
                      final id = _idOf(p);
                      final isFav = widget.fav.contains(id);
                      final qty = widget.cart[id] ?? 0;

                      return Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0.6,
                        child: InkWell(
                          onTap: () => widget.onOpenDetail(p),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== Gambar + heart + badge =====
                              Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 16 / 11,
                                    child: Image.network(
                                      _imageOf(p),
                                      fit: BoxFit.cover,
                                      loadingBuilder: (c, child, ev) =>
                                          ev == null
                                              ? child
                                              : const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  ),
                                                ),
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                        color: Color(0xFFCFD8DC),
                                        child: Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    left: 8,
                                    top: 8,
                                    child: GestureDetector(
                                      onTap: () => setState(() => widget.onFav(p)),
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          isFav ? Icons.favorite : Icons.favorite_border,
                                          size: 18,
                                          color: isFav ? Colors.pink : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Transform.rotate(
                                      angle: -0.35, // efek pita
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE11D48),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          '5% OFF',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // ===== Info + harga + rating + CTA =====
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nameOf(p),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text('\$ ${_priceStrOf(p)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800)),
                                        const Spacer(),
                                        const Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        const SizedBox(width: 2),
                                        const Text('(243)',
                                            style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // ===== Add to cart / Stepper =====
                                    if (qty == 0)
                                      SizedBox(
                                        height: 38,
                                        width: double.infinity,
                                        child: FilledButton.tonal(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: cs.primaryContainer,
                                            foregroundColor: cs.onPrimaryContainer,
                                          ),
                                          onPressed: () {
                                            widget.onAdd(p);
                                            setState(() {});
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Added to cart')),
                                            );
                                          },
                                          child: const Text('Add to cart',
                                              style: TextStyle(fontSize: 13)),
                                        ),
                                      )
                                    else
                                      _QtyStepper(
                                        qty: qty,
                                        onInc: () {
                                          widget.onAdd(p);
                                          setState(() {});
                                        },
                                        onDec: () {
                                          widget.onRemove(p);
                                          setState(() {});
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ===== Helpers agar kompatibel dg berbagai nama field product tim =====
  String _idOf(Product p) {
    final d = p as dynamic;
    return (d.id ?? d.productId ?? d.code ?? '') as String;
  }

  String _nameOf(Product p) {
    final d = p as dynamic;
    return (d.name ?? d.title ?? '').toString();
  }

  String _imageOf(Product p) {
    final d = p as dynamic;
    return (d.img ?? d.imageUrl ?? d.image ?? d.photo ?? '') as String;
  }

  String _priceStrOf(Product p) {
    final d = p as dynamic;
    final num v = (d.price ?? d.amount ?? 0) as num;
    return v.toStringAsFixed(1);
  }
}

/// Stepper (- qty +) ala desain
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onInc,
    required this.onDec,
  });

  final int qty;
  final VoidCallback onInc;
  final VoidCallback onDec;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          _RoundIconBtn(icon: Icons.remove, onTap: onDec),
          const Spacer(),
          Text('$qty',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const Spacer(),
          _RoundIconBtn(icon: Icons.add, onTap: onInc),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  const _RoundIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 32,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
