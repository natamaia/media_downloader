import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorHandler {
  static void copyToClipboard(BuildContext context, String errorText, {String? label}) {
    Clipboard.setData(ClipboardData(text: errorText));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label ?? 'Erro copiado para a área de transferência!',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E2E3A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void showErrorDetailsDialog(
    BuildContext context, {
    required String title,
    required String errorMessage,
    String? technicalDetails,
  }) {
    final fullText = StringBuffer()
      ..writeln('=== MediaDownloader Error Diagnostic ===')
      ..writeln('Timestamp: ${DateTime.now().toIso8601String()}')
      ..writeln('Summary: $title')
      ..writeln('Message: $errorMessage');
    if (technicalDetails != null && technicalDetails.isNotEmpty) {
      fullText.writeln('Technical Details:\n$technicalDetails');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage, style: const TextStyle(fontSize: 14)),
              if (technicalDetails != null && technicalDetails.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Detalhes Técnicos / SQL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    technicalDetails,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.orangeAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copiar Tudo'),
            onPressed: () {
              copyToClipboard(context, fullText.toString());
              Navigator.pop(ctx);
            },
          ),
          TextButton(
            child: const Text('Fechar'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }
}
