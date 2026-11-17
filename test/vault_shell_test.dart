import 'package:doc_vault/features/navigation/vault_shell.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  testWidgets('bottom navigation shows every label and handles selections',
      (tester) async {
    tester.view.physicalSize = const Size(720, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    var addCalls = 0;

    await tester.pumpWidget(ShadcnApp(
      home: Scaffold(
        child: PremiumBottomNavigation(
          selectedIndex: 0,
          onDestinationSelected: (value) => selected = value,
          onAddDocument: () => addCalls++,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    for (final label in ['Vault', 'Docs', 'Alerts', 'Settings']) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.byType(NavigationItem).at(3));
    await tester.pump();
    expect(selected, 3);
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();
    expect(addCalls, 1);
    expect(tester.takeException(), isNull);
  });
}
