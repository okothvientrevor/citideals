import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernNavItem {
  final IconData icon;
  final String label;
  const ModernNavItem({required this.icon, required this.label});
}

class ModernNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items;

  const ModernNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.darkCard.withOpacity(0.96)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : AppTheme.primary.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.03),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return _NavButton(
                item: items[i],
                selected: selected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final ModernNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withOpacity(0.55),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        item.label,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
