import 'package:flutter/material.dart';

class OrdersPage extends StatelessWidget {
  OrdersPage({super.key});
  final tabs = const ['All', 'On Delivery', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          leading: const SizedBox(),
          bottom: TabBar(tabs: [for (final t in tabs) Tab(text: t)]),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(statusFilter: null),
            _OrdersList(statusFilter: 'On Delivery'),
            _OrdersList(statusFilter: 'Completed'),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            // --- PERUBAHAN DI SINI ---
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrackOrderPage()),
              );
            },
            // --- AKHIR PERUBAHAN ---
            child: const Text('TRACK ORDER'),
          ),
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({this.statusFilter});
  final String? statusFilter;

  @override
  Widget build(BuildContext context) {
    final orders = _mockOrders
        .where((o) => statusFilter == null || o.status == statusFilter)
        .toList();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemBuilder: (_, i) => _OrderCard(orders[i]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: orders.length,
    );
  }
}

class OrderData {
  final String id;
  final String status;
  final List<String> steps;
  OrderData(this.id, this.status, this.steps);
}

final _mockOrders = <OrderData>[
  OrderData('#0012345', 'On Delivery', [
    'Order Placed',
    'Order Confirmed',
    'Your Order On Delivery by Courier',
    'Order Delivered',
  ]),
  OrderData('#0012346', 'Completed', [
    'Order Placed',
    'Order Confirmed',
    'Your Order On Delivery by Courier',
    'Order Delivered',
  ]),
];

class _OrderCard extends StatelessWidget {
  const _OrderCard(this.data);
  final OrderData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Order ID ${data.id}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  data.status,
                  style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < data.steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    // Logika untuk menampilkan status progres
                    (data.status == 'On Delivery' && i <= 2) ||
                            (data.status == 'Completed' && i <= 3)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: (data.status == 'On Delivery' && i <= 2) ||
                            (data.status == 'Completed' && i <= 3)
                        ? cs.primary
                        : Theme.of(context).textTheme.bodySmall!.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(data.steps[i])),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

//==================================================================
// --- HALAMAN BARU UNTUK TRACK ORDER ---
//==================================================================
class TrackOrderPage extends StatelessWidget {
  const TrackOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: Stack(
        children: [
          // 1. Placeholder Peta (Tampilan Saja)
          Image.network(
            'https://images.prd.k8s.shop.digital.gob.es/2022-09-12_static-map-with-markers-and-route.png',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            // Menampilkan loading indicator saat gambar peta dimuat
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            // Menampilkan placeholder jika gambar gagal dimuat
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(
                    Icons.map_outlined,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),

          // 2. Kartu Info Driver di Bagian Bawah
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Avatar Driver
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    
                    // Info Driver
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'James King', // Nama dari gambar
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID 2445556', // ID dari gambar
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    
                    // Tombol Telepon
                    IconButton(
                      onPressed: () {
                        // Tampilan saja, tidak ada fungsi
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulasi menelepon driver...')),
                        );
                      },
                      icon: const Icon(Icons.call_outlined),
                      color: Theme.of(context).colorScheme.primary,
                      iconSize: 28,
                    ),
                    const SizedBox(width: 8),
                    
                    // Tombol Chat
                    IconButton(
                      onPressed: () {
                        // Tampilan saja, tidak ada fungsi
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Simulasi membuka chat driver...')),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      color: Theme.of(context).colorScheme.primary,
                      iconSize: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}