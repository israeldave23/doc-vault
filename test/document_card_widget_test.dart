import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/documents/widgets/document_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('document card exposes one useful accessible action', (tester) async {
    final expiry = DateTime.now().add(const Duration(days: 45));
    final document = Document(
      id: 'passport',
      title: 'Philippine Passport',
      category: 'passport',
      expiryDate: expiry,
      profileId: 'me',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentCard(document: document, onTap: () {}),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(DocumentCard));
    expect(semantics.label, contains('Philippine Passport'));
    expect(semantics.label, contains('Passport'));
    expect(semantics.label, contains('Renew soon'));
    expect(semantics.flagsCollection.isButton, isTrue);
  });

  testWidgets('document card remains usable with large text', (tester) async {
    final document = Document(
      id: 'license',
      title: 'Driver license with a deliberately long descriptive title',
      category: 'drivers_license',
      expiryDate: DateTime.now().add(const Duration(days: 10)),
      profileId: 'me',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(body: DocumentCard(document: document)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Expiring soon'), findsOneWidget);
    expect(find.textContaining('Expires '), findsOneWidget);
  });

  testWidgets('document card wraps on narrow width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final document = Document(
      id: 'passport',
      title: 'Very long document title that should wrap',
      category: 'passport',
      expiryDate: DateTime.now().add(const Duration(days: 45)),
      profileId: 'me',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(280, 600)),
          child: Scaffold(body: DocumentCard(document: document)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(DocumentCard), findsOneWidget);
    expect(find.textContaining('Very long document title'), findsOneWidget);
  });

  testWidgets('document card preserves tap interaction', (tester) async {
    var tapped = false;
    final document = Document(
      id: 'insurance',
      title: 'Health Insurance',
      category: 'insurance',
      expiryDate: DateTime.now().add(const Duration(days: 120)),
      profileId: 'me',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentCard(
            document: document,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DocumentCard));
    expect(tapped, isTrue);
    expect(find.text('Insurance'), findsOneWidget);
    expect(find.text('Valid'), findsOneWidget);
  });

  testWidgets('document card renders in both light and dark themes', (tester) async {
    final document = Document(
      id: 'expired',
      title: 'Expired Passport',
      category: 'passport',
      expiryDate: DateTime.now().subtract(const Duration(days: 2)),
      profileId: 'me',
    );

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.light),
          darkTheme: ThemeData(brightness: Brightness.dark),
          themeMode: mode,
          home: Scaffold(body: DocumentCard(document: document)),
        ),
      );
      expect(find.byType(DocumentCard), findsOneWidget);
      expect(find.text('Expired'), findsOneWidget);
    }
  });
}