import 'package:doc_vault/features/pro/models/free_tier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FreeTier', () {
    test('matches the spec limits', () {
      expect(FreeTier.maxDocuments, 10);
      expect(FreeTier.maxProfiles, 2);
      expect(FreeTier.proProductId, 'pro_unlock');
    });

    test('limit messages state both the cap and the current count', () {
      final docs = FreeTier.documentLimitMessage(7);
      expect(docs, contains('10'));
      expect(docs, contains('7'));

      final people = FreeTier.profileLimitMessage(3);
      expect(people, contains('2'));
      expect(people, contains('3'));
    });
  });
}
