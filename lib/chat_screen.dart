import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart';
import 'app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  static const List<String> _quickChips = [
    '🌴 Best time to visit?',
    '💰 Budget tips',
    '🦁 Wildlife spots',
    '🏖️ Best beaches',
    '🍛 Local food',
    '🚂 Train routes',
  ];

  static const String _systemPrompt =
      'You are an expert AI travel guide for Sri Lanka. '
      'You have deep knowledge of Sri Lankan culture, history, destinations, food, transport, weather, costs, safety tips, and travel logistics. '
      'Be warm, enthusiastic, practical, and specific. Keep responses concise but helpful. Use emojis naturally.';

  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isHistoryLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final loaded = snapshot.docs.map((doc) {
          final data = doc.data();
          return _ChatMessage(
            text: data['text'] ?? '',
            isUser: data['isUser'] ?? false,
            isError: data['isError'] ?? false,
          );
        }).toList();

        setState(() {
          _messages.clear();
          _messages.addAll(loaded);
          _isHistoryLoading = false;
        });
      } else {
        setState(() {
          _messages.clear();
          _messages.add(const _ChatMessage(
            text:
                "Hello! I'm your AI travel assistant for Sri Lanka 🇱🇰\n\nAsk me anything — best time to visit, hidden gems, food recommendations, budget tips, or help planning your itinerary!",
            isUser: false,
          ));
          _isHistoryLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> _saveMessageToFirestore(String text, bool isUser, {bool isError = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .add({
        'text': text,
        'isUser': isUser,
        'isError': isError,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving message to Firestore: $e');
    }
  }

  Future<void> _clearChatHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('chat_history')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = text.trim();
    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userMsg, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    await _saveMessageToFirestore(userMsg, true);

    try {
      final response = await callAiApi(
        systemPrompt: _systemPrompt,
        userMessage: userMsg,
        maxTokens: 800,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
        _scrollToBottom();
      }

      await _saveMessageToFirestore(response, false);
    } catch (e) {
      final errorMsg = '⚠️ Sorry, I couldn\'t reach the AI. Please check your API key in `ai_service.dart` and try again.\n\nError: $e';
      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(
            text: errorMsg,
            isUser: false,
            isError: true,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
      }
      await _saveMessageToFirestore(errorMsg, false, isError: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.auto_awesome,
                  color: AppColors.accentLight, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Travel Assistant',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text('Powered by Gemini AI',
                    style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              setState(() {
                _messages.clear();
                _messages.add(const _ChatMessage(
                  text:
                      "Hello! I'm your AI travel assistant for Sri Lanka 🇱🇰\n\nAsk me anything — best time to visit, hidden gems, food recommendations, budget tips, or help planning your itinerary!",
                  isUser: false,
                ));
              });
              await _clearChatHistory();
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: _isHistoryLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(_messages[i]);
              },
            ),
          ),

          // Quick suggestion chips (shown only near start)
          if (_messages.length <= 2)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text('Quick questions',
                        style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                  ),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _quickChips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => _sendMessage(_quickChips[i]),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(_quickChips[i],
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask about Sri Lanka…',
                      hintStyle:
                          TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(_inputController.text),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? Colors.grey[300]
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _isLoading
                          ? []
                          : [
                              BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4))
                            ],
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isLoading ? Colors.grey : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: msg.isError
                    ? Colors.red[50]
                    : AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                msg.isError ? Icons.error_outline : Icons.auto_awesome,
                color: msg.isError ? AppColors.error : AppColors.primary,
                size: 18,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? AppColors.primary
                    : msg.isError
                        ? Colors.red[50]
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: Offset(0, 2))
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser
                      ? Colors.white
                      : msg.isError
                          ? AppColors.error
                          : Colors.black87,
                  fontSize: 14,
                  height: 1.55,
                ),
              ),
            ),
          ),
          if (msg.isUser) SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _Dot(delay: i * 200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatMessage(
      {required this.text, required this.isUser, this.isError = false});
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.0, end: 1.0).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        margin: EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8 + (_anim.value * 4),
        decoration: BoxDecoration(
          color: AppColors.primary
              .withValues(alpha: 0.5 + _anim.value * 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
