import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'data_provider.dart';
import 'detail_screen.dart';
import 'planner_screen.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'app_theme.dart';
import 'favorites_screen.dart';
import 'universal_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _categories = [
    'All',
    'Beach',
    'Temple',
    'Mountain',
  ];

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> dataDestinations) {
    return dataDestinations.where((d) {
      final matchCat =
          _selectedCategory == 'All' || d['category'] == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          (d['name'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          (d['tag'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      DashboardScreen(),
      FavoritesScreen(),
      PlannerScreen(),
      AiChatScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: Offset(0, -4))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark),
              label: 'Planner',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'AI Chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.email?.split('@').first ?? 'Traveller';
    final dataProvider = Provider.of<DataProvider>(context);

    if (dataProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final destinationsList = dataProvider.destinations;
    final filteredList = _filtered(destinationsList);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.primary,
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: _goToProfile,
              tooltip: 'Profile',
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Sign out',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 16, bottom: 44),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $displayName 👋',
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                const Text('Sri Lanka Explorer 🌴',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                UniversalImage(
                  imagePath: 'https://images.unsplash.com/photo-1546708973-b339540b5162?w=800&q=80',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 55, right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: AppColors.accentLight, size: 13),
                          const SizedBox(width: 4),
                          Text(
                              '${destinationsList.length} Places',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Transform.translate(
              offset: const Offset(0, 20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search destinations…',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Category chips
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 30, 0, 4),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ]
                            : [],
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == 'All'
                      ? 'Top Destinations'
                      : '$_selectedCategory Destinations',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                Text(
                  '${filteredList.length} found',
                  style: TextStyle(
                      color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // Destination cards
        if (filteredList.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No destinations found',
                      style: TextStyle(
                          color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _DestinationCard(location: filteredList[i]),
                childCount: filteredList.length,
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  final Map<String, dynamic> location;
  const _DestinationCard({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DetailScreen(location: location)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    child: UniversalImage(
                      imagePath: location['img'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        height: 200,
                        color: AppColors.primarySurface,
                        child: Center(
                          child: Icon(Icons.image_not_supported,
                              color: AppColors.primary, size: 48),
                        ),
                      ),
                    ),
                  ),
                  // Tag badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: location['tagColor'],
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(location['tag'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 4),
                          Text('${location['rating']}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(location['name'],
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  color: AppColors.primary, size: 13),
                              SizedBox(width: 3),
                              Text(location['country'],
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(width: 8),
                              Text('· ${location['cost']}',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: AppColors.primary, size: 12),
                              SizedBox(width: 5),
                              Text(location['bestTime'],
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(location['duration'],
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
