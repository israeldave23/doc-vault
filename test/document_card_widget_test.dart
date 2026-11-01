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
  });
}