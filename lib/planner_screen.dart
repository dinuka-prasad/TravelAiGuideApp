import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';
import 'app_theme.dart';
import 'ai_service.dart';
import 'universal_image.dart';

// ─────────────────────────────────────────────
// Wishlist Manager – Firestore-backed singleton
// ─────────────────────────────────────────────
class WishlistManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String get _uid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  static CollectionReference get _col =>
      _db.collection('users').doc(_uid).collection('wishlist');

  static Stream<List<Map<String, dynamic>>> get stream {
    if (_uid.isEmpty) return Stream.value([]);
    return _col.snapshots().map((snap) => snap.docs
        .map((d) => {...(d.data() as Map<String, dynamic>), 'docId': d.id})
        .toList());
  }

  static Future<void> add(Map<String, dynamic> destination) async {
    if (_uid.isEmpty) return;
    // Check if already saved
    final existing = await _col
        .where('name', isEqualTo: destination['name'])
        .get();
    if (existing.docs.isNotEmpty) return;

    // Strip non-serializable fields (Color)
    final data = Map<String, dynamic>.from(destination)
      ..remove('tagColor');
    await _col.add({...data, 'savedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> remove(String name) async {
    if (_uid.isEmpty) return;
    final snap = await _col.where('name', isEqualTo: name).get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  static Future<void> update(String name, Map<String, dynamic> data) async {
    if (_uid.isEmpty) return;
    final snap = await _col.where('name', isEqualTo: name).get();
    for (final doc in snap.docs) {
      await doc.reference.update(data);
    }
  }

  static Future<bool> isSaved(String name) async {
    if (_uid.isEmpty) return false;
    final snap = await _col.where('name', isEqualTo: name).get();
    return snap.docs.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getData(String name) async {
    if (_uid.isEmpty) return null;
    final snap = await _col.where('name', isEqualTo: name).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data() as Map<String, dynamic>;
  }
}

// ─────────────────────────────────────────────
// Planner Screen
// ─────────────────────────────────────────────
class PlannerScreen extends StatelessWidget {
  PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Travel Planner',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text('Your saved wishlist',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        actions: [
          _ClearAllButton(uid: uid),
        ],
      ),
      body: uid.isEmpty
          ? const Center(child: Text('Please log in to view your planner.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: WishlistManager.stream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final items = snap.data ?? [];
                return items.isEmpty
                    ? _buildEmpty(context)
                    : Column(
                        children: [
                          // Dynamic AI Travel alert
                          DynamicAlertBanner(
                            destinations: items.map((e) => e['name'] as String).toList(),
                          ),
                          // Count header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  'Saved Destinations (${items.length})',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          // Wishlist items
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: items.length,
                              itemBuilder: (ctx, i) =>
                                  _WishlistCard(destination: items[i]),
                            ),
                          ),
                        ],
                      );
              },
            ),
    );
  }



  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bookmark_border,
                size: 64, color: AppColors.primary),
          ),
          SizedBox(height: 20),
          Text('No Saved Destinations',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on any\ndestination to add it here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ClearAllButton extends StatelessWidget {
  final String uid;
  const _ClearAllButton({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: WishlistManager.stream,
      builder: (ctx, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) return const SizedBox.shrink();
        return TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Clear Wishlist'),
                content: const Text('Remove all saved destinations?'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () async {
                      for (final d in items) {
                        await WishlistManager.remove(d['name']);
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text('Clear',
                        style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            );
          },
          child: const Text('Clear All',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
        );
      },
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final Map<String, dynamic> destination;
  _WishlistCard({required this.destination});

  @override
  Widget build(BuildContext context) {
    // Reconstruct tagColor from stored integer or fallback to primary
    final tagColorVal = destination['tagColorValue'] as int?;
    final tagColor = tagColorVal != null
        ? Color(tagColorVal)
        : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailScreen(location: destination)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: UniversalImage(
                    imagePath: destination['img'] ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: 80,
                      height: 80,
                      color: AppColors.primarySurface,
                      child: Icon(Icons.image,
                          color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(destination['name'] ?? '',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: tagColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(destination['tag'] ?? '',
                                style: TextStyle(
                                    color: tagColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          Text(' ${destination['rating'] ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today,
                              color: Colors.grey[400], size: 12),
                          Text(' ${destination['bestTime'] ?? ''}',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Remove button
                IconButton(
                  icon: Icon(Icons.bookmark_remove,
                      color: AppColors.error, size: 22),
                  onPressed: () =>
                      WishlistManager.remove(destination['name']),
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dynamic AI Travel Alerts Banner
// ─────────────────────────────────────────────
class DynamicAlertBanner extends StatefulWidget {
  final List<String> destinations;
  const DynamicAlertBanner({super.key, required this.destinations});

  @override
  State<DynamicAlertBanner> createState() => _DynamicAlertBannerState();
}

class _DynamicAlertBannerState extends State<DynamicAlertBanner> {
  String _alertText = 'Best time to visit: Jan – Apr for most destinations. Book early!';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchAlert();
  }

  @override
  void didUpdateWidget(covariant DynamicAlertBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentList = widget.destinations;
    final oldList = oldWidget.destinations;

    bool listChanged = currentList.length != oldList.length;
    if (!listChanged) {
      for (int i = 0; i < currentList.length; i++) {
        if (currentList[i] != oldList[i]) {
          listChanged = true;
          break;
        }
      }
    }

    if (listChanged) {
      _fetchAlert();
    }
  }

  Future<void> _fetchAlert() async {
    if (widget.destinations.isEmpty) {
      if (mounted) {
        setState(() {
          _alertText = 'Add destinations to your planner to get dynamic travel alerts & weather advisories!';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final destsJoined = widget.destinations.join(', ');
      final result = await callAiApi(
        systemPrompt: 'You are a real-time travel advisory system for Sri Lanka. '
            'Generate a very brief, practical travel advisory/alert (max 2 sentences) '
            'about the weather, seasonal highlights, or safety warnings for the specified destinations. '
            'Keep it concise, realistic, and direct. Use emojis naturally.',
        userMessage: 'Generate real-time travel alerts/warnings/weather advisories for these Sri Lankan places: $destsJoined.',
        maxTokens: 150,
      );

      if (mounted) {
        setState(() {
          _alertText = result.trim();
        });
      }
    } catch (e) {
      debugPrint('Error fetching dynamic alerts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFECB3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active,
                color: Color(0xFFF57F17), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'AI Travel Alert',
                      style: TextStyle(
                          color: Color(0xFFF57F17),
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF57F17)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _alertText,
                  style: const TextStyle(
                      color: Color(0xFFF9A825),
                      fontSize: 12,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
