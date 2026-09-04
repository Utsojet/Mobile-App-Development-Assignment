import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../utils/app_colors.dart';
import 'home/home_screen.dart';
import 'favorites/favorites_screen.dart';

/// Root shell that owns the [BottomNavigationBar] and switches between
/// top-level screens via an [IndexedStack] (screens stay alive on tab switch).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // Screens are kept alive in IndexedStack — no re-fetching on tab switch.
  static const List<Widget> _screens = [
    HomeScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Iconsax.home),
            selectedIcon: Icon(Iconsax.home_2, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Iconsax.heart),
            selectedIcon: Icon(Iconsax.heart_add, color: AppColors.primary),
            label: 'Favorites',
          ),
        ],
      ),
    );
  }
}
