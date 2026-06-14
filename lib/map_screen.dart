import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'hotel_detail_screen.dart';
import 'detail_screen.dart';
import 'app_theme.dart';
import 'universal_image.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;
  String _routeDistance = '';
  String _routeDuration = '';

  // User's current location (Defaults to Colombo, updated dynamically via GPS)
  LatLng? _currentLocation;
  bool _isLoadingLocation = true;

  LatLng get _startLocation => _currentLocation ?? const LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _determinePosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        // Move camera to user's location
        _mapController.move(_currentLocation!, 8.0);
      }
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      if (mounted) {
        setState(() {
          // Fallback to Colombo
          _currentLocation = LatLng(6.9271, 79.8612);
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch GPS location. Falling back to Colombo: $e'),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Tracks selected item for showing details
  Map<String, dynamic>? _selectedItem;
  bool _isHotel = false;

  Future<void> _fetchRoute(LatLng destinationPoint) async {
    setState(() {
      _isLoadingRoute = true;
      _routePoints = [];
      _routeDistance = '';
      _routeDuration = '';
    });

    final startPoint = _startLocation;
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${startPoint.longitude},${startPoint.latitude};'
      '${destinationPoint.longitude},${destinationPoint.latitude}'
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

          // Center map to route midpoint
          final centerLat = (startPoint.latitude + destinationPoint.latitude) / 2;
          final centerLng = (startPoint.longitude + destinationPoint.longitude) / 2;
          _mapController.move(LatLng(centerLat, centerLng), 8.0);
        } else {
          throw Exception('No route returned from routing engine');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to calculate route: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);
    final hotelsList = dataProvider.hotels;
    final destinationsList = dataProvider.destinations;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore on Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _getCurrentLocation();
            },
            tooltip: 'Get My GPS Location',
          ),
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                setState(() {
                  _routePoints = [];
                  _routeDistance = '';
                  _routeDuration = '';
                  _selectedItem = null;
                });
              },
              tooltip: 'Clear Route',
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map View ──
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(7.8731, 80.7718),
              initialZoom: 7.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mytravelapp',
              ),
              // Route Polyline Layer
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.primary,
                      strokeWidth: 5.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              // Markers Layer
              MarkerLayer(
                markers: [
                  // My GPS Location Marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  // Hotel Markers
                  ...hotelsList.map((hotel) {
                    final isSelected = _selectedItem != null && _selectedItem!['name'] == hotel.name;
                    return Marker(
                      point: LatLng(hotel.lat, hotel.lng),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItem = {
                              'name': hotel.name,
                              'tag': 'Hotel Stay',
                              'img': hotel.image,
                              'cost': '\$${hotel.price.toInt()}/night',
                              'rating': hotel.rating,
                              'lat': hotel.lat,
                              'lng': hotel.lng,
                              'description': hotel.description,
                            };
                            _isHotel = true;
                          });
                        },
                        child: Icon(
                          Icons.hotel,
                          color: isSelected ? Colors.red : AppColors.primary,
                          size: isSelected ? 42 : 35,
                        ),
                      ),
                    );
                  }),
                  // Destination Markers
                  ...destinationsList.map((dest) {
                    final isSelected = _selectedItem != null && _selectedItem!['name'] == dest['name'];
                    return Marker(
                      point: LatLng((dest['lat'] as num).toDouble(), (dest['lng'] as num).toDouble()),
                      width: 45,
                      height: 45,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedItem = {
                              'name': dest['name'],
                              'tag': dest['tag'],
                              'img': dest['img'],
                              'cost': dest['cost'],
                              'rating': dest['rating'],
                              'lat': dest['lat'],
                              'lng': dest['lng'],
                              'description': dest['description'],
                              'raw': dest,
                            };
                            _isHotel = false;
                          });
                        },
                        child: Icon(
                          Icons.place,
                          color: isSelected ? Colors.red : AppColors.accentDark,
                          size: isSelected ? 42 : 35,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── GPS Fetching Loader ──
          if (_isLoadingLocation)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Getting GPS Location...',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),

          // ── Top Route Stats Info Card ──
          if (_routeDistance.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.directions_car, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Routing from My GPS Location',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Distance: $_routeDistance  |  Time: $_routeDuration',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _routePoints = [];
                            _routeDistance = '';
                            _routeDuration = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom Persistent Details Card ──
          if (_selectedItem != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: UniversalImage(
                              imagePath: _selectedItem!['img'],
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySurface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _selectedItem!['tag'],
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 14),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${_selectedItem!['rating']}',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 6),
                                Text(
                                  _selectedItem!['name'],
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _selectedItem!['cost'],
                                  style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        _selectedItem!['description'],
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (_isHotel) {
                                  final hotel = hotelsList.firstWhere((h) => h.name == _selectedItem!['name']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => HotelDetailScreen(hotel: hotel)),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DetailScreen(location: _selectedItem!['raw'])),
                                  );
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('View Full Details'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoadingRoute
                                  ? null
                                  : () => _fetchRoute(LatLng((_selectedItem!['lat'] as num).toDouble(), (_selectedItem!['lng'] as num).toDouble())),
                              icon: _isLoadingRoute
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(Icons.navigation_outlined, size: 16),
                              label: Text(_isLoadingRoute ? 'Routing...' : 'Get Route'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
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
      ),
    );
  }
}
