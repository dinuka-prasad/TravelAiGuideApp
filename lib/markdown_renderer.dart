import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// SIMPLE MARKDOWN RENDERER
// ─────────────────────────────────────────────
class MarkdownText extends StatelessWidget {
  final String text;
  const MarkdownText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: text.split('\n').map(_buildLine).toList(),
    );
  }

  Widget _buildLine(String raw) {
    final line = raw.trim();
    if (line.isEmpty) return const SizedBox(height: 6);

    // Day header **📅 Day X …**
    if ((line.startsWith('**📅') ||
            (line.startsWith('**') && line.contains('Day '))) &&
        line.endsWith('**')) {
      final content = line.replaceAll('**', '');
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: const Border(
                left: BorderSide(color: Colors.teal, width: 4)),
          ),
          child: Text(content,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004D40))),
        ),
      );
    }

    // Section header **emoji text**
    if (line.startsWith('**') &&
        line.endsWith('**') &&
        line.length > 4) {
      final content = line.substring(2, line.length - 2);
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(content,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal)),
      );
    }

    // Bullet
    if (line.startsWith('- ') || line.startsWith('• ')) {
      final content = line.replaceFirst(RegExp(r'^[-•] '), '');
      return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ',
                style: TextStyle(
                    color: Colors.teal,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Expanded(child: _richText(content, 14.5)),
          ],
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: _richText(line, 14.5));
  }

  Widget _richText(String text, double size) {
    final parts = text.split('**');
    if (parts.length <= 1) {
      return Text(text,
          style:
              TextStyle(fontSize: size, color: Colors.black87, height: 1.55));
    }
    final spans = <TextSpan>[];
    for (int i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          fontSize: size,
          fontWeight: i.isOdd ? FontWeight.bold : FontWeight.normal,
          color: i.isOdd ? const Color(0xFF1A1A2E) : Colors.black87,
          height: 1.55,
        ),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }
}
