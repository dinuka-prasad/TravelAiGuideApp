import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'app_theme.dart';
import 'universal_image.dart';
import 'chat_screen.dart';
import 'planner_screen.dart';
import 'hotel_booking_screen.dart';
import 'hotel_detail_screen.dart';
import 'hotel_model.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@').first ?? 'Traveller';
    final uid = user?.uid ?? '';
    final dataProvider = Provider.of<DataProvider>(context);

    if (dataProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final destinations = dataProvider.destinations;
    final hotels = dataProvider.hotels;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    BoxDecoration(gradient: AppColors.heroGradient),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60,
                      left: -30,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.travel_explore,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          color: AppColors.accentLight,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM d, yyyy')
                                            .format(DateTime.now()),
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              'Good ${_greeting()}, $displayName! 👋',
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Your Travel Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats Row ──
                _buildStatsRow(uid, context, destinations.length),
                SizedBox(height: 20),

                // ── Quick Actions ──
                Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.auto_awesome,
                        label: 'AI Chat',
                        subtitle: 'Ask anything',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AiChatScreen()),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.hotel_outlined,
                        label: 'Hotels',
                        subtitle: 'Find a stay',
                        color: AppColors.accentDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HotelBookingScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.bookmark_outline,
                        label: 'Wishlist',
                        subtitle: 'Saved places',
                        color: Colors.teal,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PlannerScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Wishlist Preview ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saved Wishlist',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => PlannerScreen()),
                      ),
                      child: Text('View All',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                uid.isNotEmpty
                    ? _buildWishlistPreview(uid)
                    : _EmptyWishlistCard(),
                SizedBox(height: 20),

                // ── Recent Itineraries ──
                Text('Recent Itineraries',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                uid.isNotEmpty
                    ? _buildItinerariesPreview(uid)
                    : const _EmptyItineraryCard(),

                // ── Recommended Stays ──
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recommended Stays',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => HotelBookingScreen()),
                      ),
                      child: Text('View All',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: hotels.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 16),
                    itemBuilder: (ctx, i) => _HotelPickCard(hotel: hotels[i]),
                  ),
                ),

                // ── Destination Highlights ──
                SizedBox(height: 20),
                Text('Top Picks',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: destinations.take(5).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (ctx, i) =>
                        _DestPickCard(d: destinations[i]),
                  ),
                ),
                const SizedBox(height: 30),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildStatsRow(String uid, BuildContext context, int destCount) {
    return StreamBuilder<QuerySnapshot>(
      stream: uid.isNotEmpty
          ? FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('favorites')
              .snapshots()
          : null,
      builder: (ctx, wishlistSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: uid.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('itineraries')
                  .snapshots()
              : null,
          builder: (ctx, itiSnap) {
            final wishlistCount =
                wishlistSnap.data?.docs.length ?? 0;
            final itiCount = itiSnap.data?.docs.length ?? 0;
            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.bookmark,
                    value: '$wishlistCount',
                    label: 'Saved',
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.map,
                    value: '$itiCount',
                    label: 'Itineraries',
                    color: AppColors.accentDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.explore,
                    value: '$destCount',
                    label: 'Destinations',
                    color: Color(0xFF00897B),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWishlistPreview(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .limit(3)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const _EmptyWishlistCard();
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _WishlistPreviewRow(name: d['name'] ?? '', tag: d['tag'] ?? '');
          }).toList(),
        );
      },
    );
  }

  Widget _buildItinerariesPreview(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('itineraries')
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const _EmptyItineraryCard();
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return _ItineraryPreviewRow(
              location: d['location'] ?? '',
              days: d['days'] ?? 1,
              style: d['style'] ?? '',
              budget: d['budget'] ?? '',
              createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────── Stat Card ───────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────── Action Card ───────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────── Wishlist Preview Row ───────
class _WishlistPreviewRow extends StatelessWidget {
  final String name;
  final String tag;
  const _WishlistPreviewRow({required this.name, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bookmark, color: AppColors.primary, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(name,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(tag,
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────── Itinerary Preview Row ───────
class _ItineraryPreviewRow extends StatelessWidget {
  final String location;
  final int days;
  final String style;
  final String budget;
  final DateTime? createdAt;

  const _ItineraryPreviewRow({
    required this.location,
    required this.days,
    required this.style,
    required this.budget,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentDark.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.map, color: AppColors.accentDark, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('$days days · $budget · $style',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (createdAt != null)
            Text(
              DateFormat('MMM d').format(createdAt!),
              style: TextStyle(
                  fontSize: 11, color: AppColors.textHint),
            ),
        ],
      ),
    );
  }
}

class _EmptyWishlistCard extends StatelessWidget {
  const _EmptyWishlistCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_border, color: AppColors.textHint, size: 28),
          SizedBox(width: 12),
          Text('No saved destinations yet.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EmptyItineraryCard extends StatelessWidget {
  const _EmptyItineraryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.map_outlined, color: AppColors.textHint, size: 28),
          SizedBox(width: 12),
          Text('No itineraries generated yet.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────── Destination Pick Card (horizontal) ───────
class _DestPickCard extends StatelessWidget {
  final Map<String, dynamic> d;
  const _DestPickCard({required this.d});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              UniversalImage(
                imagePath: d['img'],
                fit: BoxFit.cover,
                errorWidget: Container(color: AppColors.primarySurface),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65)
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  d['name'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelPickCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelPickCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: hotel)),
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: UniversalImage(
                  imagePath: hotel.image,
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        hotel.rating.toString(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Spacer(),
                      Text(
                        '\$${hotel.price.toInt()}',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
