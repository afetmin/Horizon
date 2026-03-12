import 'package:flutter/material.dart';

class ManifestUrlDialog extends StatefulWidget {
  const ManifestUrlDialog({
    super.key,
    required this.initialValue,
  });

  final String initialValue;

  @override
  State<ManifestUrlDialog> createState() => _ManifestUrlDialogState();
}

class _ManifestUrlDialogState extends State<ManifestUrlDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Manifest URL'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          labelText: 'Remote manifest URL',
          hintText: 'https://cdn.jsdelivr.net/gh/owner/repo@gh-pages/api/mobile-manifest.json',
          errorText: _errorText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    final uri = Uri.tryParse(value);
    final isValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority;

    if (!isValid) {
      setState(() {
        _errorText = 'Enter a valid http/https URL.';
      });
      return;
    }

    Navigator.of(context).pop(value);
  }
}
