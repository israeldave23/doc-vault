import 'package:doc_vault/features/documents/models/document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Document sample() => Document(
        id: 'abc',
        title: 'Passport',
        category: 'passport',
        expiryDate: DateTime(2030, 1, 1),
        profileId: 'me',
        idNumber: 'P1234567A',
      );

  test('maskedIdNumber shows only the last 4 characters', () {
    expect(sample().maskedIdNumber, '•••• 567A');
  });

  test('default reminders are 90/30/7/1', () {
    expect(sample().reminderDaysBefore, [90, 30, 7, 1]);
  });

  test('copyWith keeps id and updates fields', () {
    final updated = sample().copyWith(title: 'New title', clearIssueDate: true);
    expect(updated.id, 'abc');
    expect(updated.title, 'New title');
    expect(updated.issueDate, isNull);
  });
}
