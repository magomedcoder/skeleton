abstract interface class EditorRepository {
  Future<String> transform({
    required String text,
    String? model,
  });
}
