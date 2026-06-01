import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'hotel_model.dart';
import 'hotel_data.dart';
import 'hotel_detail_screen.dart';
import 'app_theme.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Center roughly around Sri Lanka
    const centerPoint = LatLng(7.8731, 80.7718);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore on Map'),
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: centerPoint,
          initialZoom: 7.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mytravelapp',
          ),
          MarkerLayer(
            markers: kHotels.map((hotel) {
              // Note: using dummy coordinates based on the index or name for now
              // In a real app, 'hotel.lat' and 'hotel.lng' should be used.
              // Since hotel_model.dart doesn't have lat/lng right now, 
              // we will generate a pseudo-random coordinate in Sri Lanka.
              final lat = 6.0 + (hotel.id.hashCode % 30) / 10.0;
              final lng = 79.5 + (hotel.name.hashCode % 20) / 10.0;
              
              return Marker(
                point: LatLng(lat, lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelDetailScreen(hotel: hotel),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
