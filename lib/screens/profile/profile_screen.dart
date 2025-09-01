import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../services/auth_service.dart';
import '../../services/driver_data_service.dart';
import '../../models/driver.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DriverDataService _driverDataService = DriverDataService();
  Driver? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverDetails();
  }

  void _loadDriverDetails() async {
    try {
      final driver = await _driverDataService.getDriverData();
      if (driver != null && mounted) {
        setState(() {
          _driver = driver;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading driver details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImageDialog(String title, Uint8List? imageBytes) {
    if (imageBytes == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    width: double.infinity,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      child: InteractiveViewer(
                        child: Image.memory(imageBytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top image and header with animation (like assigned_trip)
            Stack(
              children: [
                FadeSlideAnimation(
                  duration: const Duration(milliseconds: 1000),
                  beginOffset: const Offset(0, 0.3),
                  curve: Curves.linear,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: Image.asset(
                      'assets/images/DashBoard.jpg',
                      width: double.infinity,
                      height: size.height * 0.34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: size.height * 0.20,
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(-0.6, 0),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Settings & Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_driver != null)
                  Positioned(
                    bottom: 20,
                    right: 24,
                    child: FadeSlideAnimation(
                      duration: const Duration(milliseconds: 1200),
                      beginOffset: const Offset(0.2, -0.2),
                      curve: Curves.easeOut,
                      child: GestureDetector(
                        onTap: () => _showImageDialog(
                          'Profile Picture',
                          _driver!.getProfileImageBytes(),
                        ),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: _driver!.hasProfileImageUrl
                                ? Image.network(
                                    _driver!.profileImage,
                                    fit: BoxFit.cover,
                                  )
                                : (_driver!.getProfileImageBytes() != null
                                    ? Image.memory(
                                        _driver!.getProfileImageBytes()!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.grey,
                                          size: 30,
                                        ),
                                      )),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FadeSlideAnimation(
                beginOffset: const Offset(0, 0.25),
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                  children: [
                    _ProfileOption(
                      icon: Icons.person,
                      text: 'Driver Details',
                      onTap: () {
                        Navigator.pushNamed(context, '/driver_details');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.lock,
                      text: 'Change Password',
                      onTap: () {
                        Navigator.pushNamed(context, '/change_password');
                      },
                    ),
                    _ProfileOption(
                      icon: Icons.info_outline,
                      text: 'About',
                      onTap: () {},
                    ),
                    _ProfileOption(
                      icon: Icons.logout,
                      text: 'Logout',
                      onTap: _showLogoutDialog,
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

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFBE9E0),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 18,
          color: AppColors.primary,
        ),
        onTap: onTap,
      ),
    );
  }
}
