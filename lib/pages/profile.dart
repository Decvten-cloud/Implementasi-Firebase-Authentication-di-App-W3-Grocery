import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'driver_dashboard.dart';
import 'vendor_dashboard.dart';

// --- IMPORT DIPERBAIKI ---
// (Pastikan path ini benar mengarah ke file splash_screen.dart Anda)
import '../splash_screen.dart';

//==================================================================
// --- 1. MODEL DATA BARU UNTUK REVIEW ---
//==================================================================
class Review {
  final String name;
  final String imageUrl;
  final double rating;
  final String comment;
  final String date;

  const Review({
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// --- DATA DUMMY UNTUK REVIEW SEBELUMNYA ---
final dummyReviews = [
  const Review(
    name: 'Sarah K.',
    imageUrl: 'https://i.pravatar.cc/150?img=47',
    rating: 5.0,
    comment: 'Great service and fast delivery! Everything was fresh.',
    date: '2 days ago',
  ),
  const Review(
    name: 'Mark P.',
    imageUrl: 'https://i.pravatar.cc/150?img=32',
    rating: 4.0,
    comment: 'Good selection of products, but one item was missing.',
    date: '3 days ago',
  ),
  const Review(
    name: 'Emily R.',
    imageUrl: 'https://i.pravatar.cc/150?img=45',
    rating: 5.0,
    comment: 'Love this app! Makes my weekly shopping so much easier.',
    date: '5 days ago',
  ),
];

//==================================================================
// --- 2. HALAMAN PROFILE UTAMA ---
//==================================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onOpenOrders, this.onToggleDark});
  final VoidCallback onOpenOrders;
  final VoidCallback? onToggleDark;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: const SizedBox(),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.apps_rounded),
            onSelected: (value) {
              switch (value) {
                case 'toggle_dark':
                  if (onToggleDark != null) onToggleDark!();
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentsPage()),
                  );
                  break;
                case 'help':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationPage()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'toggle_dark',
                child: Text('Toggle Dark Mode'),
              ),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'help', child: Text('Help & Support')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _UserHeader(),
          const SizedBox(height: 12),
          _MenuTile(
            icon: Icons.receipt_long_rounded,
            text: 'My Orders',
            onTap: onOpenOrders,
          ),
          _MenuTile(
            icon: Icons.account_balance_wallet_rounded,
            text: 'Payments & Wallet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentsPage()),
              );
            },
          ),
          // --- PERUBAHAN DI SINI ---
          // Mengarahkan ke halaman baru, bukan modal
          _MenuTile(
            icon: Icons.reviews_rounded,
            text: 'Ratings & Review',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RatingsAndReviewsPage(),
                ),
              );
            },
          ),
          // --- AKHIR PERUBAHAN ---
          _MenuTile(
            icon: Icons.notifications_active_rounded,
            text: 'Notification',
            trailing: const _Badge(number: 1),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationPage()),
              );
            },
          ),
          _MenuTile(
            icon: Icons.location_on_rounded,
            text: 'Delivery Address',
            onTap: () {
              _showSelectLocationSheet(context);
            },
          ),
          // Vendor/Driver shortcuts
          _MenuTile(
            icon: Icons.storefront_rounded,
            text: 'Vendor Dashboard',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VendorDashboard()),
              );
            },
          ),
          _MenuTile(
            icon: Icons.local_shipping_rounded,
            text: 'Driver Dashboard',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverDashboard()),
              );
            },
          ),
          _MenuTile(
            icon: Icons.article_rounded,
            text: 'Blog & Blog Detail',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlogPage()),
              );
            },
          ),
          const SizedBox(height: 6),
          _MenuTile(
            icon: Icons.logout_rounded,
            text: 'LogOut',
            isDestructive: true,
            onTap: () async {
              // --- FUNGSI LOGOUT ---
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const SplashScreen()),
                (Route<dynamic> route) => false,
              );
              // --- AKHIR FUNGSI LOGOUT ---
            },
          ),
        ],
      ),
    );
  }
}

// (Widget _UserHeader, _MenuTile, _Badge tetap sama)
class _UserHeader extends StatefulWidget {
  const _UserHeader();
  @override
  State<_UserHeader> createState() => _UserHeaderState();
}

class _UserHeaderState extends State<_UserHeader> {
  User? _user;
  String? _savedName;
  String _username = '';
  String _website = '';
  String _bio = '';
  String _accountType = ''; // e.g. 'vendor' or 'driver'

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadSavedName();
    _refreshUser();

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((u) {
      if (mounted) {
        setState(() => _user = u);
        _loadSavedName();
        // When auth state changes, refresh to get latest user data
        _refreshUser();
      }
    });

    // Force a reload after 200ms to ensure everything is loaded
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _loadSavedName();
    });
  }

  Future<void> _loadSavedName() async {
    try {
      final userEmail = _user?.email;
      if (userEmail == null) {
        if (mounted) setState(() => _savedName = null);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final keyBase = 'profile_${userEmail}_';

      // Load saved profile fields
      String? name = prefs.getString('${keyBase}name');
      final username = prefs.getString('${keyBase}username') ?? '';
      final website = prefs.getString('${keyBase}website') ?? '';
      final bio = prefs.getString('${keyBase}bio') ?? '';
      final accountType = prefs.getString('${keyBase}accountType') ?? '';

      print(
        'DEBUG: Loading profile data for $userEmail: name=$name username=$username website=$website bio=${bio.isNotEmpty}',
      );

      // Fallback: if no saved name, use email prefix
      if (name == null || name.isEmpty) {
        name = userEmail.split('@')[0];
        print('DEBUG: No saved name, using email prefix: $name');
      } else {
        print('DEBUG: Using saved full name: $name');
      }

      if (mounted) {
        setState(() {
          _savedName = name;
          _username = username;
          _website = website;
          _bio = bio;
          _accountType = accountType;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading saved name: $e');
    }
  }

  Future<void> _refreshUser() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      if (mounted) {
        setState(() => _user = FirebaseAuth.instance.currentUser);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _savedName ?? _user?.displayName ?? _user?.email ?? 'Guest User';
    final email = _user?.email ?? 'Not signed in';
    final phone = _user?.phoneNumber ?? '';
    final photo = _user?.photoURL;

    // Debug logging
    print(
      'DEBUG Profile: user=${_user?.email}, displayName=$displayName, saved=$_savedName, raw=${_user?.displayName}',
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: photo != null
                    ? NetworkImage(photo)
                    : const NetworkImage('https://i.pravatar.cc/150?img=5'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_username.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '@' + _username,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_website.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _website,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (_accountType.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _accountType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    if (_bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _bio,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
            ],
          ),
          const Divider(color: Colors.white54, height: 20),
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: Colors.white70),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '324002\nUK - 324002',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  _showSelectLocationSheet(context);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.text,
    this.trailing,
    this.isDestructive = false,
    this.onTap,
  });
  final IconData icon;
  final String text;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(
          text,
          style: TextStyle(
            color: isDestructive ? Colors.red : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.number});
  final int number;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ----------------------------------------------
// --- HALAMAN & MODAL ---
// ----------------------------------------------

//==================================================================
// --- 3. HALAMAN BARU: DAFTAR RATING & REVIEW ---
//==================================================================
class RatingsAndReviewsPage extends StatefulWidget {
  const RatingsAndReviewsPage({super.key});

  @override
  State<RatingsAndReviewsPage> createState() => _RatingsAndReviewsPageState();
}

class _RatingsAndReviewsPageState extends State<RatingsAndReviewsPage> {
  // Memulai dengan daftar ulasan palsu
  final List<Review> _reviews = List.from(dummyReviews);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ratings & Review')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          return _ReviewTile(review: _reviews[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Panggil modal _showRatingsSheet
          // Kita 'await' hasilnya (yang mungkin berupa Review baru)
          final newReview = await _showRatingsSheet(context);

          if (newReview != null) {
            // Jika kita mendapatkan review baru, tambahkan ke daftar & refresh UI
            setState(() {
              _reviews.insert(0, newReview); // Tambahkan ke paling atas
            });

            // Tampilkan pesan sukses
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Terima kasih atas ulasan Anda!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: const Icon(Icons.add_comment_rounded),
      ),
    );
  }
}

// --- WIDGET BARU: UNTUK MENAMPILKAN SATU TILE REVIEW ---
class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(review.imageUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            review.date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(review.comment),
          ],
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _websiteController;
  late TextEditingController _bioController;
  bool _loading = false;
  String _accountType = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _websiteController = TextEditingController();
    _bioController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final prefs = await SharedPreferences.getInstance();
      final email = user.email ?? '';
      final keyBase = 'profile_${email}_';

      final name = prefs.getString('${keyBase}name') ?? '';
      final username = prefs.getString('${keyBase}username') ?? '';
      final website = prefs.getString('${keyBase}website') ?? '';
      final bio = prefs.getString('${keyBase}bio') ?? '';
      final accountType = prefs.getString('${keyBase}accountType') ?? '';

      if (mounted) {
        setState(() {
          _nameController.text = name;
          _usernameController.text = username;
          _websiteController.text = website;
          _bioController.text = bio;
          _accountType = accountType;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading profile data: $e');
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');
      final prefs = await SharedPreferences.getInstance();
      final email = user.email ?? '';
      final keyBase = 'profile_${email}_';

      await prefs.setString('${keyBase}name', name);
      await prefs.setString(
        '${keyBase}username',
        _usernameController.text.trim(),
      );
      await prefs.setString(
        '${keyBase}website',
        _websiteController.text.trim(),
      );
      await prefs.setString('${keyBase}bio', _bioController.text.trim());
      await prefs.setString('${keyBase}accountType', _accountType);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _loading ? null : _saveProfile,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=5',
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Change profile photo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            enabled: !_loading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
            enabled: !_loading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _websiteController,
            decoration: const InputDecoration(labelText: 'Website'),
            enabled: !_loading,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
            maxLines: 3,
            enabled: !_loading,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accountType == 'vendor'
                      ? Colors.green
                      : null,
                ),
                onPressed: () => setState(() => _accountType = 'vendor'),
                child: Text(
                  _accountType == 'vendor' ? 'Vendor ✓' : 'Vendor Account',
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accountType == 'driver'
                      ? Colors.green
                      : null,
                ),
                onPressed: () => setState(() => _accountType = 'driver'),
                child: Text(
                  _accountType == 'driver' ? 'Driver ✓' : 'Driver Account',
                ),
              ),
            ],
          ),
          TextButton(onPressed: () {}, child: const Text('Create avatar')),
          TextButton(
            onPressed: () {},
            child: const Text('Personal information settings'),
          ),
        ],
      ),
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Today', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildNotificationTile(
            img: 'https://i.pravatar.cc/150?img=12',
            text:
                '@davidjr rmention you in a comment: @joviedan Lol\n"Lorem ipsum dolor sit amet..."',
            time: '5h ago',
          ),
          _buildNotificationTile(
            img: 'https://i.pravatar.cc/150?img=32',
            text: '@henry and 5 others liked your message',
            time: '6h ago',
          ),
          const SizedBox(height: 24),
          Text('This Year', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          _buildNotificationTile(
            img: 'https://i.pravatar.cc/150?img=12',
            text:
                '@davidjr rmention you in a comment: @joviedan Lol\n"Lorem ipsum dolor sit amet..."',
            time: '5h ago',
          ),
          _buildNotificationTile(
            img: 'https://i.pravatar.cc/150?img=33',
            text: '@lucas rmention you in a story',
            time: '5h ago',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile({
    required String img,
    required String text,
    required String time,
  }) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(img)),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            TextSpan(
              text: ' $time',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments'), leading: const SizedBox()),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select Payment mode',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text('Cards'),
              subtitle: const Text('Add Credit, Debit & ATM Cards'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showAddCardSheet(context);
              },
            ),
          ),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.payment),
              title: const Text('UPI'),
              subtitle: const Text('Pay via UPI'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Link via UPI'),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter your UPI ID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green.shade700,
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.lock, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Your UPI ID Will be encrypted and is 100% safe with us.',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Wallet'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Link Your Wallet'),
                      const SizedBox(height: 8),
                      TextField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '91',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.network(
                              'https://flagcdn.com/w20/in.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green.shade700,
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Netbanking'),
              children: [
                ListTile(title: const Text('Bank of India'), onTap: () {}),
                ListTile(title: const Text('Canara Bank'), onTap: () {}),
                ListTile(title: const Text('HDFC Bank'), onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBlogCard(context, true),
          _buildBlogCard(context, false),
          _buildBlogCard(context, false),
          _buildBlogCard(context, false),
        ],
      ),
    );
  }

  Widget _buildBlogCard(BuildContext context, bool isFeatured) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFeatured)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1780&q=80',
              fit: BoxFit.cover,
              height: 180,
              width: double.infinity,
            ),
          ),
        if (!isFeatured)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=500&q=80',
              fit: BoxFit.cover,
              height: 80,
              width: 80,
            ),
          ),
        const SizedBox(height: 8, width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The best food Of this month.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (!isFeatured)
              const Text(
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            const Text(
              '2 hours ago • 1 min read • By Emile',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );

    return Card(
      elevation: 0,
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BlogDetailPage()),
          );
        },
        child: isFeatured
            ? cardContent
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cardContent.children[0], // Gambar
                  const SizedBox(width: 12),
                  Expanded(
                    child: cardContent.children[2], // Column Teks
                  ),
                ],
              ),
      ),
    );
  }
}

class BlogDetailPage extends StatelessWidget {
  const BlogDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Detail')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1780&q=80',
                  fit: BoxFit.cover,
                  height: 250,
                  width: double.infinity,
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'The best food Of this month.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 12,
                            backgroundImage: NetworkImage(
                              'https://i.pravatar.cc/150?img=32',
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'By Emily • 2 hours ago • 1 min read',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's So Trendy About Food That Everyone Went Crazy Over It?",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Vegetables, including lettuce, corn, tomatoes, onions, celery, cucumbers, mushrooms, and more are also sold at many grocery stores, and are purchased similarly to the way that fruits are. Grocery stores typically stock more vegetables than fruit at any given time, as vegetables remain fresh longer than fruits do, generally speaking.\n\nDonec sit amet eros non massa vehicula porta. Nulla facilisi. Suspendisse ac aliquet nisl, lacinia mattis magna. Praesent quis consectetur neque, sed viverra neque. Mauris ultrices massa purus, fermentum ornare magna gravida vitae. Nulla sit amet est a enim porta gravida.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modal "Select a location"
void _showSelectLocationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select a location',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search for area, street name..',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(
                    ctx,
                  ).colorScheme.primary.withOpacity(0.1),
                  foregroundColor: Theme.of(ctx).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Add'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

// --- WIDGET FORM RATING (STATEFUL) ---
class _RatingForm extends StatefulWidget {
  const _RatingForm();

  @override
  State<_RatingForm> createState() => _RatingFormState();
}

class _RatingFormState extends State<_RatingForm> {
  int _rating = 0; // Variabel untuk menyimpan rating (0-5)
  final _reviewController =
      TextEditingController(); // Controller untuk mengambil teks

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    // --- BUAT REVIEW BARU (SIMULASI) ---
    // (Anda bisa ganti 'Current User' dengan nama user yang sedang login)
    final newReview = Review(
      name: 'Current User',
      imageUrl: 'https://i.pravatar.cc/150?img=5', // Gambar user saat ini
      rating: _rating.toDouble(),
      comment: _reviewController.text,
      date: 'Just now',
    );
    // --- AKHIR SIMULASI ---

    // Tutup modal dan KIRIM review baru kembali ke halaman sebelumnya
    Navigator.pop(context, newReview);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'What do you think?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please give me your rating by clicking on the\nstars below.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // --- INI BAGIAN BINTANG YANG INTERAKTIF ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1; // index 0-4 -> rating 1-5
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 40,
                  color: index < _rating ? Colors.amber : Colors.grey,
                ),
              );
            }),
          ),
          // --- AKHIR BAGIAN BINTANG ---
          const SizedBox(height: 24),
          TextField(
            controller: _reviewController, // <-- Hubungkan controller
            decoration: InputDecoration(
              hintText: 'Tell us about your experience.',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _rating == 0
                  ? null
                  : _submitReview, // <-- Panggil fungsi submit
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('SUBMIT'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// --- FUNGSI UNTUK MENAMPILKAN MODAL ---
// (Sekarang mengembalikan Future<Review?>)
Future<Review?> _showRatingsSheet(BuildContext context) async {
  return await showModalBottomSheet<Review?>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return const _RatingForm();
    },
  );
}

// Modal "Add Card"
void _showAddCardSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ADD CARD',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Card holder Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '**** **** **** ****',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Security Code',
                      hintText: '...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Added'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
