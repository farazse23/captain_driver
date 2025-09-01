import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messaging_service.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MessagingService _messagingService = MessagingService();
  final NotificationService _notificationService = NotificationService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // First check if email exists in drivers collection with driver role
      QuerySnapshot driverQuery = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: email)
          .where('role', isEqualTo: 'driver')
          .get();

      if (driverQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Driver account not found with this email.',
        };
      }

      // Extract driver data for use in fallback flows (e.g., tempPassword)
      final Map<String, dynamic> driverData =
          driverQuery.docs.first.data() as Map<String, dynamic>;

      // Optional: block login if status is not acceptable (uncomment if needed)
      // if ((driverData['status'] ?? '').toString().toLowerCase() == 'blocked') {
      //   return {'success': false, 'message': 'Your account is blocked.'};
      // }

      // If driver exists, proceed with Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user != null) {
        return {'success': true, 'user': user, 'driverData': driverData};
      }
    } on FirebaseAuthException catch (e) {
      // Handle cases where the Firebase Auth user does not exist yet or password mismatch
      try {
        // Re-run driver query to access driverData in this scope
        final QuerySnapshot driverQuery = await _firestore
            .collection('drivers')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: 'driver')
            .get();
        if (driverQuery.docs.isNotEmpty) {
          final Map<String, dynamic> driverData =
              driverQuery.docs.first.data() as Map<String, dynamic>;
          final String tempPassword = (driverData['tempPassword'] ?? '')
              .toString();

          // If user not found in Firebase Auth but driver exists in Firestore, create the auth user with tempPassword
          if (e.code == 'user-not-found' && tempPassword.isNotEmpty) {
            try {
              await _auth.createUserWithEmailAndPassword(
                email: email,
                password: tempPassword,
              );
              // Sign in with temp password
              final created = await _auth.signInWithEmailAndPassword(
                email: email,
                password: tempPassword,
              );
              return {
                'success': true,
                'user': created.user,
                'driverData': driverData,
                'needsPasswordChange': true,
                'message':
                    'Signed in with temporary password. Please change your password.',
              };
            } on FirebaseAuthException catch (_) {
              // Fall through to error below
            }
          }

          // If wrong-password, attempt login using tempPassword
          if (e.code == 'wrong-password' && tempPassword.isNotEmpty) {
            try {
              final tempResult = await _auth.signInWithEmailAndPassword(
                email: email,
                password: tempPassword,
              );
              return {
                'success': true,
                'user': tempResult.user,
                'driverData': driverData,
                'needsPasswordChange': true,
                'message':
                    'Signed in with temporary password. Please change your password.',
              };
            } on FirebaseAuthException catch (_) {
              // Fall through to error below
            }
          }
        }
      } catch (_) {}

      return {'success': false, 'message': _getErrorMessage(e.code)};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }

    return {'success': false, 'message': 'Login failed. Please try again.'};
  }

  // Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent successfully.',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    }
  }

  // Update password
  Future<Map<String, dynamic>> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
        return {'success': true, 'message': 'Password updated successfully.'};
      } else {
        return {'success': false, 'message': 'No user logged in.'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    }
  }

  // Re-authenticate user (required before password update)
  Future<Map<String, dynamic>> reauthenticateUser(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return {'success': true};
      } else {
        return {'success': false, 'message': 'No user logged in.'};
      }
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _getErrorMessage(e.code)};
    }
  }

  // Get driver details by email
  Future<Map<String, dynamic>?> getDriverDetails(String email) async {
    try {
      QuerySnapshot driverQuery = await _firestore
          .collection('drivers')
          .where('email', isEqualTo: email)
          .get();

      if (driverQuery.docs.isNotEmpty) {
        return driverQuery.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting driver details: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _messagingService.deleteToken();
    _notificationService.resetStreams(); // Reset notification streams
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'requires-recent-login':
        return 'Please log in again before changing your password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
