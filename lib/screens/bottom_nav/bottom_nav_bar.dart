import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Trips'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (index == 1) {
          Navigator.pushReplacementNamed(context, '/assigned_trip');
        } else if (index == 2) {
          Navigator.pushReplacementNamed(context, '/profile');
        }
      },
    );
  }
}
