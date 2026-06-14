import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'app_theme.dart';

import 'universal_image.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _isLoginMode = true;

  // Background images for the slideshow - real verified photos
  final List<String> _bgImages = [
    'https://images.pexels.com/photos/13391116/pexels-photo-13391116.jpeg?auto=compress&cs=tinysrgb&w=800', // Sigiriya Rock
    'https://images.unsplash.com/photo-1765833437191-9dc9992db439?w=800&q=80', // Galle Fort Lighthouse
    'https://images.unsplash.com/photo-1665849050332-8d5d7e59afb6?w=800&q=80', // Kandy Temple of the Tooth
    'https://images.unsplash.com/photo-1586861635167-e5223aadc9fe?w=800&q=80', // Coconut Tree Hill, Mirissa
  ];
  int _currentBgIndex = 0;
  Timer? _bgTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();

    // Start background image slideshow
    _bgTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _animController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Firestore එකට ඩේටා සේව් කිරීම/යාවත්කාලීන කිරීම
  Future<void> _saveUserToFirestore(User? user, {String? displayName, String? phoneNumber}) async {
    if (user == null) return;
    
    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'email': user.email ?? '',
      'lastSeen': FieldValue.serverTimestamp(),
    };

    // Sign Up මාදිලියේදී පමණක් මේවා එකතු වේ
    if (displayName != null && displayName.isNotEmpty) {
      userData['name'] = displayName;
      userData['phone'] = phoneNumber ?? '';
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['role'] = 'user'; 
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userData, SetOptions(merge: true));
  }

  // ── 1. LOG IN FUNCTION ──
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final credential = await _auth
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
            .timeout(const Duration(seconds: 20));

        final user = credential.user;

        // 🔥 EMAIL VERIFICATION CHECK
        // යූසර් Email එක Verify කරලා නැත්නම් ඇතුලට යවන්නේ නැහැ
        if (user != null && !user.emailVerified) {
          await user.reload(); // දත්ත අලුත් කිරීම
          if (!user.emailVerified) {
            setState(() => isLoading = false);
            _showSnack('Please verify your email address first. Check your inbox!', isError: true);
            await _showErrorDialog('Your email is not verified yet. We sent a link to ${_emailController.text.trim()}. Please check your spam folder too.');
            return;
          }
        }

        await _saveUserToFirestore(user);
        
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String msg = 'Login failed. Please try again.';
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          msg = 'Invalid email or password. Please try again.';
        }
        _showSnack(msg, isError: true);
      } catch (e) {
        if (!mounted) return;
        _showSnack('Unexpected error: $e', isError: true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // ── 2. SIGN UP FUNCTION ──
  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final credential = await _auth
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
            .timeout(const Duration(seconds: 20));
            
        final user = credential.user;
        
        if (user != null) {
          // Auth Profile එකට නම දමයි
          await user.updateDisplayName(_nameController.text.trim());
          
          // 🔥 EMAIL VERIFICATION LINK එකක් යැවීම
          await user.sendEmailVerification();
          
          // Firestore එකට ඔක්කොම විස්තර (නම, ෆෝන්, ඊමේල්) සේව් කිරීම
          await _saveUserToFirestore(
            user, 
            displayName: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
          );
        }
        
        if (!mounted) return;
        _showSnack('Account created! A verification email has been sent.', isError: false);
        
        // එකවුන්ට් එක හැදුනට පස්සේ Verification එක ඕන නිසා ආයේ Log In මාදිලියට හරවනවා
        await _showSuccessDialog('Registration Successful!\n\nWe have sent a verification email to ${_emailController.text.trim()}. Please click the link in that email to activate your account, then log in.');
        
        setState(() {
          _isLoginMode = true;
          _nameController.clear();
          _phoneController.clear();
        });

      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String msg = 'Sign up failed: ${e.message}';
        if (e.code == 'email-already-in-use') {
          msg = 'Email already registered. Please log in instead.';
        }
        _showSnack(msg, isError: true);
      } catch (e) {
        if (!mounted) return;
        _showSnack('Unexpected error: $e', isError: true);
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [Icon(Icons.error_outline, color: AppColors.error), SizedBox(width: 8), Text('Verification Required')],
        ),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('OK'))],
      ),
    );
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [Icon(Icons.check_circle_outline, color: AppColors.success), SizedBox(width: 8), Text('Verify Email')],
        ),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Got it'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Image Slideshow ──
          AnimatedSwitcher(
            duration: Duration(seconds: 1),
            child: UniversalImage(
              imagePath: _bgImages[_currentBgIndex],
              key: ValueKey<int>(_currentBgIndex),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorWidget: Container(color: AppColors.primaryDark),
            ),
          ),
          // ── Dark Gradient Overlay ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // ── Foreground Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // ── Logo ──
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 88,
                                height: 88,
                                color: AppColors.primarySurface,
                                child: Icon(Icons.travel_explore, size: 50, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'ARAKSHAKAYA',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            '🌴 Travel AI Guide',
                            style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Form Card ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 40,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLoginMode ? 'Welcome Back 👋' : 'Create Account',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _isLoginMode
                                          ? 'Sign in to continue your journey'
                                          : 'Join and start exploring Sri Lanka',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                    ),
                                    const SizedBox(height: 32),

                                    // ── Tab Toggle ──
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          _tabBtn('Log In', _isLoginMode, () => setState(() => _isLoginMode = true)),
                                          _tabBtn('Sign Up', !_isLoginMode, () => setState(() => _isLoginMode = false)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // ── 1. Full Name Field (Sign Up Only) ──
                                    if (!_isLoginMode) ...[
                                      TextFormField(
                                        controller: _nameController,
                                        keyboardType: TextInputType.name,
                                        decoration: _inputStyle('Full Name', Icons.person_outline),
                                        validator: (val) =>
                                            (!_isLoginMode && (val == null || val.trim().isEmpty))
                                                ? 'Please enter your name'
                                                : null,
                                      ),
                                      const SizedBox(height: 16),

                                      // ── 2. Phone Number Field (Sign Up Only) ──
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        decoration: _inputStyle('Phone Number', Icons.phone_outlined),
                                        validator: (val) {
                                          if (!_isLoginMode) {
                                            if (val == null || val.trim().isEmpty) return 'Please enter phone number';
                                            if (val.trim().length < 10) {
                                              return 'Enter a valid phone number (e.g. 0771234567)';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // ── 3. Email Field ──
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: _inputStyle('Email Address', Icons.email_outlined),
                                      validator: (val) {
                                        if (val == null || val.isEmpty) return 'Please enter your email';
                                        if (!val.contains('@')) return 'Enter a valid email';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // ── 4. Password Field ──
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14),
                                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                                        ),
                                      ),
                                      validator: (val) =>
                                          (val == null || val.length < 6) ? 'Password must be at least 6 characters' : null,
                                    ),
                                    SizedBox(height: 28),

                                    // ── Submit Button ──
                                    if (isLoading)
                                      Center(child: CircularProgressIndicator(color: AppColors.primary))
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _isLoginMode ? _login : _signUp,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            elevation: 3,
                                            shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                          ),
                                          child: Text(
                                            _isLoginMode ? 'Log In' : 'Create Account',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'By continuing, you agree to our Terms of Service.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.primary, width: 2)),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: active ? Colors.white : AppColors.textSecondary, fontSize: 14),
          ),
        ),
      ),
    );
  }
}