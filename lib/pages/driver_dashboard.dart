import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('orders');
    if (raw == null) return;
    try {
      final arr = jsonDecode(raw) as List;
      setState(() {
        _orders = arr
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_orders.map((o) => o.toJson()).toList());
    await prefs.setString('orders', json);
  }

  Future<void> _updateStatus(Order o, String status) async {
    setState(() => o.status = status);
    await _saveOrders();
  }

  @override
  Widget build(BuildContext context) {
    final pending = _orders.where((o) => o.status != 'Completed').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: pending.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Pending Orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All deliveries are completed!',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (c, i) {
                final o = pending[i];
                final timeStr = o.timestamp.toString().split(
                  '.',
                )[0]; // HH:mm:ss
                final itemCount = o.items.fold<int>(
                  0,
                  (sum, item) => sum + item.qty,
                );
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      'Order #${o.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text('Customer: ${o.customerName}'),
                        Text('Items: $itemCount • Status: ${o.status}'),
                        Text(
                          'Address: ${o.address ?? 'N/A'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Time: $timeStr',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'pickup')
                          await _updateStatus(o, 'On Delivery');
                        if (v == 'complete')
                          await _updateStatus(o, 'Completed');
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'pickup',
                          child: Text('Mark On Delivery'),
                        ),
                        const PopupMenuItem(
                          value: 'complete',
                          child: Text('Mark Completed'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: pending.length,
            ),
      floatingActionButton: null,
    );
  }
}
