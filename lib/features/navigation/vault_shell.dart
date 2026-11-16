import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../documents/screens/dashboard_screen.dart';
import '../documents/screens/document_collection_screen.dart';
import '../settings/screens/settings_screen.dart';

/// Retains scroll and filter state while switching archive destinations.
class VaultShell extends StatefulWidget {
  const VaultShell({super.key});

  @override
  State<VaultShell> createState() => _VaultShellState();
}

class _VaultShellState extends State<VaultShell> {
  int _selectedIndex = 0;

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final destinations = <Widget>[
      DashboardScreen(onBrowseAll: () => _select(1)),
      const DocumentCollectionScreen(),
      const DocumentCollectionScreen(alertsOnly: true),
      const SettingsScreen(),
    ];
    const items = <(IconData, String)>[
      (Icons.space_dashboard_outlined, 'Overview'),
      (Icons.folder_copy_outlined, 'Documents'),
      (Icons.notifications_none_rounded, 'Renewals'),
      (Icons.tune_rounded, 'Settings'),
    ];

    Widget navigation({required bool vertical}) {
      final children = List<Widget>.generate(items.length, (index) {
        final selected = _selectedIndex == index;
        return Semantics(
          selected: selected,
          button: true,
          label: items[index].$2,
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              color: selected ? scheme.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _select(index),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[index].$1,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant),
                      const SizedBox(height: 6),
                      Text(
                        items[index].$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      });
      return vertical
          ? Column(children: children)
          : Row(
              children:
                  children.map((child) => Expanded(child: child)).toList());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          _select(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            if (wide)
              Container(
                width: 112,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border:
                      Border(right: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Icon(Icons.shield_outlined,
                            color: scheme.primary, size: 32),
                      ),
                      navigation(vertical: true),
                    ],
                  ),
                ),
              ),
            Expanded(
              child:
                  IndexedStack(index: _selectedIndex, children: destinations),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(top: false, child: navigation(vertical: false)),
              ),
      ),
    );
  }
}
