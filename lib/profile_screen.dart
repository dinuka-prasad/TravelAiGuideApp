import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
            tooltip: 'Sign out',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: uid.isEmpty
          ? const Center(
              child: Text('Please sign in to view your profile.'),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? {};
                final email = user?.email ?? data['email'] ?? 'Unknown';
                final createdAt = data['createdAt'] is Timestamp
                    ? (data['createdAt'] as Timestamp).toDate()
                    : null;
                final lastSeen = data['lastSeen'] is Timestamp
                    ? (data['lastSeen'] as Timestamp).toDate()
                    : null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Information',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'User ID: ${uid.substring(0, 8)}...${uid.substring(uid.length - 6)}',
                                        style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            _buildDetailRow('Email', email),
                            _buildDetailRow('UID', uid),
                            _buildDetailRow(
                              'Last seen',
                              lastSeen != null
                                  ? '${lastSeen.toLocal()}'
                                  : 'Not available',
                            ),
                            _buildDetailRow(
                              'Profile created',
                              createdAt != null
                                  ? '${createdAt.toLocal()}'
                                  : 'Not available',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _signOut(context),
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
