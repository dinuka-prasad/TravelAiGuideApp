import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'ai_tips_screen.dart';
import 'trip_planner_screen.dart';
import 'planner_screen.dart';
import 'app_theme.dart';
import 'destinations.dart';
import 'universal_image.dart';
import 'database_service.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  const DetailScreen({super.key, required this.location});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isSaved = false;
  bool _checkingStatus = true;
  bool _photoPicking = false;
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoBase64;

  // New TripAdvisor and Interactive Features
  String _currentTab = 'Overview';
  bool _isUsd = true;
  late List<Map<String, dynamic>> _subLocations;

  @override
  void initState() {
    super.initState();
    _checkSavedStatus();
    _subLocations = getSubLocations(widget.location);
  }

  Future<void> _checkSavedStatus() async {
    final name = widget.location['name'] as String;
    final savedData = await WishlistManager.getData(name);
    if (mounted) {
      setState(() {
        _isSaved = savedData != null;
        if (savedData != null && savedData['photoNoteBase64'] != null) {
          _photoBase64 = savedData['photoNoteBase64'];
        }
        _checkingStatus = false;
      });
    }
  }

  Future<void> _toggleWishlist() async {
    final name = widget.location['name'] as String;
    if (_isSaved) {
      await WishlistManager.remove(name);
      if (mounted) {
        setState(() => _isSaved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed from Planner.'),
            backgroundColor: AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } else {
      final data = Map<String, dynamic>.from(widget.location);
      final color = data['tagColor'] as Color?;
      data['tagColorValue'] = color?.toARGB32();
      data.remove('tagColor');

      await WishlistManager.add(data);
      if (mounted) {
        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to Planner! ✈️'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photoPicking) return;
    setState(() {
      _photoPicking = true;
    });

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      
      if (!_isSaved) {
        await _toggleWishlist();
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        await WishlistManager.update(widget.location['name'], {'photoNoteBase64': base64String});

        if (mounted) {
          setState(() {
            _photoBase64 = base64String;
            _photoBytes = bytes;
            _photoName = picked.name;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _photoPicking = false;
        });
      }
    }
  }

  void _removePhoto() async {
    setState(() {
      _photoBytes = null;
      _photoName = null;
      _photoBase64 = null;
    });
  }

  void _showAddReviewBottomSheet() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add a review')),
      );
      return;
    }

    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Write a Review',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Your Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() {
                            rating = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Your Review Description',
                      hintText: 'Share your experience about this place...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final comment = commentController.text.trim();
                        if (comment.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a review description')),
                          );
                          return;
                        }

                        final userName = user.displayName ?? user.email?.split('@').first ?? 'Traveller';

                        try {
                          await FirebaseFirestore.instance.collection('reviews').add({
                            'destinationName': widget.location['name'],
                            'rating': rating,
                            'comment': comment,
                            'userId': user.uid,
                            'userName': userName,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Review submitted successfully!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSubLocationDetail(Map<String, dynamic> subLoc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SubLocationDetailModal(
          subLocation: subLoc,
          isUsd: _isUsd,
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        );
      },
    );
  }

  String _formatPrice(double usdPrice) {
    if (usdPrice == 0) return 'Free';
    if (_isUsd) {
      return '\$${usdPrice.toStringAsFixed(0)}';
    } else {
      return 'Rs. ${(usdPrice * 300).toStringAsFixed(0)}';
    }
  }

  Widget _buildTabs() {
    final tabs = ['Overview', 'Sights', 'Stays', 'Eats', 'Budget', 'Map'];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = _currentTab == tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(tab),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.primarySurface,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _currentTab = tab;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(widget.location['description'],
            style: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: Colors.black87)),
        const SizedBox(height: 24),

        Text('Highlights',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (widget.location['highlights'] as List<dynamic>).map((h) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(h.toString(),
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        Text('Photo Note',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        if (_photoBytes != null || _photoBase64 != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _photoBytes != null
                ? Image.memory(
                    _photoBytes!,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  )
                : Image.memory(
                    base64Decode(_photoBase64!),
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            _photoName ?? 'Selected photo',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: _photoPicking ? null : () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(110, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _photoPicking ? null : () => _pickPhoto(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentDark,
                minimumSize: const Size(110, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
            if (_photoBytes != null || _photoBase64 != null)
              OutlinedButton.icon(
                onPressed: _removePhoto,
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AiTipsScreen(location: widget.location)),
            ),
            icon: const Icon(Icons.auto_awesome, size: 20),
            label: const Text('Ask AI for Travel Tips',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              shadowColor: AppColors.accentDark.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AiTripPlannerScreen(location: widget.location)),
            ),
            icon: Icon(Icons.map_outlined, size: 20, color: AppColors.primary),
            label: Text('Plan My Trip with AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'User Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _showAddReviewBottomSheet,
              icon: const Icon(Icons.rate_review_outlined, size: 18),
              label: const Text('Write a Review'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildReviewsStream(),
      ],
    );
  }

  Widget _buildReviewsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('destinationName', isEqualTo: widget.location['name'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, color: Colors.grey.shade300, size: 40),
                const SizedBox(height: 8),
                Text(
                  'No reviews yet. Be the first to review!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final reviews = List<DocumentSnapshot>.from(docs);
        reviews.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;
            final userName = data['userName'] ?? 'Anonymous';
            final rating = data['rating'] ?? 5;
            final comment = data['comment'] ?? '';
            final ts = data['createdAt'] as Timestamp?;
            final dateStr = ts != null
                ? '${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2, '0')}-${ts.toDate().day.toString().padLeft(2, '0')}'
                : '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        starIdx < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSubLocationsTab(String category) {
    final filtered = _subLocations.where((sub) => sub['category'] == category).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.category_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'No ${category}s available here.',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final sub = filtered[index];
        return GestureDetector(
          onTap: () => _showSubLocationDetail(sub),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: UniversalImage(
                    imagePath: sub['img'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      height: 160,
                      color: AppColors.primarySurface,
                      child: Icon(Icons.image, color: AppColors.primary),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sub['name'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                '${sub['rating']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sub['description'],
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatPrice((sub['price'] as num).toDouble()),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'View Details →',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
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
      },
    );
  }

  Widget _buildMapTab() {
    final baseLat = (widget.location['lat'] as num?)?.toDouble() ?? 6.9271;
    final baseLng = (widget.location['lng'] as num?)?.toDouble() ?? 79.8612;

    return SizedBox(
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LocalMapWidget(
          destinationBaseCoords: LatLng(baseLat, baseLng),
          subLocations: _subLocations,
          onViewDetails: _showSubLocationDetail,
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 'Overview':
        return _buildOverviewTab();
      case 'Sights':
        return _buildSubLocationsTab('Sight');
      case 'Stays':
        return _buildSubLocationsTab('Stay');
      case 'Eats':
        return _buildSubLocationsTab('Eat');
      case 'Budget':
        return _buildSubLocationsTab('Budget');
      case 'Map':
        return _buildMapTab();
      default:
        return _buildOverviewTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color tagColor = widget.location['tagColor'] is Color
        ? widget.location['tagColor'] as Color
        : (widget.location['tagColorValue'] != null
            ? Color(widget.location['tagColorValue'] as int)
            : AppColors.primary);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.location['name'],
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              background: Stack(fit: StackFit.expand, children: [
                UniversalImage(
                  imagePath: widget.location['img'],
                  fit: BoxFit.cover,
                  errorWidget: Container(color: AppColors.primaryDark),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC1A006A)],
                    ),
                  ),
                ),
              ]),
            ),
            actions: [
              if (_checkingStatus)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? AppColors.accentLight : Colors.white,
                  ),
                  onPressed: _toggleWishlist,
                  tooltip: _isSaved ? 'Remove from Planner' : 'Save to Planner',
                ),
              // Currency Switcher
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isUsd = !_isUsd;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isUsd ? '\$ USD' : 'Rs. LKR',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(widget.location['tag'],
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('reviews')
                          .where('destinationName', isEqualTo: widget.location['name'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        double displayRating = (widget.location['rating'] as num?)?.toDouble() ?? 0.0;

                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          final docs = snapshot.data!.docs;
                          double totalRating = 0;
                          for (var doc in docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final r = data['rating'] ?? 5;
                            totalRating += r is num ? r.toDouble() : 5.0;
                          }
                          displayRating = totalRating / docs.length;
                        }

                        return Text(' ${displayRating.toStringAsFixed(1)} / 5.0',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15));
                      },
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sell_outlined, color: Color(0xFF2E7D32), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            _isUsd
                                ? (widget.location['cost'] as String)
                                : (widget.location['cost'] as String).replaceAllMapped(
                                    RegExp(r'\$(\d+)'),
                                    (match) => 'Rs. ${(int.parse(match.group(1)!) * 300)}',
                                  ),
                            style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoPill(Icons.location_on_outlined, AppColors.primary, widget.location['country']),
                      const SizedBox(width: 10),
                      _infoPill(Icons.calendar_month_outlined, AppColors.accentDark, widget.location['bestTime']),
                      const SizedBox(width: 10),
                      _infoPill(Icons.access_time, AppColors.primaryLight, widget.location['duration']),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 20),
                  _buildTabContent(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 🏨 Sub-Location Detail Modal & Booking Sheet
// ─────────────────────────────────────────────
class _SubLocationDetailModal extends StatefulWidget {
  final Map<String, dynamic> subLocation;
  final bool isUsd;
  final String uid;

  const _SubLocationDetailModal({
    required this.subLocation,
    required this.isUsd,
    required this.uid,
  });

  @override
  State<_SubLocationDetailModal> createState() => _SubLocationDetailModalState();
}

class _SubLocationDetailModalState extends State<_SubLocationDetailModal> {
  DateTime? _selectedDate;
  int _durationDays = 1;
  int _visitorsCount = 1;

  bool _isCheckingAvailability = false;
  String _availabilityStatus = ''; // 'checking', 'available', 'booked'
  String _availabilityMsg = '';
  bool _bookingSuccess = false;

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _checkAvailability();
    }
  }

  void _checkAvailability() async {
    if (_selectedDate == null) return;

    setState(() {
      _isCheckingAvailability = true;
      _availabilityStatus = 'checking';
    });

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final isWeekend = _selectedDate!.weekday == DateTime.saturday || _selectedDate!.weekday == DateTime.sunday;

    setState(() {
      _isCheckingAvailability = false;
      if (isWeekend) {
        _availabilityStatus = 'booked';
        _availabilityMsg = '🔴 Weekends are fully occupied! Try a weekday.';
      } else if (_visitorsCount > 6) {
        _availabilityStatus = 'booked';
        _availabilityMsg = '🔴 Group size exceeds maximum capacity (6 people).';
      } else {
        _availabilityStatus = 'available';
        _availabilityMsg = '🟢 Available! Confirm your booking below.';
      }
    });
  }

  Future<void> _createBooking() async {
    if (widget.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to make a booking.')),
      );
      return;
    }

    setState(() {
      _isCheckingAvailability = true;
    });

    try {
      final basePrice = (widget.subLocation['price'] as num?)?.toDouble() ?? 0.0;
      final category = widget.subLocation['category'] as String;
      final name = widget.subLocation['name'] as String;

      final nameLower = name.toLowerCase();
      final isStayLike = category == 'Stay' ||
          (category == 'Budget' &&
              (nameLower.contains('hostel') || nameLower.contains('guesthouse') || nameLower.contains('inn')));

      final totalPriceUsd = isStayLike ? basePrice * _durationDays * _visitorsCount : basePrice * _visitorsCount;
      final displayPriceStr = widget.isUsd ? '\$${totalPriceUsd.toInt()}' : 'Rs. ${(totalPriceUsd * 300).toInt()}';

      final bookingData = {
        'userId': widget.uid,
        'userEmail': FirebaseAuth.instance.currentUser?.email ?? '',
        'hotelId': name,
        'hotelName': name,
        'hotelImage': widget.subLocation['img'],
        'price': totalPriceUsd,
        'displayPrice': displayPriceStr,
        'location': name,
        'bookedAt': FieldValue.serverTimestamp(),
        'startDate': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'durationDays': _durationDays,
        'visitors': _visitorsCount,
        'bookingType': category,
      };

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).collection('bookings').add(bookingData);
      await FirebaseFirestore.instance.collection('bookings').add(bookingData);

      await DatabaseService.logNotification(
        uid: widget.uid,
        title: 'Booking Confirmed',
        message: 'Successfully booked $name ($category) for $displayPriceStr.',
        type: 'booking',
      );

      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
          _bookingSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAvailability = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatPrice(double usdPrice) {
    if (usdPrice == 0) return 'Free';
    if (widget.isUsd) {
      return '\$${usdPrice.toStringAsFixed(0)}';
    } else {
      return 'Rs. ${(usdPrice * 300).toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subLocation;
    final category = sub['category'] as String;
    final basePrice = (sub['price'] as num?)?.toDouble() ?? 0.0;

    final nameLower = sub['name'].toString().toLowerCase();
    final isStayLike = category == 'Stay' ||
        (category == 'Budget' &&
            (nameLower.contains('hostel') || nameLower.contains('guesthouse') || nameLower.contains('inn')));

    final totalPriceUsd = isStayLike ? basePrice * _durationDays * _visitorsCount : basePrice * _visitorsCount;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _bookingSuccess
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.check_circle, color: Colors.green, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'Booking Confirmed! 🎉',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'You successfully booked ${sub['name']}.\nCheck your profile page for detail receipts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Back to Destination'),
                ),
                const SizedBox(height: 16),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: UniversalImage(
                          imagePath: sub['img'],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            width: 80,
                            height: 80,
                            color: AppColors.primarySurface,
                            child: Icon(Icons.image, color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                category.toUpperCase(),
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sub['name'],
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${sub['rating']} rating',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    sub['description'],
                    style: TextStyle(color: AppColors.textSecondary, height: 1.4, fontSize: 13),
                  ),
                  if (sub['amenities'] != null) ...[
                    const SizedBox(height: 14),
                    const Text('Amenities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (sub['amenities'] as List<dynamic>).map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(a.toString(), style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ],
                  const Divider(height: 28),
                  const Text('Select Dates & Guests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            _selectedDate == null
                                ? 'Select Date'
                                : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () {
                                  if (_visitorsCount > 1) {
                                    setState(() {
                                      _visitorsCount--;
                                    });
                                    _checkAvailability();
                                  }
                                },
                              ),
                              Text('$_visitorsCount guests', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  if (_visitorsCount < 10) {
                                    setState(() {
                                      _visitorsCount++;
                                    });
                                    _checkAvailability();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isStayLike) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration (Nights)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('$_durationDays nights', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: _durationDays.toDouble(),
                      min: 1,
                      max: 14,
                      divisions: 13,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _durationDays = val.round();
                        });
                        _checkAvailability();
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Availability Indicator
                  if (_isCheckingAvailability)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  else if (_availabilityMsg.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _availabilityStatus == 'available' ? Colors.green[50] : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _availabilityMsg,
                        style: TextStyle(
                          color: _availabilityStatus == 'available' ? Colors.green[800] : Colors.red[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Budget', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            _formatPrice(totalPriceUsd),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _availabilityStatus == 'available' && !_isCheckingAvailability ? _createBooking : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(140, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Book Now'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
// 🗺️ Local Map Widget showing Sub-Locations
// ─────────────────────────────────────────────
class LocalMapWidget extends StatefulWidget {
  final LatLng destinationBaseCoords;
  final List<Map<String, dynamic>> subLocations;
  final Function(Map<String, dynamic>) onViewDetails;

  const LocalMapWidget({
    super.key,
    required this.destinationBaseCoords,
    required this.subLocations,
    required this.onViewDetails,
  });

  @override
  State<LocalMapWidget> createState() => _LocalMapWidgetState();
}

class _LocalMapWidgetState extends State<LocalMapWidget> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String _routeDistance = '';
  String _routeDuration = '';

  LatLng? _currentLocation;
  bool _isLoadingLocation = true;
  Map<String, dynamic>? _selectedItem;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _mapController.move(widget.destinationBaseCoords, 14.0);
      }
    } catch (e) {
      debugPrint('Error getting GPS in Local Map: $e');
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(6.9271, 79.8612); // Colombo fallback
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _fetchRoute(LatLng endPoint) async {
    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
    });

    final startPoint = _currentLocation ?? const LatLng(6.9271, 79.8612);
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${startPoint.longitude},${startPoint.latitude};'
      '${endPoint.longitude},${endPoint.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>;

        if (routes.isNotEmpty) {
          final geometry = routes[0]['geometry'] as Map<String, dynamic>;
          final coordinates = geometry['coordinates'] as List<dynamic>;

          final legs = routes[0]['legs'] as List<dynamic>;
          double distanceKm = 0.0;
          double durationMins = 0.0;
          if (legs.isNotEmpty) {
            distanceKm = (legs[0]['distance'] as num).toDouble() / 1000.0;
            durationMins = (legs[0]['duration'] as num).toDouble() / 60.0;
          }

          final List<LatLng> points = coordinates.map((c) {
            return LatLng(c[1] as double, c[0] as double);
          }).toList();

          setState(() {
            _routePoints = points;
            _routeDistance = '${distanceKm.toStringAsFixed(1)} km';
            if (durationMins > 60) {
              final hrs = (durationMins / 60).floor();
              final mins = (durationMins % 60).round();
              _routeDuration = '${hrs}h ${mins}m';
            } else {
              _routeDuration = '${durationMins.round()}m';
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Local map route failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sight':
        return Colors.blue;
      case 'Stay':
        return Colors.green;
      case 'Eat':
        return Colors.orange;
      case 'Budget':
        return Colors.purple;
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Sight':
        return Icons.place;
      case 'Stay':
        return Icons.hotel;
      case 'Eat':
        return Icons.restaurant;
      case 'Budget':
        return Icons.attach_money;
      default:
        return Icons.location_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.destinationBaseCoords,
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mytravelapp',
            ),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: AppColors.primary,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 30,
                    height: 30,
                    child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                  ),
                ...widget.subLocations.map((sub) {
                  final lat = (sub['lat'] as num?)?.toDouble() ?? 0.0;
                  final lng = (sub['lng'] as num?)?.toDouble() ?? 0.0;
                  final isSelected = _selectedItem != null && _selectedItem!['name'] == sub['name'];
                  final color = _getCategoryColor(sub['category'] as String);

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedItem = sub;
                          _routePoints = [];
                          _routeDistance = '';
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.red : color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Icon(
                          _getCategoryIcon(sub['category'] as String),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        if (_isLoadingLocation)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5)),
                  SizedBox(width: 6),
                  Text('GPS...', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
        if (_routeDistance.isNotEmpty)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Text(
                'Route: $_routeDistance | Time: $_routeDuration',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
        if (_selectedItem != null)
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: UniversalImage(
                            imagePath: _selectedItem!['img'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedItem!['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(
                                '${_selectedItem!['category']} • ★${_selectedItem!['rating']}',
                                style: const TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => widget.onViewDetails(_selectedItem!),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Details', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoadingRoute
                                ? null
                                : () => _fetchRoute(LatLng(_selectedItem!['lat'] as double, _selectedItem!['lng'] as double)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoadingRoute
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white))
                                : const Text('Directions', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}