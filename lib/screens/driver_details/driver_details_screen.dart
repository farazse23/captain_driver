import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../services/driver_data_service.dart';
import '../../models/driver.dart';

class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({super.key});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
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
      print('DriverDetails - Loading driver data using cached service...');
      final driver = await _driverDataService.getDriverData();
      print('DriverDetails - Driver data loaded: ${driver != null}');

      if (driver != null) {
        setState(() {
          _driver = driver;
          print('Driver profile image length: ${_driver?.profileImage.length}');
          print('Driver license image length: ${_driver?.licenseImage.length}');
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading driver details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageDialog(String title, Uint8List? imageBytes) {
    if (imageBytes == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Image.memory(imageBytes, fit: BoxFit.contain),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_driver == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Driver details not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
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
                  top: size.height * 0.18,
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(-0.6, 0),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Driver Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Profile & Account',
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
                Positioned(
                  bottom: 20,
                  right: 24,
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1200),
                    beginOffset: const Offset(0.2, -0.2),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                      onTap: () {
                        if (_driver!.hasProfileImageUrl) {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: InteractiveViewer(
                                child: Image.network(
                                  _driver!.profileImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        } else {
                          _showImageDialog(
                            'Profile Picture',
                            _driver!.getProfileImageBytes(),
                          );
                        }
                      },
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
                    _DetailTile(label: 'Name', value: _driver!.name),
                    _DetailTile(label: 'Email', value: _driver!.email),
                    _DetailTile(label: 'CNIC', value: _driver!.cnic),
                    _DetailTile(
                      label: 'License Number',
                      value: _driver!.licenseNumber,
                    ),
                    _DetailTile(label: 'Address', value: _driver!.address),
                    _DetailTile(label: 'Status', value: _driver!.status),
                    Card(
                      color: const Color(0xFFFBE9E0),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: const Text(
                          'License Image',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _driver!.hasLicenseImageUrl ||
                          _driver!.getLicenseImageBytes() != null
                              ? 'Tap to view license image'
                              : 'No license image available',
                        ),
                        trailing: Icon(
                          _driver!.getLicenseImageBytes() != null
                              ? Icons.image
                              : Icons.image_not_supported,
                          color: AppColors.primary,
                        ),
                        onTap: () {
                          if (_driver!.hasLicenseImageUrl) {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(
                                    _driver!.licenseImage,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          } else if (_driver!.getLicenseImageBytes() != null) {
                            _showImageDialog(
                                'License Image',
                                _driver!.getLicenseImageBytes(),
                            );
                          }
                        },
                      ),
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

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;

  const _DetailTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFBE9E0),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
