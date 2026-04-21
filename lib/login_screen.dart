import 'package:flutter/material.dart';
import 'main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Color(0xFF004D40)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const Icon(Icons.travel_explore_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text("TRAVEL AI", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        const Text("Login", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(height: 25),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const TravelApp()),
                              );
                            },
                            child: const Text("LOG IN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // --- SIGN UP LINK ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- REGISTER SCREEN (NEW) ---
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Color(0xFF004D40)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Column(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 10),
                  const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: const Icon(Icons.person_outline, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "Email",
                            prefixIcon: const Icon(Icons.email_outlined, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.teal),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            onPressed: () {
                              // Register වූ පසු කෙලින්ම App එකට හෝ Login එකට යැවිය හැක
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Account Created Successfully!")),
                              );
                              Navigator.pop(context); // ආපහු Login එකට යෑම
                            },
                            child: const Text("SIGN UP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Already have an account? Login", style: TextStyle(color: Colors.teal)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}