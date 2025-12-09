import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../widgets/common_widgets.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    super.key,
    required this.cart,
    required this.onAdd,
    required this.onRemove,
    this.onCheckoutSuccess,
  });

  final Map<String, int> cart;
  final void Function(Product) onAdd;
  final void Function(Product) onRemove;
  final VoidCallback? onCheckoutSuccess;

  @override
  Widget build(BuildContext context) {
    final items = kProducts
        .where((p) => cart[p.id] != null && cart[p.id]! > 0)
        .toList();
    final subtotal = items.fold<double>(
      0,
      (s, p) => s + p.price * cart[p.id]!.toDouble(),
    );
    final tax = subtotal * 0.02;
    final total = subtotal - 1.08 + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Shopping Cart')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          for (final p in items)
            _CartRow(
              p: p,
              qty: cart[p.id]!,
              onInc: () => onAdd(p),
              onDec: () => onRemove(p),
            ),
          const SizedBox(height: 14),
          _SummaryLine(label: 'Subtotal', value: subtotal),
          _SummaryLine(label: 'TAX (2%)', value: -1.08 + tax),
          const Divider(height: 24),
          _SummaryLine(label: 'Total', value: total, bold: true),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sell_outlined),
            label: const Text('Apply Promotion Code    2 Promos'),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutPage(
                  onSuccess: onCheckoutSuccess,
                  cart: cart,
                  items: items,
                ),
              ),
            );
          },
          child: const Text('CHECKOUT'),
        ),
      ),
    );
  }
}

// -------------------- CART ROW --------------------
class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.p,
    required this.qty,
    required this.onInc,
    required this.onDec,
  });
  final Product p;
  final int qty;
  final VoidCallback onInc, onDec;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 62,
          height: 62,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              p.img,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, progress) =>
                  progress == null ? child : const ImgPlaceholder(),
              errorBuilder: (c, e, s) => const ImgBroken(),
            ),
          ),
        ),
        title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(p.tag),
        trailing: SizedBox(
          width: 130,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              QtyBtn(icon: Icons.remove, onTap: onDec),
              Text('$qty', style: const TextStyle(fontWeight: FontWeight.w800)),
              QtyBtn(icon: Icons.add, onTap: onInc),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- SUMMARY LINE --------------------
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          label,
          style: bold
              ? t.titleMedium!.copyWith(fontWeight: FontWeight.w800)
              : t.bodyMedium,
        ),
        const Spacer(),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: bold
              ? t.titleMedium!.copyWith(fontWeight: FontWeight.w900)
              : t.bodyMedium,
        ),
      ],
    );
  }
}

// -------------------- CHECKOUT PAGE (FINAL, ALL PAYMENT TYPES SAME FORM) --------------------
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    this.onSuccess,
    required this.cart,
    required this.items,
  });

  final VoidCallback? onSuccess;
  final Map<String, int> cart;
  final List<Product> items;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int step = 1;
  final _formKey = GlobalKey<FormState>();

  // Address fields
  String? fullName, email, phone, address, zip, city, country;
  bool saveAddress = true;

  // Payment
  int selectedPayment = 2; // 1=COD, 2=CreditCard, 3=Paypal
  bool saveCard = true;

  // -------------------- Input Style --------------------
  InputDecoration _inputStyle(String label, String hint) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.always,
      label: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 32),
            Expanded(child: _buildStepContent()),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: step > 1
                    ? () => setState(() => step--)
                    : () => Navigator.pop(context),
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  if (step < 3) {
                    setState(() => step++);
                  } else {
                    // Notify parent (e.g., RootShell) that checkout succeeded
                    try {
                      widget.onSuccess?.call();
                    } catch (_) {}
                    // Create a richer order record with items and address, then save to SharedPreferences
                    (() async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final raw = prefs.getString('orders');
                        final list = raw == null
                            ? <Map<String, dynamic>>[]
                            : List<Map<String, dynamic>>.from(jsonDecode(raw));

                        final id = DateTime.now().millisecondsSinceEpoch
                            .toString();

                        // Build order items from cart
                        final orderItems = <OrderItemDetail>[];
                        var totalAmount = 0.0;
                        for (final product in widget.items) {
                          final qty = widget.cart[product.id] ?? 0;
                          if (qty > 0) {
                            orderItems.add(
                              OrderItemDetail(
                                productId: product.id,
                                productName: product.name,
                                qty: qty,
                                price: product.price,
                              ),
                            );
                            totalAmount += product.price * qty;
                          }
                        }

                        // Create order with full details
                        final order = Order(
                          id: id,
                          customerName: fullName ?? 'Guest',
                          customerEmail: email ?? '',
                          status: 'Pending',
                          items: orderItems,
                          vendorId: '', // TODO: multi-vendor support
                          driverId: '',
                          timestamp: DateTime.now(),
                          address: '$address, $city, $zip, $country',
                          totalAmount: totalAmount,
                        );

                        list.add(order.toJson());
                        await prefs.setString('orders', jsonEncode(list));
                      } catch (e) {
                        // ignore
                      }
                    })();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PaymentSuccessPage(amount: 55),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                child: Text(step == 3 ? 'Finish' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------- STEP INDICATOR --------------------
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _stepCircle('Delivery', 1),
        _lineConnector(1),
        _stepCircle('Address', 2),
        _lineConnector(2),
        _stepCircle('Payment', 3),
      ],
    );
  }

  Widget _stepCircle(String label, int index) {
    bool isActive = step >= index;
    bool isCurrent = step == index;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isActive ? Colors.green : Colors.grey.shade300,
          child: Icon(
            isActive
                ? (isCurrent ? Icons.circle : Icons.check)
                : Icons.circle_outlined,
            color: Colors.white,
            size: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _lineConnector(int index) {
    return Expanded(
      child: Container(
        height: 2,
        color: step > index ? Colors.green : Colors.grey.shade300,
      ),
    );
  }

  // -------------------- STEP CONTENT --------------------
  Widget _buildStepContent() {
    if (step == 1 || step == 2) {
      return Form(
        key: _formKey,
        child: ListView(
          children: [
            // ---- Form Fields ----
            TextFormField(
              decoration: _inputStyle('Full Name', 'Enter your name'),
              onChanged: (v) => fullName = v,
            ),
            const SizedBox(height: 32),
            TextFormField(
              decoration: _inputStyle('Email Address', 'example@mail.com'),
              onChanged: (v) => email = v,
            ),
            const SizedBox(height: 32),
            TextFormField(
              decoration: _inputStyle('Phone', 'Enter phone number'),
              onChanged: (v) => phone = v,
            ),
            const SizedBox(height: 32),
            TextFormField(
              decoration: _inputStyle('Address', 'Type your home address'),
              onChanged: (v) => address = v,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: _inputStyle('Zip Code', 'Enter here'),
                    onChanged: (v) => zip = v,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: _inputStyle('City', 'Enter here'),
                    onChanged: (v) => city = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            DropdownButtonFormField<String>(
              decoration: _inputStyle('Country', 'Select your country'),
              items: const [
                DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
                DropdownMenuItem(value: 'Malaysia', child: Text('Malaysia')),
                DropdownMenuItem(value: 'Singapore', child: Text('Singapore')),
              ],
              onChanged: (v) => setState(() => country = v),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: saveAddress,
              onChanged: (v) => setState(() => saveAddress = v ?? true),
              title: const Text('Save shipping address'),
            ),
          ],
        ),
      );
    } else {
      // ---- Step 3: Payment ----
      return ListView(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _paymentOption(Icons.local_shipping, 'Cash On Delivery', 1),
              _paymentOption(Icons.credit_card, 'Credit Card', 2),
              _paymentOption(Icons.account_balance_wallet, 'Paypal', 3),
            ],
          ),
          const SizedBox(height: 20),
          _creditCardForm(), // sama untuk semua metode
        ],
      );
    }
  }

  Widget _paymentOption(IconData icon, String label, int value) {
    final isSelected = selectedPayment == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPayment = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.green : Colors.grey),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.green : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- PAYMENT FORM (SAME FOR ALL METHODS) --------------------
  Widget _creditCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Card(
          color: Colors.blue.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'A Bank',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  '**** **** **** ****',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CARD HOLDER\nLouis Anderson',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      'VALID THRU\n08/26',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          decoration: _inputStyle('Card Holder Name', 'Enter name'),
        ),
        const SizedBox(height: 32),
        TextFormField(
          decoration: _inputStyle('Card Number', '0000 0000 0000 0000'),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: _inputStyle('Month/Year', 'MM/YY'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(decoration: _inputStyle('CVV', '123')),
            ),
          ],
        ),
        const SizedBox(height: 32),
        DropdownButtonFormField<String>(
          decoration: _inputStyle('Country', 'Select your country'),
          items: const [
            DropdownMenuItem(value: 'Indonesia', child: Text('Indonesia')),
            DropdownMenuItem(value: 'Malaysia', child: Text('Malaysia')),
            DropdownMenuItem(value: 'Singapore', child: Text('Singapore')),
          ],
          onChanged: (v) => country = v,
        ),
        CheckboxListTile(
          value: saveCard,
          onChanged: (v) => setState(() => saveCard = v ?? true),
          title: const Text('Save this payment method'),
        ),
      ],
    );
  }
}

// -------------------- PAYMENT SUCCESS PAGE --------------------
class PaymentSuccessPage extends StatelessWidget {
  final double amount;
  const PaymentSuccessPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E7A46),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white,
                child: Icon(Icons.check, color: Color(0xFF1E7A46), size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You've paid: \$${55.toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF1E7A46),
                  size: 16,
                ),
                label: const Text(
                  'Delivery Status',
                  style: TextStyle(
                    color: Color(0xFF1E7A46),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
