import 'package:flutter/material.dart';
import '../../constants/app_colors.dart'; // Update with your actual import

void showCustomPopup(
  BuildContext context, {
  required Widget graphic, // Accepts Icon, Image, etc.
  required String mainText,
  required String subText,
  Widget? centerImage, // Optional image before icon
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (centerImage != null) ...[
              centerImage,
              const SizedBox(height: 16),
            ],
            graphic,
            const SizedBox(height: 16),
            Text(
              mainText,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: subText,
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future.delayed(const Duration(seconds: 2), () {
    // ignore: use_build_context_synchronously
    Navigator.of(context, rootNavigator: true).pop();
  });
}
