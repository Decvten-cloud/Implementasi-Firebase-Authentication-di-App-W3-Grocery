import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'category_page.dart';
import '../widgets/common_widgets.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  final Map<String, int> cart;
  final Set<String> fav;
  final Function(dynamic) onAdd;
  final Function(dynamic) onFav;
  final Function(dynamic) onOpenDetail;
  final VoidCallback? onToggleDark;

  const HomePage({
    super.key,
    required this.cart,
    required this.fav,
    required this.onAdd,
    required this.onFav,
    required this.onOpenDetail,
    this.onToggleDark,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? selectedCategory;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Product> vendorProducts = [];

  @override
  void initState() {
    super.initState();
    _loadVendorProducts();
  }

  Future<void> _loadVendorProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final vendorEmails = <String>[];

      // Collect all vendor emails that have products
      for (final key in prefs.getKeys()) {
        if (key.startsWith('vendor_') && key.endsWith('_products')) {
          // Extract email from key format: vendor_<email>_products
          final email = key
              .replaceFirst('vendor_', '')
              .replaceFirst('_products', '');
          vendorEmails.add(email);
        }
      }

      final products = <Product>[];
      for (final email in vendorEmails) {
        final raw = prefs.getString('vendor_${email}_products');
        if (raw != null) {
          try {
            final arr = jsonDecode(raw) as List;
            for (final item in arr) {
              final map = item as Map<String, dynamic>;
              products.add(
                Product(
                  map['id'] as String,
                  map['name'] as String,
                  map['img'] as String? ?? 'https://via.placeholder.com/150',
                  (map['price'] as num).toDouble(),
                  (map['price'] as num).toDouble(), // oldPrice same as price
                  'Vendor',
                ),
              );
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() => vendorProducts = products);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => searchQuery = query);
    });
  }

  List<Product> get filteredProducts {
    // Merge default products with vendor products
    List<Product> products = [...kProducts, ...vendorProducts];

    if (selectedCategory != null && selectedCategory != 'Vendor') {
      products = products.where((p) => p.tag == selectedCategory).toList();
    } else if (selectedCategory == 'Vendor') {
      products = products.where((p) => p.tag == 'Vendor').toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      products = products
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.tag.toLowerCase().contains(q),
          )
          .toList();
    }

    return products;
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = selectedCategory == category ? null : category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final promos = kPromoImages;

    return Scaffold(
      appBar: null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // ✅ Search + Avatar (RIGHT side)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SearchBox(
                  hint: 'Search for products',
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfilePage(
                        onOpenOrders: () {
                          // ✅ Hook this later to real Orders page if needed
                          debugPrint("Open Orders tapped from Profile");
                        },
                        onToggleDark: widget.onToggleDark,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: const NetworkImage(
                    'https://i.pravatar.cc/150?img=5',
                  ),
                  backgroundColor: cs.primaryContainer,
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ✅ Promo carousel
          AspectRatio(
            aspectRatio: 16 / 7,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.92),
              itemCount: promos.length,
              itemBuilder: (ctx, i) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  promos[i],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ImgBroken(),
                  loadingBuilder: (c, child, progress) =>
                      progress == null ? child : const ImgPlaceholder(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ✅ Categories
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final category = kCategories[i];
                final name = category.$1;
                final icon = category.$2;
                final color = category.$3;
                final items = category.$4;
                final isSelected = selectedCategory == name;

                return GestureDetector(
                  onTap: () {
                    _selectCategory(name);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryPage(
                          category: name,
                          cart: widget.cart,
                          fav: widget.fav,
                          onAdd: widget.onAdd,
                          onFav: widget.onFav,
                          onOpenDetail: widget.onOpenDetail,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isSelected
                              ? color.withOpacity(.3)
                              : color.withOpacity(.22),
                          isSelected
                              ? color.withOpacity(.15)
                              : color.withOpacity(.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: isSelected
                          ? Border.all(color: color.withOpacity(.5), width: 2)
                          : null,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: color),
                        const Spacer(),
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w800,
                          ),
                        ),
                        Text(
                          items,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? cs.primary
                                : cs.onSurface.withOpacity(.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ✅ Products grid header
          Row(
            children: [
              Text(
                selectedCategory ?? 'Favourite Products',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 8),
              Text(
                '(${filteredProducts.length} items)',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ✅ Products grid
          ProductGrid(
            products: filteredProducts,
            fav: widget.fav,
            onAdd: widget.onAdd,
            onFav: widget.onFav,
            onOpenDetail: widget.onOpenDetail,
          ),

          const SizedBox(height: 18),

          const SizedBox(height: 6),
          Text(
            'Other Login w3Grocery package',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),

          // ✅ Vendor & Driver login cards
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Use named route so the app-level login handler is used
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.teal[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'W3 Vendor',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/login');
                          },
                          child: const Text('Click Now'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.lightBlue[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'W3 Driver',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/login');
                          },
                          child: const Text('Click Now'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Set<String> fav;
  final Function(dynamic) onAdd;
  final Function(dynamic) onFav;
  final Function(dynamic) onOpenDetail;

  const ProductGrid({
    super.key,
    required this.products,
    required this.fav,
    required this.onAdd,
    required this.onFav,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return ProductCard(
          p: p,
          inFav: fav.contains(p.id),
          onFav: () => onFav(p),
          onAdd: () => onAdd(p),
          onOpen: () => onOpenDetail(p),
        );
      },
    );
  }
}
