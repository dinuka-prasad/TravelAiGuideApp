import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // MarkdownBody පාවිච්චි කිරීමට එකතු කරන ලදී
import 'ai_service.dart';
import 'app_theme.dart';

class AiTripPlannerScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  // Error 3: tcation වෙනුවට location ලෙස නිවැරදි කර, constructor එක හරියටම සැකසුවා
  const AiTripPlannerScreen({super.key, required this.location});

  @override
  State<AiTripPlannerScreen> createState() => _AiTripPlannerScreenState();
}

// Error 4: State<AiTnerScreen> වෙනුවට State<AiTripPlannerScreen> ලෙස නිවැරදි කරන ලදී
class _AiTripPlannerScreenState extends State<AiTripPlannerScreen> {
  int _days = 3;
  String _budget = 'Mid-range';
  String _style = 'Cultural & Sightseeing';
  String _plan = '';
  bool _loading = false;
  bool _saved = false;

  static const _budgets = ['Budget', 'Mid-range', 'Luxury'];
  static const _styles = [
    'Cultural & Sightseeing',
    'Adventure & Outdoor',
    'Food & Local Life',
    'Relaxation & Wellness',
    'Family Friendly',
  ];

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _plan = '';
      _saved = false;
    });
    try {
      final result = await callAiApi(
        systemPrompt:
            'You are an expert Sri Lanka travel planner. Create detailed, practical day-by-day itineraries.',
        userMessage:
            '''Create a $_days-day itinerary for ${widget.location['name']}, Sri Lanka.
Travel Style: $_style  |  Budget: $_budget

Format strictly as:
**📅 Day 1: [Creative Theme]**
- Morning: ...
- Afternoon: ...
- Evening: ...
- 🍽️ Eat at: ...
- 💡 Tip: ...

Repeat for each day. Include specific places, costs in USD, and transport tips.
Tailor everything for a $_budget traveller who loves $_style.''',
        maxTokens: 2500,
      );
      if (mounted) setState(() => _plan = result);
    } catch (e) {
      if (mounted) {
        setState(
          () => _plan = '⚠️ Error generating plan. Please try again.\n\n$e',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _plan.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .add({
        'location': widget.location['name'],
        'days': _days,
        'budget': _budget,
        'style': _style,
        'plan': _plan,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _saved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Itinerary saved! View it in your Dashboard.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Plan: ${widget.location['name']}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Config card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customise Your Trip',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Days
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Duration',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_days Days',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.primary,
                      thumbColor: AppColors.primary,
                      inactiveTrackColor: AppColors.primary.withValues(
                        alpha: 0.2,
                      ),
                      overlayColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: _days.toDouble(),
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: '$_days days',
                      onChanged: (v) => setState(() => _days = v.round()),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Budget
                  const Text(
                    'Budget',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _budgets.map((b) {
                      final sel = _budget == b;
                      return ChoiceChip(
                        label: Text(b),
                        selected: sel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.primarySurface,
                        labelStyle: TextStyle(
                          color: sel ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _budget = b),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Style
                  const Text(
                    'Travel Style',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _styles.map((s) {
                      final sel = _style == s;
                      return ChoiceChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        selected: sel,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.primarySurface,
                        labelStyle: TextStyle(
                          color: sel ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) => setState(() => _style = s),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _loading ? 'Generating…' : 'Generate My Itinerary',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        elevation: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Plan result
            if (_plan.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.map,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your $_days-Day Itinerary',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!_saved)
                          IconButton(
                            icon: const Icon(
                              Icons.save_alt,
                              color: AppColors.primary,
                            ),
                            onPressed: _saveToFirestore,
                            tooltip: 'Save to Dashboard',
                          ),
                        if (_saved)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                          ),
                      ],
                    ),
                    const Divider(height: 24),
                    
                    // Error 5: MarkdownText වෙනුවට නිල flutter_markdown එකේ MarkdownBody යෙදුවා
                    MarkdownBody(
                      data: _plan,
                      selectable: true,
                    ),
                    
                    const SizedBox(height: 16),
                    if (!_saved)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saveToFirestore,
                          icon: const Icon(
                            Icons.save_alt,
                            color: AppColors.primary,
                          ),
                          label: const Text(
                            'Save to Dashboard',
                            style: TextStyle(color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
