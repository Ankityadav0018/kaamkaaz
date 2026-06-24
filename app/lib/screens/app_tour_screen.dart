import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import 'package:easy_localization/easy_localization.dart';

class AppTourScreen extends StatefulWidget {
  final String role;
  const AppTourScreen({super.key, required this.role});

  @override
  State<AppTourScreen> createState() => _AppTourScreenState();
}

class _AppTourScreenState extends State<AppTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List<Map<String, String>> _pages;

  @override
  void initState() {
    super.initState();
    if (widget.role == 'worker') {
      _pages = [
        {'title': 'tourWelcomeWorker'.tr(), 'desc': 'tourDescWorker1'.tr(), 'icon': '👋'},
        {'title': 'tourTitleWorker2'.tr(), 'desc': 'tourDescWorker2'.tr(), 'icon': '🔍'},
        {'title': 'tourTitleWorker3'.tr(), 'desc': 'tourDescWorker3'.tr(), 'icon': '💬'},
        {'title': 'tourTitleWorker4'.tr(), 'desc': 'tourDescWorker4'.tr(), 'icon': '✅'},
      ];
    } else {
      _pages = [
        {'title': 'tourWelcomeRecruiter'.tr(), 'desc': 'tourDescRecruiter1'.tr(), 'icon': '👋'},
        {'title': 'tourTitleRecruiter2'.tr(), 'desc': 'tourDescRecruiter2'.tr(), 'icon': '📝'},
        {'title': 'tourTitleRecruiter3'.tr(), 'desc': 'tourDescRecruiter3'.tr(), 'icon': '🤝'},
        {'title': 'tourTitleRecruiter4'.tr(), 'desc': 'tourDescRecruiter4'.tr(), 'icon': '💬'},
      ];
    }
  }

  Future<void> _completeTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tour_seen_${widget.role}', true);
    if (mounted) {
      if (widget.role == 'worker') {
        context.go('/worker');
      } else {
        context.go('/recruiter');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _completeTour,
            child: Text('tourSkip'.tr(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(page['icon']!, style: const TextStyle(fontSize: 100)),
                      const SizedBox(height: 40),
                      Text(
                        page['title']!,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        page['desc']!,
                        style: const TextStyle(fontSize: 16, color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _completeTour();
                    } else {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'tourGetStarted'.tr() : 'tourNext'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
