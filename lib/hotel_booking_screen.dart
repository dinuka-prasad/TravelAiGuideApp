import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorites_provider.dart';
import 'hotel_model.dart';
import 'hotel_data.dart';
import 'hotel_detail_screen.dart';
import 'app_theme.dart';
import 'map_screen.dart';

class HotelBookingScreen extends StatefulWidget {
  const HotelBookingScreen({super.key});

  @override
  State<HotelBookingScreen> createState() => _HotelBookingScreenState();
}

class _HotelBookingScreenState extends State<HotelBookingScreen> {
  double _maxPrice = 1000;
  double _minRating = 0;

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text('Max Price: \$${_maxPrice.toInt()}'),
                  Slider(
                    value: _maxPrice,
                    min: 50,
                    max: 1000,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => _maxPrice = val);
                      setState(() => _maxPrice = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text('Minimum Rating: ${_minRating.toStringAsFixed(1)} stars'),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setModalState(() => _minRating = val);
                      setState(() => _minRating = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredHotels = kHotels.where((hotel) {
      return hotel.price <= _maxPrice && hotel.rating >= _minRating;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Stay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
        label: const Text('Map View', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.map, color: Colors.white),
        backgroundColor: AppColors.accent,
      ),
      body: filteredHotels.isEmpty
          ? const Center(child: Text('No hotels match your filters.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredHotels.length,
              itemBuilder: (context, index) {
                final hotel = filteredHotels[index];
                return _HotelCard(hotel: hotel);
              },
            ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  const _HotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: hotel)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: Image.network(
                    hotel.image,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, provider, child) {
                      final isFav = provider.isFavorite(hotel.id);
                      return GestureDetector(
                        onTap: () => provider.toggleFavorite(hotel.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFav ? Colors.red : AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          hotel.rating.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hotel.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '\$${hotel.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        hotel.location,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const Spacer(),
                      const Text(
                        '/night',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
