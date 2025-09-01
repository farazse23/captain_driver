import 'package:driver_app/constants/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_popup.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TapGestureRecognizer _resendTapRecognizer = TapGestureRecognizer();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _sendPasswordResetEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _authService.sendPasswordResetEmail(
          _emailController.text.trim(),
        );

        if (result['success']) {
          showCustomPopup(
            context,
            centerImage: Image.asset(
              'assets/images/logo.png',
              width: 150,
              height: 150,
            ),
            graphic: Icon(
              FontAwesomeIcons.solidCircleCheck,
              size: 50,
              color: AppColors.success,
            ),
            mainText: 'Email Sent!',
            subText: 'Please check your inbox for password reset instructions.',
          );
        } else {
          _showErrorDialog(result['message']);
        }
      } catch (e) {
        _showErrorDialog('An unexpected error occurred. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.04,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.04),
                  Transform(
                    transform: Matrix4.translationValues(0, 35, 0),
                    child: SvgPicture.asset(
                      'assets/images/logo.svg',
                      width: size.width * 0.60,
                      height: size.width * 0.60,
                    ),
                  ),
                  Transform(
                    transform: Matrix4.translationValues(0, -20, 0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Forgot',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.black,
                            ),
                          ),
                          TextSpan(
                            text: ' Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.03),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'thisand@that.com',
                      prefixIcon: const Icon(
                        FontAwesomeIcons.envelope,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: AppColors.fieldBackground,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+',
                      ).hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: size.height * 0.03),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Didn\'t Receive email? ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.black,
                          ),
                        ),
                        TextSpan(
                          text: 'Resend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: _resendTapRecognizer
                            ..onTap = _sendPasswordResetEmail,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),
                  CustomButton(
                    text: _isLoading ? 'Sending...' : 'Get Link',
                    onPressed: _sendPasswordResetEmail,
                    enabled: !_isLoading,
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
