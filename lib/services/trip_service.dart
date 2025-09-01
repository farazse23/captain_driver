import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip.dart';
import 'auth_service.dart';

class TripService {
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get current driver's assigned trips (pending, assigned, in-progress)
  Stream<List<Trip>> getAssignedTrips() {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) return Stream.value([]);

    // Use a more efficient approach: get all users and check their trips
    return _firestore.collection('users').snapshots().asyncMap((
      usersSnapshot,
    ) async {
      List<Trip> allAssignedTrips = [];
      // Iterate through users and collect assigned trips for current driver

      for (var userDoc in usersSnapshot.docs) {
        try {
          // Query each user's trips subcollection for assigned and in-progress trips
          final List<String> statuses = ['assigned', 'in-progress'];

          for (String status in statuses) {
            final tripsQuery = await _firestore
                .collection('users')
                .doc(userDoc.id)
                .collection('trips')
                .where('status', isEqualTo: status)
                .get();

            for (var tripDoc in tripsQuery.docs) {
              final tripData = tripDoc.data();
              final assignedDriverIds = List<String>.from(
                tripData['assignedDriverIds'] ?? [],
              );

              // Check if current driver is assigned to this trip
              bool isAssignedToCurrentDriver = assignedDriverIds.contains(
                driverId,
              );

              if (isAssignedToCurrentDriver) {
                allAssignedTrips.add(Trip.fromMap(tripData, tripDoc.id));
              }
            }
          }
        } catch (e) {
          // Continue processing other users on error
        }
      }

      return allAssignedTrips;
    });
  }

  // Get current driver's active trip (in-progress) for navigation
  Future<Trip?> getCurrentActiveTrip() async {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) return null;

    try {
      // Search across all users for in-progress trips assigned to current driver
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final tripsQuery = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('trips')
            .where('status', isEqualTo: 'in-progress')
            .get();

        for (var tripDoc in tripsQuery.docs) {
          final tripData = tripDoc.data();
          final assignedDriverIds = List<String>.from(
            tripData['assignedDriverIds'] ?? [],
          );

          bool isAssignedToCurrentDriver = assignedDriverIds.contains(driverId);

          if (isAssignedToCurrentDriver) {
            return Trip.fromMap(tripData, tripDoc.id);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current driver's active trips (in-progress)
  Stream<List<Trip>> getActiveTrips() {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) return Stream.value([]);

    // Use a more efficient approach: get all users and check their trips
    return _firestore.collection('users').snapshots().asyncMap((
      usersSnapshot,
    ) async {
      List<Trip> allActiveTrips = [];

      for (var userDoc in usersSnapshot.docs) {
        try {
          // Query each user's trips subcollection
          final tripsQuery = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('trips')
              .where('status', isEqualTo: 'in-progress')
              .get();

          for (var tripDoc in tripsQuery.docs) {
            final tripData = tripDoc.data();
            final assignedDriverIds = List<String>.from(
              tripData['assignedDriverIds'] ?? [],
            );

            // Check if current driver is assigned to this trip
            bool isAssignedToCurrentDriver = assignedDriverIds.contains(
              driverId,
            );

            if (isAssignedToCurrentDriver) {
              allActiveTrips.add(Trip.fromMap(tripData, tripDoc.id));
            }
          }
        } catch (e) {
          // Continue processing other users on error
        }
      }

      return allActiveTrips;
    });
  }

  // Get completed trips for the current driver
  Stream<List<Trip>> getCompletedTrips() {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) return Stream.value([]);

    return _firestore.collection('users').snapshots().asyncMap((
      usersSnapshot,
    ) async {
      List<Trip> allCompletedTrips = [];

      for (var userDoc in usersSnapshot.docs) {
        try {
          // Get completed trips
          final completedTripsQuery = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('trips')
              .where('status', isEqualTo: 'completed')
              .get();

          // Get cancelled trips
          final cancelledTripsQuery = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('trips')
              .where('status', isEqualTo: 'cancelled')
              .get();

          // Process completed trips
          for (var tripDoc in completedTripsQuery.docs) {
            final tripData = tripDoc.data();
            final assignedDriverIds = List<String>.from(
              tripData['assignedDriverIds'] ?? [],
            );

            bool isAssignedToCurrentDriver = assignedDriverIds.contains(
              driverId,
            );

            if (isAssignedToCurrentDriver) {
              allCompletedTrips.add(Trip.fromMap(tripData, tripDoc.id));
            }
          }

          // Process cancelled trips
          for (var tripDoc in cancelledTripsQuery.docs) {
            final tripData = tripDoc.data();
            final assignedDriverIds = List<String>.from(
              tripData['assignedDriverIds'] ?? [],
            );

            bool isAssignedToCurrentDriver = assignedDriverIds.contains(
              driverId,
            );

            if (isAssignedToCurrentDriver) {
              allCompletedTrips.add(Trip.fromMap(tripData, tripDoc.id));
            }
          }
        } catch (e) {
          // Continue processing other users on error
        }
      }

      // Sort by completion time (most recent first)
      allCompletedTrips.sort((a, b) {
        final aTime = a.completedAt ?? a.cancelledAt ?? DateTime.now();
        final bTime = b.completedAt ?? b.cancelledAt ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      return allCompletedTrips;
    });
  }

  // Update trip status
  Future<void> updateTripStatus(
    String userId,
    String tripId,
    String status, {
    DateTime? timestamp,
  }) async {
    try {
      final doc = _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId);

      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add status-specific timestamps
      if (status == 'in-progress') {
        updateData['inProgressAt'] = timestamp ?? FieldValue.serverTimestamp();
      } else if (status == 'completed') {
        updateData['completedAt'] = timestamp ?? FieldValue.serverTimestamp();
      }

      await doc.update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Start trip (change status to in-progress)
  Future<void> startTrip(String userId, String tripId) async {
    try {
      final driverId = _authService.currentUser?.uid;
      if (driverId == null) {
        throw Exception('Driver not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .update({
            'status': 'in-progress',
            'inProgressAt': FieldValue.serverTimestamp(),
            'startedBy': driverId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Complete trip
  Future<void> completeTrip(String userId, String tripId) async {
    try {
      final driverId = _authService.currentUser?.uid;
      if (driverId == null) {
        throw Exception('Driver not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trips')
          .doc(tripId)
          .update({
            'status': 'completed',
            'completedAt': FieldValue.serverTimestamp(),
            'completedBy': driverId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Cancel trip with reason
  Future<void> cancelTrip(
    String userId,
    String tripId,
    String cancellationReason,
  ) async {
    final driverId = _authService.currentUser?.uid;
    if (driverId == null) {
      throw Exception('Driver not authenticated');
    }

    try {
      // Search across all users to find the trip
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        try {
          final tripsSnapshot = await _firestore
              .collection('users')
              .doc(userDoc.id)
              .collection('trips')
              .doc(tripId)
              .get();

          if (tripsSnapshot.exists) {
            await _firestore
                .collection('users')
                .doc(userDoc.id)
                .collection('trips')
                .doc(tripId)
                .update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                  'cancellationReason': cancellationReason,
                  'cancelledBy': driverId,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
            return;
          }
        } catch (e) {
          // Continue processing other users on error
        }
      }

      throw Exception('Trip not found');
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to find trip across all users
  Future<Map<String, String>?> findTripLocation(String tripId) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final tripDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('trips')
            .doc(tripId)
            .get();

        if (tripDoc.exists) {
          return {'userId': userDoc.id, 'tripId': tripId};
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch driver information
  Future<Map<String, dynamic>?> getDriverInfo(String driverId) async {
    try {
      final driverDoc = await _firestore
          .collection('drivers')
          .doc(driverId)
          .get();
      if (driverDoc.exists) {
        return driverDoc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch truck information
  Future<Map<String, dynamic>?> getTruckInfo(String truckId) async {
    try {
      final truckDoc = await _firestore.collection('trucks').doc(truckId).get();
      if (truckDoc.exists) {
        return truckDoc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Fetch customer information
  Future<Map<String, dynamic>?> getCustomerInfo(String customerId) async {
    try {
      final customerDoc = await _firestore
          .collection('users')
          .doc(customerId)
          .get();
      if (customerDoc.exists) {
        return customerDoc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
