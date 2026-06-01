import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesProvider extends ChangeNotifier {
  Set<String> _favoriteHotelIds = {};
  bool _isLoading = false;

  Set<String> get favoriteHotelIds => _favoriteHotelIds;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    _loadFavorites();
    // Listen to auth changes to reload favorites on login/logout
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadFavorites();
      } else {
        _favoriteHotelIds.clear();
        notifyListeners();
      }
    });
  }

  bool isFavorite(String hotelId) {
    return _favoriteHotelIds.contains(hotelId);
  }

  Future<void> _loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('hotels')
          .get();

      if (doc.exists && doc.data() != null) {
        final List<dynamic> ids = doc.data()!['ids'] ?? [];
        _favoriteHotelIds = ids.map((e) => e.toString()).toSet();
      } else {
        _favoriteHotelIds = {};
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String hotelId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_favoriteHotelIds.contains(hotelId)) {
      _favoriteHotelIds.remove(hotelId);
    } else {
      _favoriteHotelIds.add(hotelId);
    }
    notifyListeners(); // Update UI immediately (optimistic UI)

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('hotels')
          .set({
        'ids': _favoriteHotelIds.toList(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving favorite: $e');
      // Revert if failed (optional, keeping it simple for now)
    }
  }
}
