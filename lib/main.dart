// FOLDER: lib/main.dart
// (Kode ini sudah diperbaiki dan digabungkan dengan logika state Anda)

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/product.dart';
import 'pages/homepage.dart';
import 'pages/orders.dart';
import 'pages/cart.dart';
import 'pages/favorites.dart';
import 'pages/profile.dart';
import 'pages/product_detail.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'login_driver_vendor.dart';
import 'login_screen.dart' as user_login;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase (reads config from native files on Android/iOS).
    await Firebase.initializeApp();
  } catch (e) {
    // If initialization fails, report to console but continue so app can run in demo mode.
    // On web, you may need to pass FirebaseOptions; if so, set them up separately.
    debugPrint('Firebase initializeApp error: $e');
  }

  runApp(const GroceryApp());
}

class GroceryApp extends StatefulWidget {
  const GroceryApp({super.key});
  @override
  State<GroceryApp> createState() => _GroceryAppState();
}

class _GroceryAppState extends State<GroceryApp> {
  int brandIndex = 0;
  bool dark = false;
  bool _loggedIn = false;

  static const kBrandColors = <Color>[
    Color(0xFF10B981), // green
    Color(0xFF3B82F6), // blue
    Color(0xFFF59E0B), // amber
    Color(0xFFEF4444), // red
    Color(0xFF06B6D4), // cyan
    Color(0xFF8B5CF6), // violet
  ];

  ThemeData _theme(Brightness b) {
    final seed =
        _GroceryAppState.kBrandColors[brandIndex % kBrandColors.length];
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: b == Brightness.dark
          ? const Color(0xFF0E1628)
          : const Color(0xFFF6F7F9),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Grocery',
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      // Launch flow: start with SplashScreen which will navigate to Onboarding.
      // After onboarding uses the named route '/login', the LoginScreen will
      // call the provided onLoginSuccess to flip [_loggedIn] to true and
      // rebuild this widget so the app shows the RootShell.
      home: _loggedIn
          ? RootShell(
              onPickBrand: (i) => setState(() => brandIndex = i),
              onToggleDark: () => setState(() => dark = !dark),
              brandIndex: brandIndex,
              brandColors: _GroceryAppState.kBrandColors,
              dark: dark,
            )
          : const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        // Provide a Login route that shows either the user-login screen
        // (default when no role argument is passed) or the vendor/driver
        // login when an initialRole is provided from the homepage buttons.
        '/login': (ctx) {
          final initialRole = ModalRoute.of(ctx)?.settings.arguments as String?;

          // Shared success handler: mark app logged-in and replace nav stack
          void handleSuccess() {
            setState(() => _loggedIn = true);
            Navigator.of(ctx).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => RootShell(
                  onPickBrand: (i) => setState(() => brandIndex = i),
                  onToggleDark: () => setState(() => dark = !dark),
                  brandIndex: brandIndex,
                  brandColors: _GroceryAppState.kBrandColors,
                  dark: dark,
                ),
              ),
              (route) => false,
            );
          }

          if (initialRole == 'vendor' || initialRole == 'driver') {
            // Use the login widget implemented for vendor/driver flows.
            return LoginScreen(
              onLoginSuccess: handleSuccess,
              initialRole: initialRole,
            );
          }

          // Default: use the regular user login screen (aliased import).
          return user_login.LoginScreen(onLoginSuccess: handleSuccess);
        },
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({
    super.key,
    required this.onPickBrand,
    required this.onToggleDark,
    required this.brandIndex,
    required this.brandColors,
    required this.dark,
  });

  final void Function(int) onPickBrand;
  final VoidCallback onToggleDark;
  final int brandIndex;
  final List<Color> brandColors;
  final bool dark;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;
  // Ini adalah "Single Source of Truth" untuk state aplikasi Anda
  final cart = <String, int>{};
  final fav = <String>{};

  // Fungsi untuk memodifikasi state
  void addToCart(Product p) =>
      setState(() => cart.update(p.id, (v) => v + 1, ifAbsent: () => 1));
  void removeFromCart(Product p) => setState(
    () => cart.update(p.id, (v) => math.max(0, v - 1), ifAbsent: () => 0),
  );
  void toggleFav(Product p) =>
      setState(() => fav.contains(p.id) ? fav.remove(p.id) : fav.add(p.id));

  // Called when adding from the Home page: update state and show a
  // floating notification (SnackBar) to confirm the action.
  void _addFromHome(Product p) {
    // Update cart state
    addToCart(p);

    // Show a floating SnackBar with a small thumbnail and action to open cart
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  p.img,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${p.name} added to cart',
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => setState(() => _tab = 2),
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_tab) {
      case 0:
        return HomePage(
          cart: cart,
          fav: fav,
          // When adding from HomePage, use _addFromHome so we can show
          // a floating confirmation SnackBar.
          onAdd: (p) => _addFromHome(p),
          onFav: (p) => toggleFav(p),
          onOpenDetail: (p) => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                product: p,
                inFav: fav.contains(p.id),
                onFav: () => toggleFav(p),
                onAdd: () => _addFromHome(p),
              ),
            ),
          ),
          onToggleDark: widget.onToggleDark,
        );
      case 1:
        return OrdersPage();
      case 2:
        return CartPage(
          cart: cart,
          onAdd: (p) => addToCart(p),
          onRemove: (p) => removeFromCart(p),
          onCheckoutSuccess: () =>
              setState(() => _tab = 1), // Switch to Orders tab
        );
      case 3:
        return FavoritesPage(
          products: kProducts, // Add the products list
          fav: fav,
          cart: cart,
          onFav: (p) => toggleFav(p),
          onAdd: (p) => addToCart(p),
          onRemove: (p) => removeFromCart(p),
          onOpenDetail: (p) {},
        );
      case 4:
        return ProfilePage(
          onOpenOrders: () => setState(() => _tab = 1),
          onToggleDark: widget.onToggleDark,
        );
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan halaman mana yang butuh AppBar dari RootShell
    final bool showAppBar = _tab == 0 || _tab == 2 || _tab == 3;
    // Tentukan judul berdasarkan tab
    final String title = [
      'Grocery', // Tab 0
      'My Orders', // Tab 1 (Tidak dipakai)
      'My Cart', // Tab 2
      'Favorites', // Tab 3
      'Profile', // Tab 4 (Tidak dipakai)
    ][_tab];

    return Scaffold(
      // Tampilkan AppBar secara kondisional
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.color_lens_rounded),
                  onPressed: () => _openCustomizer(context),
                ),
              ],
            )
          : null, // Sembunyikan AppBar jika tab 1 atau 4
      body: _buildCurrentPage(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _openCustomizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Color',
                    style: Theme.of(ctx).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onToggleDark,
                    icon: Icon(
                      Theme.of(context).brightness == Brightness.dark
                          ? Icons.wb_sunny
                          : Icons.nightlight_round,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(widget.brandColors.length, (i) {
                  final c = widget.brandColors[i];
                  final active = widget.brandIndex == i;
                  return GestureDetector(
                    onTap: () {
                      widget.onPickBrand(i);
                    },
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active
                              ? Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : cs.primary
                              : Colors.transparent,
                          width: active ? 2.5 : 0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 8,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black38
                                : Colors.black26,
                          ),
                        ],
                      ),
                      child: active
                          ? Icon(
                              Icons.check,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.black
                                  : Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
