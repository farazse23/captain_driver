import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/notification_service.dart';
import '../../services/driver_data_service.dart';
import '../../models/driver.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/custom_dashboard_card.dart';
import 'dart:typed_data';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final NotificationService _notificationService = NotificationService();

  final List<Widget> _pages = [
    const DashboardHome(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _pages[_selectedIndex],
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: Colors.transparent,
          color: const Color(0xFFFBE9E0),
          height: 70,
          animationDuration: const Duration(milliseconds: 300),
          index: _selectedIndex,
          items: [
            const Icon(
              FontAwesomeIcons.house,
              size: 28,
              color: AppColors.primary,
            ),
            // Notification icon with badge
            StreamBuilder<int>(
              stream: _notificationService.getUnreadNotificationCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      FontAwesomeIcons.bell,
                      size: 28,
                      color: Colors.purple,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const Icon(FontAwesomeIcons.user, size: 28, color: Colors.green),
          ],
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
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
      print('Dashboard - Loading driver data using cached service...');

      // Try to get cached data first to avoid loading state
      final cachedDriver = _driverDataService.getCachedDriverData();
      if (cachedDriver != null && mounted) {
        setState(() {
          _driver = cachedDriver;
          _isLoading = false;
        });
        print('Dashboard - Using cached driver data');
      }

      // Then fetch fresh data in background
      final driver = await _driverDataService.getDriverData();
      print('Dashboard - Driver data loaded: ${driver != null}');

      if (driver != null && mounted) {
        setState(() {
          _driver = driver;
          print(
            'Dashboard - Driver profile image length: ${_driver?.profileImage.length ?? 0}',
          );
          _isLoading = false;
        });
      } else if (mounted && cachedDriver == null) {
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

  Uint8List? _getProfileImageBytes() {
    if (_driver == null) return null;
    if (_driver!.hasProfileImageUrl) return null;
    return _driver!.getProfileImageBytes();
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
        child: RefreshIndicator(
          onRefresh: () async {
            // Force refresh the cached data
            await _driverDataService.getDriverData(forceRefresh: true);
            _loadDriverDetails();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top image and header with animation
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
                      left: 20,
                      top: size.height * 0.20,
                      child: FadeSlideAnimation(
                        duration: const Duration(milliseconds: 1000),
                        beginOffset: const Offset(-0.6, 0),
                        curve: Curves.easeOut,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _driver?.name ?? 'Driver',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _driver?.address ?? 'Location not set',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 25,
                      top: size.height * 0.20,
                      child: FadeSlideAnimation(
                        duration: const Duration(milliseconds: 1200),
                        beginOffset: const Offset(0.6, 0),
                        curve: Curves.easeOut,
                        child: Container(
                          width: 60,
                          height: 60,
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
                            borderRadius: BorderRadius.circular(30),
                            child:
                                _driver != null && _driver!.hasProfileImageUrl
                                ? Image.network(
                                    _driver!.profileImage,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.grey,
                                                size: 30,
                                              ),
                                            ),
                                  )
                                : (_getProfileImageBytes() != null
                                      ? Image.memory(
                                          _getProfileImageBytes()!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    color: Colors.grey[300],
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.grey,
                                                      size: 30,
                                                    ),
                                                  ),
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
                  ],
                ),
                const SizedBox(height: 32),

                // Dashboard Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: FadeSlideAnimation(
                              duration: const Duration(milliseconds: 600),
                              beginOffset: const Offset(0, 0.2),
                              curve: Curves.easeOut,
                              child: CustomDashboardCard(
                                title: 'Assigned Trips',
                                description: 'View your assigned trips',
                                icon: Icons.assignment,
                                iconColor: Colors.blue,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/assigned_trip',
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FadeSlideAnimation(
                              duration: const Duration(milliseconds: 800),
                              beginOffset: const Offset(0, 0.2),
                              curve: Curves.easeOut,
                              child: CustomDashboardCard(
                                title: 'Active Trip',
                                description: 'Currently active trip',
                                icon: Icons.directions_car,
                                iconColor: Colors.green,
                                onTap: () {
                                  // Always navigate to active trip screen
                                  // The screen will handle showing map with "No Active Trip" state
                                  Navigator.pushNamed(context, '/active_trip');
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FadeSlideAnimation(
                              duration: const Duration(milliseconds: 1000),
                              beginOffset: const Offset(0, 0.2),
                              curve: Curves.easeOut,
                              child: CustomDashboardCard(
                                title: 'Completed Trips',
                                description: 'View completed trips',
                                icon: Icons.check_circle,
                                iconColor: Colors.orange,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/completed_trip',
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FadeSlideAnimation(
                              duration: const Duration(milliseconds: 1200),
                              beginOffset: const Offset(0, 0.2),
                              curve: Curves.easeOut,
                              child: CustomDashboardCard(
                                title: 'Driver Details',
                                description: 'View your profile',
                                icon: Icons.person,
                                iconColor: Colors.purple,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/driver_details',
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
