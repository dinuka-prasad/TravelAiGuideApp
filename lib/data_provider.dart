import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_service.dart';
import 'hotel_model.dart';

class DataProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _destinations = [];
  List<Hotel> _hotels = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> get destinations => _destinations;
  List<Hotel> get hotels => _hotels;
  bool get isLoading => _isLoading;

  DataProvider() {
    loadData();
    // Listen to auth changes to reload data on login/logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadData();
      } else {
        _destinations = [];
        _hotels = [];
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // 1. Ensure DB is bootstrapped
      await DatabaseService.bootstrapDatabase();

      // 2. Fetch Destinations
      final destSnapshot = await FirebaseFirestore.instance.collection('destinations').get();
      _destinations = destSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Reconstruct tagColor from stored integer
        if (data['tagColorValue'] != null) {
          data['tagColor'] = Color(data['tagColorValue'] as int);
        }
        
        // Ensure subLocations also have their tagColor reconstructed
        if (data['subLocations'] != null) {
          final List<dynamic> subs = data['subLocations'];
          final List<Map<String, dynamic>> cleanSubs = [];
          for (var sub in subs) {
            final subMap = Map<String, dynamic>.from(sub);
            if (subMap['tagColorValue'] != null) {
              subMap['tagColor'] = Color(subMap['tagColorValue'] as int);
            }
            cleanSubs.add(subMap);
          }
          data['subLocations'] = cleanSubs;
        }

        return data;
      }).toList();

      // 3. Fetch Hotels
      final hotelSnapshot = await FirebaseFirestore.instance.collection('hotels').get();
      _hotels = hotelSnapshot.docs.map((doc) {
        final data = doc.data();
        return Hotel(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          location: data['location'] ?? '',
          image: data['image'] ?? '',
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
          amenities: List<String>.from(data['amenities'] ?? []),
          lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
          lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error loading dynamic content: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
