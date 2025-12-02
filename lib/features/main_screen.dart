import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:crypto_assistant/l10n/app_localizations.dart';
import 'crypto/presentation/pages/home_screen.dart';
import 'news/presentation/pages/news_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.5),
                        ]
                      : [
                          Colors.white.withOpacity(0.8),
                          Colors.white.withOpacity(0.7),
                        ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: isDark 
                      ? Colors.white.withOpacity(0.15) 
                      : Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentIndex == 0 ? Icons.home : Icons.home_outlined,
                            size: 28,
                            color: _currentIndex == 0 
                                ? (isDark ? Colors.white : Colors.deepPurple)
                                : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.home,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _currentIndex == 0 ? FontWeight.w600 : FontWeight.normal,
                              color: _currentIndex == 0 
                                  ? (isDark ? Colors.white : Colors.deepPurple)
                                  : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentIndex == 1 ? Icons.article : Icons.article_outlined,
                            size: 28,
                            color: _currentIndex == 1 
                                ? (isDark ? Colors.white : Colors.deepPurple)
                                : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.news,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _currentIndex == 1 ? FontWeight.w600 : FontWeight.normal,
                              color: _currentIndex == 1 
                                  ? (isDark ? Colors.white : Colors.deepPurple)
                                  : (isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
