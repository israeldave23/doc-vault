import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../documents/screens/dashboard_screen.dart';
import '../documents/screens/document_collection_screen.dart';
import '../documents/screens/add_edit_document_screen.dart';
import '../settings/screens/settings_screen.dart';

/// Custom premium bottom navigation bar with center Add Document FAB.
class PremiumBottomNavigation extends StatefulWidget {
  const PremiumBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onAddDocument,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onAddDocument;

  @override
  State<PremiumBottomNavigation> createState() =>
      _PremiumBottomNavigationState();
}

class _PremiumBottomNavigationState extends State<PremiumBottomNavigation> {
  static const _tabs = [
    (icon: Icons.grid_view_outlined, selectedIcon: Icons.grid_view_rounded, label: 'Vault'),
    (icon: Icons.description_outlined, selectedIcon: Icons.description_rounded, label: 'Docs'),
    (icon: Icons.notifications_none_outlined, selectedIcon: Icons.notifications_rounded, label: 'Alerts'),
    (icon: Icons.tune_outlined, selectedIcon: Icons.tune_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = AppColors.seed;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: _tabs[0].icon,
                selectedIcon: _tabs[0].selectedIcon,
                label: _tabs[0].label,
                isSelected: widget.selectedIndex == 0,
                primaryColor: primaryColor,
                onTap: () => widget.onDestinationSelected(0),
              ),
              _NavItem(
                icon: _tabs[1].icon,
                selectedIcon: _tabs[1].selectedIcon,
                label: _tabs[1].label,
                isSelected: widget.selectedIndex == 1,
                primaryColor: primaryColor,
                onTap: () => widget.onDestinationSelected(1),
              ),
              _NavItem(
                icon: _tabs[2].icon,
                selectedIcon: _tabs[2].selectedIcon,
                label: _tabs[2].label,
                isSelected: widget.selectedIndex == 2,
                primaryColor: primaryColor,
                onTap: () => widget.onDestinationSelected(2),
              ),
              _NavItem(
                icon: _tabs[3].icon,
                selectedIcon: _tabs[3].selectedIcon,
                label: _tabs[3].label,
                isSelected: widget.selectedIndex == 3,
                primaryColor: primaryColor,
                onTap: () => widget.onDestinationSelected(3),
              ),
            ],
          ),
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: widget.onAddDocument,
                backgroundColor: AppColors.primaryViolet,
                foregroundColor: Colors.white,
                elevation: 6,
                tooltip: 'Add document',
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.primaryColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isSelected ? primaryColor : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Material 3 application shell with custom premium bottom navigation.
class VaultShell extends ConsumerStatefulWidget {
  const VaultShell({super.key});

  @override
  ConsumerState<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends ConsumerState<VaultShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            DashboardScreen(),
            DocumentCollectionScreen(),
            DocumentCollectionScreen(alertsOnly: true),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: PremiumBottomNavigation(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _selectedIndex = index);
          },
          onAddDocument: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const AddEditDocumentScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}
