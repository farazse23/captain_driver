import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/forgot_password/forgot_password_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/assigned_trip/assigned_trip_screen.dart';
import 'screens/active_trip/active_trip_screen.dart';
import 'screens/completed_trip/completed_trip_screen.dart';
import 'screens/driver_details/driver_details_screen.dart';
import 'screens/trip_details/trip_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driver App',
      theme: ThemeData(fontFamily: 'Poppins'),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/assigned_trip': (context) => AssignedTripScreen(),
        '/active_trip': (context) => ActiveTripScreen(),
        '/completed_trip': (context) => CompletedTripScreen(),
        '/driver_details': (context) => DriverDetailsScreen(),
        '/trip_details': (context) {
          return const TripDetailsScreen();
        },
        '/profile': (context) => ProfileScreen(),
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/change_password': (context) => ChangePasswordScreen(),
      },
    );
  }
}
