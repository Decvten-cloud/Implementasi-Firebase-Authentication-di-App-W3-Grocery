import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data untuk setiap halaman onboarding
  final List<Map<String, String>> _onboardingData = [
    {
      "title": "Best Quality Grocery\nat your doorstep!",
      "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor.",
      "icon": "vegetables" // Placeholder
    },
    {
      "title": "Welcome to\nGrocery Application",
      "text": "Our products are always kept fresh. They are 100% natural, delicious, nutritions, healty and safe for consumption.",
      "icon": "basket" // Placeholder
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color w3Green = Color(0xFF006400); // Sesuaikan warnanya

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingData.length,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPageContent(
                    title: _onboardingData[index]['title']!,
                    text: _onboardingData[index]['text']!,
                    iconName: _onboardingData[index]['icon']!,
                  );
                },
              ),
            ),
            // Indikator titik-titik
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingData.length,
                (index) => buildDot(index: index, w3Green: w3Green),
              ),
            ),
            // Tombol NEXT
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: w3Green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_currentPage == _onboardingData.length - 1) {
                      // Halaman terakhir, pindah ke Login (nama route '/login' didefinisikan di main.dart)
                      Navigator.pushReplacementNamed(context, '/login');
                    } else {
                      // Pindah ke halaman selanjutnya
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: const Text('NEXT', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk titik indikator
  AnimatedContainer buildDot({required int index, required Color w3Green}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? w3Green : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// Widget untuk konten di dalam PageView
class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    super.key,
    required this.title,
    required this.text,
    required this.iconName,
  });

  final String title;
  final String text;
  final String iconName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- GANTI ICON INI DENGAN GAMBAR ANDA ---
          Icon(
            iconName == 'vegetables' ? Icons.local_florist : Icons.shopping_basket,
            size: 200,
            color: Colors.green,
          ),
          // --- Contoh jika pakai gambar: ---
          // Image.asset(
          //   iconName == 'vegetables' ? 'assets/vegetables.png' : 'assets/basket.png',
          //   height: 250,
          // ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}