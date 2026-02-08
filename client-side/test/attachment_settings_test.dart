import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/attachment_settings.dart';

void main() {
  group('AttachmentSettings', () {
    test('maxFileSizeKb равен 1024', () {
      expect(AttachmentSettings.maxFileSizeKb, 1024);
    });

    test('isBinaryDocument распознаёт pdf, docx, xlsx, csv', () {
      expect(AttachmentSettings.isBinaryDocument('file.pdf'), true);
      expect(AttachmentSettings.isBinaryDocument('file.docx'), true);
      expect(AttachmentSettings.isBinaryDocument('file.xlsx'), true);
      expect(AttachmentSettings.isBinaryDocument('file.csv'), true);
    });

    test('isBinaryDocument возвращает false для txt', () {
      expect(AttachmentSettings.isBinaryDocument('file.txt'), false);
    });

    test('textFileExtensions содержит ожидаемые расширения', () {
      expect(AttachmentSettings.textFileExtensions, contains('pdf'));
      expect(AttachmentSettings.textFileExtensions, contains('txt'));
    });
  });
}
