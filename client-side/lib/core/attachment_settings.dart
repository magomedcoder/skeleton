abstract final class AttachmentSettings {
  AttachmentSettings._();

  static const int maxFileSizeBytes = 512 * 1024;

  static int get maxFileSizeKb => maxFileSizeBytes ~/ 1024;

  static const List<String> textFileExtensions = [
    'txt',
    'md',
    'log',
    'pdf',
    'docx',
    'xlsx',
    'csv',
  ];

  static const List<String> documentBinaryExtensions = [
    'pdf',
    'docx',
    'xlsx',
    'csv',
  ];

  static bool isBinaryDocument(String filename) {
    final ext = filename.split('.').lastOrNull?.toLowerCase() ?? '';
    return documentBinaryExtensions.contains(ext);
  }

  static const List<String> textFormatLabels = ['TXT', 'MD', 'LOG'];

  static const List<String> documentFormatLabels = ['PDF', 'DOCX', 'XLSX', 'CSV'];
}
