import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../documents/screens/dashboard_screen.dart';
import '../documents/screens/document_collection_screen.dart';
import '../documents/screens/add_edit_document_screen.dart';
import '../settings/screens/settings_screen.dart';

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
    (icon: LucideIcons.layoutGrid, label: 'Vault'),
    (icon: LucideIcons.fileText, label: 'Docs'),
    (icon: LucideIcons.bell, label: 'Alerts'),
    (icon: LucideIcons.slidersHorizontal, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.card,
        border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var index = 0; index < _tabs.length; index++)
              Expanded(
                child: NavigationItem(
                  selected: widget.selectedIndex == index,
                  onChanged: (_) => widget.onDestinationSelected(index),
                  label: Text(_tabs[index].label),
                  child: Icon(_tabs[index].icon),
                ),
              ),
            IconButton.primary(
              icon: const Icon(LucideIcons.plus),
              onPressed: widget.onAddDocument,
              shape: ButtonShape.circle,
            ),
            const SizedBox(width: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

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
        footers: [
          PremiumBottomNavigation(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              HapticFeedback.selectionClick();
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _selectedIndex = index);
            },
            onAddDocument: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                ShadcnPageRoute<void>(
                  builder: (_) => const AddEditDocumentScreen(),
                ),
              );
            },
          ),
        ],
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            DashboardScreen(),
            DocumentCollectionScreen(),
            DocumentCollectionScreen(alertsOnly: true),
            SettingsScreen(),
          ],
        ),
      ),
    );
  }
}
