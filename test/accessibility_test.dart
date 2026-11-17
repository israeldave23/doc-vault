import 'package:doc_vault/features/documents/models/document.dart';
import 'package:doc_vault/features/documents/providers/document_providers.dart';
import 'package:doc_vault/features/documents/screens/document_detail_screen.dart';
import 'package:doc_vault/features/profiles/models/profile.dart';
import 'package:doc_vault/features/profiles/providers/profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class _Documents extends DocumentsNotifier {
  _Documents(this.document);
  final Document document;

  @override
  List<Document> build() => [document];
}

class _Profiles extends ProfilesNotifier {
  @override
  List<Profile> build() => const [Profile(id: Profile.selfId, name: 'Me')];
}

void main() {
  testWidgets('document actions expose accessible names', (tester) async {
    final document = Document(
      id: 'passport',
      title: 'Passport',
      category: 'passport',
      expiryDate: DateTime(2030, 1, 1),
      profileId: Profile.selfId,
    );
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(() => _Documents(document)),
          profilesProvider.overrideWith(_Profiles.new),
        ],
        child: ShadcnApp(
          home: DocumentDetailScreen(documentId: document.id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Edit document'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete document'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
