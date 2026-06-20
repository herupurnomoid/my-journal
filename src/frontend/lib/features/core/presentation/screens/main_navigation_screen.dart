import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/glassmorphism_container.dart';
import '../../../home/presentation/screens/dashboard_screen.dart';
import '../../../home/presentation/screens/journal_list_screen.dart';
import '../../../insight/presentation/screens/insight_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../journal/presentation/screens/journal_editor_screen.dart';
import 'package:provider/provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    JournalListScreen(),
    InsightScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Biarkan body memanjang hingga ke bawah navbar
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: FloatingBottomNavbar(
        selectedIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const JournalEditorScreen()),
          );
        },
      ),
    );
  }
}

class FloatingBottomNavbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final VoidCallback onAddPressed;

  const FloatingBottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return SafeArea(
      child: SizedBox(
        height: 92,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              left: 24,
              right: 24,
              child: SizedBox(
                height: 72,
                child: GlassmorphismContainer(
                  borderRadius: 28,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Beranda', themeProvider)),
                        Expanded(child: _buildNavItem(1, Icons.book_outlined, 'Jurnal', themeProvider)),
                        const SizedBox(width: 74),
                        Expanded(child: _buildNavItem(2, Icons.bar_chart_outlined, 'Insight', themeProvider)),
                        Expanded(child: _buildNavItem(3, Icons.person_outline_rounded, 'Profil', themeProvider)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 15,
              child: _PhysicalAddButton(onPressed: onAddPressed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, ThemeProvider themeProvider) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? themeProvider.isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? themeProvider.primaryTextColor : themeProvider.secondaryTextColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? themeProvider.primaryTextColor : themeProvider.secondaryTextColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Physical Add Button
// ─────────────────────────────────────────────
class _PhysicalAddButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _PhysicalAddButton({required this.onPressed});

  @override
  State<_PhysicalAddButton> createState() => _PhysicalAddButtonState();
}

class _PhysicalAddButtonState extends State<_PhysicalAddButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  static const double _pressDepth = 5.0;
  static const double _stemHeight = 6.0;
  static const double _size = 62.0;
  static const double _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final double currentOffset = _pressed ? _pressDepth : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: SizedBox(
        width: _size + 16, 
        height: _size + _stemHeight + 16,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ambient glow
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: _pressed
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.lightBlueAccent.withValues(alpha: 0.35), // Light blue glow
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                ),
              ),
            ),

            // Keycap
            Positioned(
              top: 8 + currentOffset,
              left: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_radius),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.45, 1.0],
                    colors: _pressed
                        ? [
                            Colors.lightBlue.shade300,
                            Colors.lightBlue.shade400,
                            Colors.blue.shade500,
                          ]
                        : [
                            Colors.lightBlueAccent.shade100,
                            Colors.lightBlueAccent,
                            Colors.blueAccent,
                          ],
                  ),
                  border: Border.all(
                    color: _pressed
                        ? Colors.blue.shade600
                        : Colors.lightBlueAccent.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: Colors.blue.shade900.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.blueAccent.withValues(alpha: 0.5),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Highlight spekuler
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        height: _size * 0.45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(_radius),
                            topRight: Radius.circular(_radius),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: _pressed ? 0.06 : 0.22),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.add_rounded,
                      size: 30,
                      color: Colors.white.withValues(alpha: _pressed ? 0.85 : 1.0),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
