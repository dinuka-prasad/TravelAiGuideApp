import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detail_screen.dart';
import 'app_theme.dart';

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

  static Future<bool> isSaved(String name) async {
    if (_uid.isEmpty) return false;
    final snap = await _col.where('name', isEqualTo: name).get();
    return snap.docs.isNotEmpty;
  }
}

// ─────────────────────────────────────────────
// Planner Screen
// ─────────────────────────────────────────────
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

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
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final items = snap.data ?? [];
                return items.isEmpty
                    ? _buildEmpty(context)
                    : Column(
                        children: [
                          // Travel alert
                          _buildAlert(),
                          // Count header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  'Saved Destinations (${items.length})',
                                  style: const TextStyle(
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

  Widget _buildAlert() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Travel Alert',
                    style: TextStyle(
                        color: Color(0xFFF57F17),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                  'Best time to visit: Jan – Apr for most destinations. Book early!',
                  style: TextStyle(
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

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bookmark_border,
                size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('No Saved Destinations',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
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
                    child: const Text('Clear',
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
  const _WishlistCard({required this.destination});

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
                  child: Image.network(
                    destination['img'] ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.primarySurface,
                      child: const Icon(Icons.image,
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
                          style: const TextStyle(
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
                  icon: const Icon(Icons.bookmark_remove,
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
