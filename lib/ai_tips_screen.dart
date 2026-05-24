import 'package:flutter/material.dart';
import 'ai_service.dart';
import 'markdown_renderer.dart';
import 'app_theme.dart';

class AiTipsScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  const AiTipsScreen({super.key, required this.location});

  @override
  State<AiTipsScreen> createState() => _AiTipsScreenState();
}

class _AiTipsScreenState extends State<AiTipsScreen> {
  String _response = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _response = '';
    });
    try {
      final result = await callAiApi(
        systemPrompt:
            'You are an expert travel guide specialising in Sri Lanka. Be practical, enthusiastic, and specific.',
        userMessage:
            '''Provide comprehensive travel tips for ${widget.location['name']}, Sri Lanka.

Format with bold section headers:
**🏛️ Overview**
**📍 Top Things To Do**
**🍽️ Local Food & Drinks**
**🚗 Getting There & Around**
**🌤️ Best Time to Visit**
**💡 Pro Tips**
**💰 Budget Guide**
**⚠️ Important Notes**

Use bullet points (- ) within sections. Be specific to ${widget.location['name']}.''',
        maxTokens: 2000,
      );
      if (mounted) setState(() => _response = result);
    } catch (e) {
      if (mounted) {
        setState(() =>
            _response =
                '⚠️ Could not load tips. Please check your API key in `ai_service.dart` and try again.\n\n$e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('AI Tips: ${widget.location['name']}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_loading)
            IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _load,
                tooltip: 'Regenerate'),
        ],
      ),
      body: _loading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 20)
                    ]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text(
                      'AI is crafting tips for\n${widget.location['name']}…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                // Header banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.accentLight, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Travel Guide',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                          Text(widget.location['name'],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15)
                    ],
                  ),
                  child: MarkdownText(text: _response),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }
}
