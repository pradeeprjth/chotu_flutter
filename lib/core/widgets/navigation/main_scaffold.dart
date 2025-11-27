import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/colors.dart';
import '../../../app/design_tokens.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../features/wishlist/providers/wishlist_provider.dart';

/// Provider to track the current navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// Main scaffold with persistent bottom navigation bar
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final cartState = ref.watch(cartProvider);
    final cartItemCount = cartState.cart.itemCount;
    final wishlistState = ref.watch(wishlistProvider);
    final wishlistItemCount = wishlistState.itemCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => _onItemTapped(context, ref, 0),
                ),
                _NavItem(
                  icon: Icons.favorite_outline,
                  activeIcon: Icons.favorite,
                  label: 'Wishlist',
                  isSelected: currentIndex == 1,
                  badgeCount: wishlistItemCount,
                  onTap: () => _onItemTapped(context, ref, 1),
                ),
                _NavItem(
                  icon: Icons.shopping_cart_outlined,
                  activeIcon: Icons.shopping_cart,
                  label: 'Cart',
                  isSelected: currentIndex == 2,
                  badgeCount: cartItemCount,
                  onTap: () => _onItemTapped(context, ref, 2),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Orders',
                  isSelected: currentIndex == 3,
                  onTap: () => _onItemTapped(context, ref, 3),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  isSelected: currentIndex == 4,
                  onTap: () => _onItemTapped(context, ref, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    HapticFeedback.lightImpact();

    // Update the provider first
    ref.read(bottomNavIndexProvider.notifier).state = index;

    // Then navigate
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/wishlist');
        break;
      case 2:
        context.go('/cart');
        break;
      case 3:
        context.go('/orders');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

/// Individual navigation item with optional badge
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final unselectedColor = isDark
        ? AppColors.textOnDarkSecondary
        : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    key: ValueKey(isSelected),
                    size: 24,
                    color: isSelected ? selectedColor : unselectedColor,
                  ),
                ),
                // Badge
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.cartBadge,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            // Label
            AnimatedDefaultTextStyle(
              duration: AppDuration.fast,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? selectedColor : unselectedColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to determine the nav index from a route path
int getNavIndexFromPath(String path) {
  if (path.startsWith('/home') || path == '/') {
    return 0;
  } else if (path.startsWith('/wishlist')) {
    return 1;
  } else if (path.startsWith('/cart') || path.startsWith('/checkout')) {
    return 2;
  } else if (path.startsWith('/orders')) {
    return 3;
  } else if (path.startsWith('/profile') || path.startsWith('/addresses')) {
    return 4;
  } else if (path.startsWith('/categories') || path.startsWith('/category') || path.startsWith('/product')) {
    // Keep home tab selected for browsing
    return 0;
  }
  return 0;
}
