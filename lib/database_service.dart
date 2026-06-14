import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'destinations.dart';
import 'hotel_data.dart';

class DatabaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if 'destinations' and 'hotels' are empty, and seed them.
  static Future<void> bootstrapDatabase() async {
    try {
      // 1. Seed destinations collection if empty
      final destSnapshot = await _db.collection('destinations').limit(1).get();
      if (destSnapshot.docs.isEmpty) {
        debugPrint('Seeding destinations to Firestore...');
        final batch = _db.batch();
        for (var dest in kDestinations) {
          final docRef = _db.collection('destinations').doc();
          final Map<String, dynamic> data = Map<String, dynamic>.from(dest);

          // Convert UI Colors to ARGB values for Firestore storage
          if (data['tagColor'] is Color) {
            data['tagColorValue'] = (data['tagColor'] as Color).toARGB32();
          }
          data.remove('tagColor');

          // Process nested subLocations to clean their Color types too
          if (data['subLocations'] != null) {
            final List<dynamic> subs = data['subLocations'];
            final cleanSubs = subs.map((sub) {
              final subMap = Map<String, dynamic>.from(sub);
              if (subMap['tagColor'] is Color) {
                subMap['tagColorValue'] = (subMap['tagColor'] as Color).toARGB32();
              }
              subMap.remove('tagColor');
              return subMap;
            }).toList();
            data['subLocations'] = cleanSubs;
          }

          batch.set(docRef, data);
        }
        await batch.commit();
        debugPrint('Successfully seeded destinations collection.');
      }

      // 2. Seed hotels collection if empty
      final hotelSnapshot = await _db.collection('hotels').limit(1).get();
      if (hotelSnapshot.docs.isEmpty) {
        debugPrint('Seeding hotels to Firestore...');
        final batch = _db.batch();
        for (var hotel in kHotels) {
          final docRef = _db.collection('hotels').doc(hotel.id);
          final data = {
            'id': hotel.id,
            'name': hotel.name,
            'location': hotel.location,
            'image': hotel.image,
            'rating': hotel.rating,
            'price': hotel.price,
            'description': hotel.description,
            'amenities': hotel.amenities,
            'lat': hotel.lat,
            'lng': hotel.lng,
          };
          batch.set(docRef, data);
        }
        await batch.commit();
        debugPrint('Successfully seeded hotels collection.');
      }
    } catch (e) {
      debugPrint('Error bootstrapping database: $e');
    }
  }

  /// Write a notification/activity log under users/{uid}/notifications.
  static Future<void> logNotification({
    required String uid,
    required String title,
    required String message,
    required String type,
  }) async {
    if (uid.isEmpty) return;
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      debugPrint('Error logging notification: $e');
    }
  }
}
