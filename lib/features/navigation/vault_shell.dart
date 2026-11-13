import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../documents/screens/dashboard_screen.dart';
import '../documents/screens/document_collection_screen.dart';
import '../settings/screens/settings_screen.dart';

/// Material 3 application shell. [IndexedStack] retains each destination's
/// scroll position, search controller, and Home banner lifecycle.
class VaultShell extends StatefulWidget {
  const VaultShell({super.key});

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int _selectedIndex = 0;

  static const _destinations = <Widget>[
    DashboardScreen(),
    DocumentCollectionScreen(),
    DocumentCollectionScreen(alertsOnly: true),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final navBarBorder = scheme.outlineVariant;
    final navBarIndicator = scheme.primaryContainer;
    final navBarSelectedIcon = scheme.primary;
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
          children: _destinations,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(
              top: BorderSide(color: navBarBorder, width: 1),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 60,
            indicatorColor: navBarIndicator,
            onDestinationSelected: (index) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() => _selectedIndex = index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded, color: navBarSelectedIcon),
                label: 'Vault',
              ),
              NavigationDestination(
                icon: const Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description_rounded, color: navBarSelectedIcon),
                label: 'Docs',
              ),
              NavigationDestination(
                icon: const Icon(Icons.notifications_none_outlined),
                selectedIcon: Icon(Icons.notifications_rounded, color: navBarSelectedIcon),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: const Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded, color: navBarSelectedIcon),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
