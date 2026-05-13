import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class ModernNavItem {
  final IconData icon;
  final String label;
  const ModernNavItem({required this.icon, required this.label});
}

/// Fixed bottom nav bar — full-width with rounded top corners.
/// When [showAdminButton] is true an elevated admin button is inserted in the
/// centre, and tapping it fires [onAdminTap] without changing [currentIndex].
class ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items; // exactly 4 items
  final bool showAdminButton;
  final VoidCallback? onAdminTap;

  const ModernNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.showAdminButton = false,
    this.onAdminTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C0C14) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.55)
                : Colors.black.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: showAdminButton
              ? _buildWithAdmin(context, isDark)
              : _buildNormal(context, isDark),
        ),
      ),
    );
  }

  Widget _buildNormal(BuildContext context, bool isDark) {
    return Row(
      children: List.generate(
        items.length,
        (i) => Expanded(
          child: _NavButton(
            item: items[i],
            selected: i == currentIndex,
            isDark: isDark,
            onTap: () {
              HapticFeedback.selectionClick();
              onTap(i);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWithAdmin(BuildContext context, bool isDark) {
    // Layout: [Discover] [Auctions] [ADMIN●] [Raffles] [Profile]
    final leftItems = items.sublist(0, 2);
    final rightItems = items.sublist(2, 4);
    return Row(
      children: [
        ...List.generate(
          leftItems.length,
          (i) => Expanded(
            child: _NavButton(
              item: leftItems[i],
              selected: i == currentIndex,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i);
              },
            ),
          ),
        ),
        _AdminFab(
          onTap: () {
            HapticFeedback.mediumImpact();
            onAdminTap?.call();
          },
        ),
        ...List.generate(
          rightItems.length,
          (i) => Expanded(
            child: _NavButton(
              item: rightItems[i],
              selected: (i + 2) == currentIndex,
              isDark: isDark,
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i + 2);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatefulWidget {
  final ModernNavItem item;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.isDark
        ? AppTheme.primaryLight
        : AppTheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.38);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _press.value * 0.07, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Active indicator bar at top
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              height: 3,
              width: widget.selected ? 28 : 0,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.all(widget.selected ? 7 : 6),
              decoration: BoxDecoration(
                color: widget.selected
                    ? activeColor.withOpacity(widget.isDark ? 0.14 : 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                widget.item.icon,
                size: 22,
                color: widget.selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminFab extends StatefulWidget {
  final VoidCallback onTap;
  const _AdminFab({required this.onTap});

  @override
  State<_AdminFab> createState() => _AdminFabState();
}

class _AdminFabState extends State<_AdminFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.forward(),
      onTapUp: (_) {
        _press.reverse();
        widget.onTap();
      },
      onTapCancel: () => _press.reverse(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: 1.0 - _press.value * 0.08, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
