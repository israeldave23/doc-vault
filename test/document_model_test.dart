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

  test('copyWith can clear nullable idNumber', () {
    final cleared = sample().copyWith(clearIdNumber: true);
    expect(cleared.idNumber, isNull);
    final kept = sample().copyWith(clearIdNumber: false);
    expect(kept.idNumber, 'P1234567A');
  });

  test('copyWith can clear nullable notes', () {
    final withNotes = sample().copyWith(notes: 'hello');
    final cleared = withNotes.copyWith(clearNotes: true);
    expect(cleared.notes, isNull);
  });

  test('fromMap rejects missing required string fields', () {
    expect(() => Document.fromMap(<String, dynamic>{
          'title': 'Passport',
          'category': 'passport',
          'expiryDate': '2030-01-01',
          'profileId': 'me',
        }), throwsA(isA<FormatException>()));
  });

  test('fromMap rejects invalid imagePaths entries', () {
    expect(() => Document.fromMap(<String, dynamic>{
          'id': 'x',
          'title': 'T',
          'category': 'passport',
          'expiryDate': '2030-01-01',
          'profileId': 'me',
          'imagePaths': [42, 'ok'],
        }), throwsA(isA<FormatException>()));
  });

  test('fromMap rejects invalid reminderDaysBefore entries', () {
    expect(() => Document.fromMap(<String, dynamic>{
          'id': 'x',
          'title': 'T',
          'category': 'passport',
          'expiryDate': '2030-01-01',
          'profileId': 'me',
          'reminderDaysBefore': [0, -1],
        }), throwsA(isA<FormatException>()));
  });

  test('fromMap rejects invalid dates', () {
    expect(() => Document.fromMap(<String, dynamic>{
          'id': 'x',
          'title': 'T',
          'category': 'passport',
          'expiryDate': 'not-a-date',
          'profileId': 'me',
        }), throwsA(isA<FormatException>()));
  });

  test('fromMap tolerates old missing optional fields', () {
    final doc = Document.fromMap(<String, dynamic>{
          'id': 'x',
          'title': 'T',
          'category': 'passport',
          'expiryDate': '2030-01-01',
          'profileId': 'me',
        });
    expect(doc.idNumber, isNull);
    expect(doc.notes, isNull);
    expect(doc.imagePaths, isEmpty);
    expect(doc.reminderDaysBefore, [90, 30, 7, 1]);
  });
}
