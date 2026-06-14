import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'favorites_provider.dart';
import 'data_provider.dart';
import 'hotel_model.dart';
import 'hotel_detail_screen.dart';
import 'app_theme.dart';
import 'universal_image.dart';

class FavoritesScreen extends StatelessWidget {
  FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final hotelsList = dataProvider.hotels;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Favorites'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          if (favoritesProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteIds = favoritesProvider.favoriteHotelIds;
          if (favoriteIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save your favorite hotels here.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final favoriteHotels = hotelsList
              .where((hotel) => favoriteIds.contains(hotel.id))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteHotels.length,
            itemBuilder: (context, index) {
              final hotel = favoriteHotels[index];
              return _FavoriteHotelCard(hotel: hotel);
            },
          );
        },
      ),
    );
  }
}

class _FavoriteHotelCard extends StatelessWidget {
  final Hotel hotel;
  const _FavoriteHotelCard({required this.hotel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: hotel)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: UniversalImage(
                imagePath: hotel.image,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      hotel.location,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${hotel.price.toInt()}/night',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Consumer<FavoritesProvider>(
                          builder: (context, provider, child) {
                            final isFav = provider.isFavorite(hotel.id);
                            return GestureDetector(
                              onTap: () => provider.toggleFavorite(hotel.id, hotel.name),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
