import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showDialog(String title, String message, {bool isSuccess = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _changePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final reauthResult = await _authService.reauthenticateUser(
          _currentPasswordController.text,
        );

        if (reauthResult['success']) {
          final updateResult = await _authService.updatePassword(
            _newPasswordController.text,
          );

          if (updateResult['success']) {
            _showDialog(
              'Success',
              'Password changed successfully!',
              isSuccess: true,
            );
          } else {
            _showDialog('Error', updateResult['message']);
          }
        } else {
          _showDialog('Error', reauthResult['message']);
        }
      } catch (e) {
        _showDialog('Error', 'An unexpected error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
                          'Change Password',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Update your credentials',
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
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: FadeSlideAnimation(
                beginOffset: const Offset(0, 0.25),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                    ),
                    children: [
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Current Password',
                        hint: 'Enter Password',
                        obscureText: true,
                        controller: _currentPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot_password');
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      CustomTextField(
                        label: 'New Password',
                        hint: 'Enter Password',
                        obscureText: true,
                        controller: _newPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 5),
                      CustomTextField(
                        label: 'Confirm Password',
                        hint: 'Enter Password',
                        obscureText: true,
                        controller: _confirmPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _isLoading ? null : _changePassword,
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Change password',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
