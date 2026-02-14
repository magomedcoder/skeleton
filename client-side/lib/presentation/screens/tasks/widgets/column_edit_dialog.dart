import 'package:flutter/material.dart';
import 'package:legion/domain/entities/board_column.dart';

typedef SaveColumnCallback = Future<void> Function(String title, String colorHex);

class ColumnEditDialog extends StatefulWidget {
  final BoardColumn? column;
  final SaveColumnCallback onSave;

  const ColumnEditDialog({
    super.key,
    this.column,
    required this.onSave,
  });

  static Future<void> showCreate(
    BuildContext context, {
    required SaveColumnCallback onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ColumnEditDialog(onSave: onSave),
    );
  }

  static Future<void> showEdit(
    BuildContext context, {
    required BoardColumn column,
    required SaveColumnCallback onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => ColumnEditDialog(column: column, onSave: onSave),
    );
  }

  @override
  State<ColumnEditDialog> createState() => _ColumnEditDialogState();
}

class _ColumnEditDialogState extends State<ColumnEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late Color _pickedColor;
  bool _isSubmitting = false;

  static const List<Color> _presetColors = [
    Color(0xFF9E9E9E),
    Color(0xFF4A6FA5),
    Color(0xFF5865F2),
    Color(0xFF0088CC),
    Color(0xFF0366D6),
    Color(0xFF25D366),
    Color(0xFF2EB886),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.column?.title ?? '');
    _pickedColor = widget.column != null ? _hexToColor(widget.column!.color) : _presetColors[0];
  }

  static Color _hexToColor(String hex) {
    if (hex.isEmpty) {
      return _presetColors[0];
    }

    var h = hex.startsWith('#') ? hex.substring(1) : hex;

    if (h.length == 6) {
      h = 'FF$h';
    }

    final v = int.tryParse(h, radix: 16);

    return v != null ? Color(v) : _presetColors[0];
  }

  static String _colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final title = _titleController.text.trim();
    final colorHex = _colorToHex(_pickedColor);
    try {
      await widget.onSave(title, colorHex);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.column != null;
    return AlertDialog(
      title: Text(isEdit ? 'Редактировать колонку' : 'Новая колонка'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например: В работе',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите название';
                  }

                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Text(
                'Цвет',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._presetColors.map((c) {
                    final selected = c.toARGB32() == _pickedColor.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _pickedColor = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
            ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
            : Text(isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
