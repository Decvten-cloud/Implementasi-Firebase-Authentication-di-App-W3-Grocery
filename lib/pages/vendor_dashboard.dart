import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class VendorDashboard extends StatefulWidget {
  const VendorDashboard({super.key});

  @override
  State<VendorDashboard> createState() => _VendorDashboardState();
}

class VendorProduct {
  String id;
  String name;
  String img;
  double price;
  int stock;

  VendorProduct({
    required this.id,
    required this.name,
    required this.img,
    required this.price,
    required this.stock,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'img': img,
    'price': price,
    'stock': stock,
  };

  factory VendorProduct.fromJson(Map<String, dynamic> j) => VendorProduct(
    id: j['id'] as String,
    name: j['name'] as String,
    img: j['img'] as String,
    price: (j['price'] as num).toDouble(),
    stock: (j['stock'] as num).toInt(),
  );
}

class _VendorDashboardState extends State<VendorDashboard> {
  // use timestamp-based ids to avoid extra dependency
  List<VendorProduct> _products = [];
  String _vendorKey = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    // Use currently logged-in email if available
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'vendor_demo@example.com';
    _vendorKey = email;
    final saved = prefs.getString('vendor_\${_vendorKey}_products');
    if (saved != null) {
      final arr = jsonDecode(saved) as List;
      setState(() {
        _products = arr.map((e) => VendorProduct.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_products.map((p) => p.toJson()).toList());
    await prefs.setString('vendor_\${_vendorKey}_products', json);
  }

  Future<void> _addProduct() async {
    final nameCtl = TextEditingController();
    final imgCtl = TextEditingController();
    final priceCtl = TextEditingController();
    final stockCtl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: imgCtl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              TextField(
                controller: priceCtl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockCtl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final name = nameCtl.text.trim();
    final img = imgCtl.text.trim().isEmpty
        ? kProducts.first.img
        : imgCtl.text.trim();
    final price = double.tryParse(priceCtl.text.trim()) ?? 0.0;
    final stock = int.tryParse(stockCtl.text.trim()) ?? 0;
    final p = VendorProduct(
      id: id,
      name: name,
      img: img,
      price: price,
      stock: stock,
    );
    setState(() => _products.add(p));
    await _saveProducts();
  }

  Future<void> _editStock(VendorProduct p) async {
    final ctl = TextEditingController(text: p.stock.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit stock'),
        content: TextField(controller: ctl, keyboardType: TextInputType.number),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final val = int.tryParse(ctl.text.trim()) ?? p.stock;
    setState(() => p.stock = val);
    await _saveProducts();
  }

  Future<void> _deleteProduct(VendorProduct p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete ${p.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _products.removeWhere((x) => x.id == p.id));
    await _saveProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Dashboard')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (c, i) {
          final p = _products[i];
          return Card(
            child: ListTile(
              leading: SizedBox(
                width: 64,
                height: 64,
                child: Image.network(
                  p.img,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
              title: Text(p.name),
              subtitle: Text(
                '\$${p.price.toStringAsFixed(2)} • Stock: ${p.stock}',
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'stock',
                    child: Text('Edit stock'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (v) {
                  if (v == 'stock') _editStock(p);
                  if (v == 'delete') _deleteProduct(p);
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}
