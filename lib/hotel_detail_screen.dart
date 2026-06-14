import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hotel_model.dart';
import 'app_theme.dart';
import 'universal_image.dart';
import 'database_service.dart';

class HotelDetailScreen extends StatelessWidget {
  final Hotel hotel;
  const HotelDetailScreen({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: UniversalImage(
                imagePath: hotel.image,
                fit: BoxFit.cover,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hotel.name,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  hotel.location,
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: AppColors.accent, size: 18),
                            SizedBox(width: 4),
                            Text(
                              hotel.rating.toString(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    hotel.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: hotel.amenities.map((amenity) => _AmenityChip(label: amenity)).toList(),
                  ),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                Text(
                  '\$${hotel.price.toInt()}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to book hotels')),
                    );
                    return;
                  }

                  try {
                    final bookingData = {
                      'userId': uid,
                      'userEmail': FirebaseAuth.instance.currentUser?.email ?? '',
                      'hotelId': hotel.id,
                      'hotelName': hotel.name,
                      'hotelImage': hotel.image,
                      'price': hotel.price,
                      'location': hotel.location,
                      'bookedAt': FieldValue.serverTimestamp(),
                      'bookingType': 'Stay',
                    };

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('bookings')
                        .add(bookingData);

                    await FirebaseFirestore.instance
                        .collection('bookings')
                        .add(bookingData);

                    await DatabaseService.logNotification(
                      uid: uid,
                      title: 'Hotel Booking Confirmed',
                      message: 'Successfully booked ${hotel.name} at \$${hotel.price.toInt()}/night.',
                      type: 'booking',
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Booking successful! View it in your Profile.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Booking failed: $e'), backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Text(
        label,
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
    );
  }
}
