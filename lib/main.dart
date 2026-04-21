import 'package:flutter/material.dart';
import 'login_screen.dart'; // Login screen එක import කිරීමට අමතක කරන්න එපා

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Travel Guide',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      // App එක මුලින්ම පටන් ගන්නේ Login Screen එකෙන්
      home: LoginScreen(), 
    );
  }
}

// --- WELCOME SCREEN (TravelApp) ---
class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Travel AI Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  'https://images.unsplash.com/photo-1502791451862-7bd8c1df43a7?auto=format&fit=crop&w=800&q=80',
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Explore the World with AI',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              const Text(
                'Your personalized smart travel companion.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text('Get Started', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- HOME SCREEN (LIST VIEW) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> locations = [
      {'name': 'Sigiriya', 'img': 'https://images.unsplash.com/photo-1586902197503-e71026292412?w=800&q=80'},
      {'name': 'Ella', 'img': 'https://images.unsplash.com/photo-1590050752117-23a9d7fc91d3?auto=format&fit=crop&w=800&q=80'},
      {'name': 'Galle Fort', 'img': 'https://images.unsplash.com/photo-1627894483216-2138af692e32?w=800&q=80'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: locations.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: Colors.black38,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(
                      name: locations[index]['name']!,
                      img: locations[index]['img']!,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.network(
                          locations[index]['img']!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                            ),
                          ),
                          child: Text(
                            locations[index]['name']!,
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const ListTile(
                    title: Text('Sri Lanka', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                    subtitle: Text('Tap to explore more with AI insights.'),
                    trailing: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 18,
                      child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- DETAIL SCREEN ---
class DetailScreen extends StatelessWidget {
  final String name;
  final String img;

  const DetailScreen({super.key, required this.name, required this.img});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(img, width: double.infinity, height: 350, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                      const Icon(Icons.favorite_border, color: Colors.red),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('Sri Lanka', style: TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),
                  const Text(
                    'Experience the breathtaking views and rich history of this location. From ancient architecture to lush greenery, it offers a unique journey for every traveler.',
                    style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print("AI Generating for $name...");
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text("Ask AI for Travel Tips"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
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