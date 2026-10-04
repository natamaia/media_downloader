import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool isExtracting;
  final VoidCallback onExtract;
  final VoidCallback onClear;

  const UrlInputField({
    super.key,
    required this.controller,
    required this.isExtracting,
    required this.onExtract,
    required this.onClear,
  });

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Cole o link da mídia',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            decoration: InputDecoration(
              hintText: 'YouTube, Spotify, Instagram, TikTok...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onClear();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    tooltip: 'Colar da área de transferência',
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null && data!.text!.isNotEmpty) {
                        widget.controller.text = data.text!;
                        setState(() {});
                        widget.onExtract();
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => widget.onExtract(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: widget.isExtracting || widget.controller.text.trim().isEmpty
                  ? null
                  : widget.onExtract,
              icon: widget.isExtracting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                widget.isExtracting ? 'Extraindo metadados...' : 'Obter Informações',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
