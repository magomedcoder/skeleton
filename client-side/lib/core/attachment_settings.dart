abstract final class AttachmentSettings {
  AttachmentSettings._();

  static const int maxFileSizeBytes = 512 * 1024;

  static int get maxFileSizeKb => maxFileSizeBytes ~/ 1024;

  static const List<String> textFileExtensions = ['txt', 'md', 'log'];
}
