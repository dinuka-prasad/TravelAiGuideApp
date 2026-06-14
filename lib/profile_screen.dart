import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'universal_image.dart';
import 'database_service.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import 'app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _showEditProfileBottomSheet(Map<String, dynamic> currentData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileBottomSheet(
        currentData: currentData,
        uid: _auth.currentUser!.uid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: uid.isEmpty
          ? const Center(child: Text('Please sign in to view your profile.'))
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _firestore.collection('users').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                
                final data = snapshot.data?.data() ?? {};
                final email = user?.email ?? data['email'] ?? 'Unknown';
                final name = data['name'] ?? user?.displayName ?? 'No Name';
                final phone = data['phone'] ?? 'Not provided';
                final photoBase64 = data['photoBase64'];
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
                          color: Theme.of(context).cardTheme.color ?? Colors.white,
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
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySurface,
                                    shape: BoxShape.circle,
                                    image: photoBase64 != null
                                        ? DecorationImage(
                                            image: MemoryImage(base64Decode(photoBase64)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: photoBase64 == null
                                      ? Icon(Icons.person, color: AppColors.primary, size: 50)
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _showEditProfileBottomSheet(data),
                                    child: Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showEditProfileBottomSheet(data),
                                icon: Icon(Icons.edit_outlined, size: 18),
                                label: Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            _buildDetailRow(Icons.phone_outlined, 'Phone', phone),
                            _buildDetailRow(Icons.fingerprint, 'User ID', '${uid.substring(0, 8)}...${uid.substring(uid.length - 4)}'),
                            _buildDetailRow(
                              Icons.access_time,
                              'Last seen',
                              lastSeen != null ? _formatDate(lastSeen) : 'Not available',
                            ),
                            _buildDetailRow(
                              Icons.calendar_today_outlined,
                              'Joined',
                              createdAt != null ? _formatDate(createdAt) : 'Not available',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // App Settings Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ?? Colors.white,
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
                            Row(
                              children: [
                                Icon(Icons.settings_outlined, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'App Settings',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, child) {
                                return SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Dark Mode',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Switch between light and dark themes',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                  secondary: Icon(
                                    themeProvider.isDarkMode
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: themeProvider.isDarkMode
                                        ? AppColors.accent
                                        : AppColors.primary,
                                  ),
                                  value: themeProvider.isDarkMode,
                                  onChanged: (val) {
                                    themeProvider.toggleTheme(val);
                                  },
                                  activeColor: AppColors.primary,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Bookings Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ?? Colors.white,
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
                            Row(
                              children: [
                                Icon(Icons.hotel_outlined, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'My Bookings',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('users')
                                  .doc(uid)
                                  .collection('bookings')
                                  .orderBy('bookedAt', descending: true)
                                  .snapshots(),
                              builder: (ctx, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final bookings = snap.data?.docs ?? [];
                                if (bookings.isEmpty) {
                                  return Text(
                                    'You have no hotel bookings yet.',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: bookings.length,
                                  itemBuilder: (ctx, i) {
                                    final b = bookings[i].data() as Map<String, dynamic>;
                                    final category = b['bookingType'] as String? ?? 'Stay';
                                    IconData categoryIcon = Icons.hotel_outlined;
                                    Color categoryColor = AppColors.primary;
                                    if (category == 'Sight') {
                                      categoryIcon = Icons.place;
                                      categoryColor = Colors.blue;
                                    } else if (category == 'Eat') {
                                      categoryIcon = Icons.restaurant;
                                      categoryColor = Colors.orange;
                                    } else if (category == 'Budget') {
                                      categoryIcon = Icons.attach_money;
                                      categoryColor = Colors.purple;
                                    }

                                    return ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: UniversalImage(
                                              imagePath: b['hotelImage'] ?? '',
                                              width: 50,
                                              height: 50,
                                              fit: BoxFit.cover,
                                              errorWidget: const Icon(Icons.image),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                categoryIcon,
                                                size: 10,
                                                color: categoryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      title: Text(b['hotelName'] ?? 'Unknown Booking', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                        'Booked on: ${_formatDate((b['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now())}\n'
                                        'Type: $category',
                                        style: const TextStyle(height: 1.3),
                                      ),
                                      trailing: Text(
                                        b['displayPrice'] ?? '\$${b['price'] ?? 0}',
                                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      
                      // Activity Log / Notifications Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color ?? Colors.white,
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
                            Row(
                              children: [
                                Icon(Icons.notifications_outlined, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text(
                                  'Activity & Notifications',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('users')
                                  .doc(uid)
                                  .collection('notifications')
                                  .orderBy('timestamp', descending: true)
                                  .limit(10)
                                  .snapshots(),
                              builder: (ctx, snap) {
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final logs = snap.data?.docs ?? [];
                                if (logs.isEmpty) {
                                  return Text(
                                    'No recent activity logged.',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  );
                                }
                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: logs.length,
                                  itemBuilder: (ctx, i) {
                                    final logDoc = logs[i].data() as Map<String, dynamic>;
                                    final title = logDoc['title'] ?? 'Activity';
                                    final message = logDoc['message'] ?? '';
                                    final type = logDoc['type'] ?? 'general';
                                    final time = logDoc['timestamp'] is Timestamp
                                        ? (logDoc['timestamp'] as Timestamp).toDate()
                                        : DateTime.now();

                                    IconData logIcon = Icons.info_outline;
                                    Color logColor = Colors.blue;
                                    if (type == 'booking') {
                                      logIcon = Icons.hotel;
                                      logColor = AppColors.primary;
                                    } else if (type == 'profile') {
                                      logIcon = Icons.person_outline;
                                      logColor = Colors.orange;
                                    } else if (type == 'favorite') {
                                      logIcon = Icons.favorite_border;
                                      logColor = Colors.red;
                                    } else if (type == 'itinerary') {
                                      logIcon = Icons.map_outlined;
                                      logColor = Colors.green;
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: logColor.withValues(alpha: 0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(logIcon, color: logColor, size: 16),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  message,
                                                  style: TextStyle(
                                                    color: AppColors.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _formatTime(time),
                                                  style: TextStyle(
                                                    color: Colors.grey[400],
                                                    fontSize: 9,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _signOut,
                        icon: Icon(Icons.exit_to_app),
                        label: Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                           backgroundColor: AppColors.error,
                           foregroundColor: Colors.white,
                           minimumSize: const Size.fromHeight(52),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(16),
                           ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          SizedBox(width: 12),
          Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _EditProfileBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentData;
  final String uid;

  const _EditProfileBottomSheet({required this.currentData, required this.uid});

  @override
  State<_EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends State<_EditProfileBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _newImageBytes;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currentData['name'] ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
    _phoneController.text = widget.currentData['phone'] ?? '';
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _newImageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? photoBase64 = widget.currentData['photoBase64'];

      if (_newImageBytes != null) {
        photoBase64 = base64Encode(_newImageBytes!);
      }

      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      if (photoBase64 != null) {
        updates['photoBase64'] = photoBase64;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update(updates);
      await DatabaseService.logNotification(
        uid: widget.uid,
        title: 'Profile Updated',
        message: 'Your profile details have been successfully updated.',
        type: 'profile',
      );
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.currentUser!.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoBase64 = widget.currentData['photoBase64'];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    shape: BoxShape.circle,
                    image: _newImageBytes != null
                        ? DecorationImage(image: MemoryImage(_newImageBytes!), fit: BoxFit.cover)
                        : (photoBase64 != null ? DecorationImage(image: MemoryImage(base64Decode(photoBase64)), fit: BoxFit.cover) : null),
                  ),
                  child: (_newImageBytes == null && photoBase64 == null)
                      ? Icon(Icons.person, color: AppColors.primary, size: 40)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
