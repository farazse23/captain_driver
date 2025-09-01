import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_colors.dart';
import '../trip_update/trip_update_screen.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({super.key});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  GoogleMapController? _mapController;
  String? _driverId;
  Map<String, dynamic>? dispatch;
  String? dispatchId;
  Map<String, dynamic>? driverMap;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _sourceLocation;
  LatLng? _destinationLocation;
  LatLng? _currentLocation;

  bool _isStarted = false;
  DateTime? _startTime;
  String? _startTimeFormatted;

  @override
  void initState() {
    super.initState();
    _driverId = _auth.currentUser?.uid;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      dispatch = args['dispatch'];
      dispatchId = args['dispatchId'];
      driverMap = args['driverMap'];

      // Use the passed driverId from AssignedTripScreen (this is the correct one)
      _driverId = args['driverId'] ?? _auth.currentUser?.uid;

      print('ActiveTrip - Using driverId: $_driverId');
      print('ActiveTrip - Driver status: ${driverMap?['status']}');

      _setupMap();
      _checkTripStatus();
    } else {
      // No arguments passed - check if driver has any active trips
      _findActiveTrip();
    }
  }

  Future<void> _findActiveTrip() async {
    try {
      _driverId = _auth.currentUser?.uid;
      if (_driverId == null) {
        _getCurrentLocation();
        return;
      }

      print('Searching for active trip for driver: $_driverId');

      // First, try to find driver document by email to get correct driver ID
      final user = _auth.currentUser;
      if (user?.email != null) {
        final driverQuery = await _firestore
            .collection('drivers')
            .where('email', isEqualTo: user!.email)
            .limit(1)
            .get();

        if (driverQuery.docs.isNotEmpty) {
          _driverId = driverQuery.docs.first.id;
          print('Found driver document ID: $_driverId');
        }
      }

      // Search for dispatches where this driver has in-progress status
      final dispatches = await _firestore.collection('dispatches').get();

      for (var doc in dispatches.docs) {
        final data = doc.data();
        final driverAssignments =
            data['driverAssignments'] as Map<String, dynamic>?;

        if (driverAssignments != null) {
          // Check multiple possible driver ID formats
          var driverData = driverAssignments[_driverId];

          // Try UID if document ID doesn't work
          if (driverData == null && user != null) {
            driverData = driverAssignments[user.uid];
          }

          // Try email if UID doesn't work
          if (driverData == null && user?.email != null) {
            driverData = driverAssignments[user!.email];
          }

          if (driverData != null && driverData['status'] == 'in-progress') {
            print('Found active trip: ${doc.id}');

            // Set the trip data
            dispatch = data;
            dispatchId = doc.id;
            driverMap = driverData;

            _setupMap();
            _checkTripStatus();

            if (mounted) setState(() {});
            return;
          }
        }
      }

      // No active trip found, show current location
      print('No active trip found for driver $_driverId');
      _getCurrentLocation();
    } catch (e) {
      print('Error finding active trip: $e');
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      _currentLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error getting current location: $e');
      // Default to Islamabad if location fails
      _currentLocation = const LatLng(33.6844, 73.0479);
      if (mounted) setState(() {});
    }
  }

  void _checkTripStatus() {
    if (driverMap != null) {
      // Only check THIS driver's status within their assignment map
      // NOT the overall dispatch status
      _isStarted = driverMap!['status'] == 'in-progress';

      print('Trip status for driver $_driverId: ${driverMap!['status']}');
      print('Is trip started: $_isStarted');

      // Load start time if trip is already in progress
      if (_isStarted && driverMap!['startedAt'] != null) {
        final Timestamp startedAtTimestamp = driverMap!['startedAt'];
        _startTime = startedAtTimestamp.toDate();
        _startTimeFormatted = _formatTime(_startTime!);
        print('Trip started at: $_startTimeFormatted');
      }
    }
  }

  void _setupMap() {
    try {
      if (dispatch != null) {
        print('Setting up map with dispatch: ${dispatch!.keys}');

        // Get coordinates from dispatch
        final sourceCoordinates = dispatch!['sourceCoordinates'];
        final destinationCoordinates = dispatch!['destinationCoordinates'];

        print('Source coordinates: $sourceCoordinates');
        print('Destination coordinates: $destinationCoordinates');

        if (sourceCoordinates != null && destinationCoordinates != null) {
          _sourceLocation = LatLng(
            sourceCoordinates['lat'].toDouble(),
            sourceCoordinates['lng'].toDouble(),
          );
          _destinationLocation = LatLng(
            destinationCoordinates['lat'].toDouble(),
            destinationCoordinates['lng'].toDouble(),
          );

          _addMarkers();
          _addRoute();
        } else {
          print('Missing coordinates in dispatch data');
          // Set default coordinates if missing
          _sourceLocation = const LatLng(33.6844, 73.0479); // Islamabad
          _destinationLocation = const LatLng(32.5007, 74.3294); // Sialkot
          _addMarkers();
          _addRoute();
        }
      }
    } catch (e) {
      print('Error setting up map: $e');
      // Set default coordinates on error
      _sourceLocation = const LatLng(33.6844, 73.0479); // Islamabad
      _destinationLocation = const LatLng(32.5007, 74.3294); // Sialkot
      _addMarkers();
      _addRoute();
    }
  }

  void _addMarkers() {
    try {
      _markers.clear();

      if (_sourceLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _sourceLocation!,
            infoWindow: InfoWindow(
              title: 'Pickup Location',
              snippet: dispatch?['sourceLocation'] ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (_destinationLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationLocation!,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: dispatch?['destinationLocation'] ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding markers: $e');
    }
  }

  void _addRoute() async {
    try {
      if (_sourceLocation != null && _destinationLocation != null) {
        _polylines.clear();

        // Get real route from Google Directions API
        final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
        if (apiKey == null) {
          print('Google Maps API key not found in .env file');
          _addStraightLineRoute(); // Fallback to straight line
          return;
        }

        final String url =
            'https://maps.googleapis.com/maps/api/directions/json'
            '?origin=${_sourceLocation!.latitude},${_sourceLocation!.longitude}'
            '&destination=${_destinationLocation!.latitude},${_destinationLocation!.longitude}'
            '&key=$apiKey';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final overviewPolyline = route['overview_polyline']['points'];
            final List<LatLng> polylinePoints = _decodePolyline(
              overviewPolyline,
            );

            _polylines.add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: polylinePoints,
                color: AppColors.primary,
                width: 5,
              ),
            );

            if (mounted) setState(() {});
          } else {
            print('Directions API error: ${data['status']}');
            _addStraightLineRoute(); // Fallback
          }
        } else {
          print('HTTP error: ${response.statusCode}');
          _addStraightLineRoute(); // Fallback
        }
      }
    } catch (e) {
      print('Error getting route: $e');
      _addStraightLineRoute(); // Fallback to straight line
    }
  }

  void _addStraightLineRoute() {
    if (_sourceLocation != null && _destinationLocation != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_sourceLocation!, _destinationLocation!],
          color: AppColors.primary,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
      if (mounted) setState(() {});
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      _mapController = controller;
      print('Map controller initialized');

      // Fit map to show both markers
      if (_sourceLocation != null && _destinationLocation != null) {
        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(
            _sourceLocation!.latitude < _destinationLocation!.latitude
                ? _sourceLocation!.latitude
                : _destinationLocation!.latitude,
            _sourceLocation!.longitude < _destinationLocation!.longitude
                ? _sourceLocation!.longitude
                : _destinationLocation!.longitude,
          ),
          northeast: LatLng(
            _sourceLocation!.latitude > _destinationLocation!.latitude
                ? _sourceLocation!.latitude
                : _destinationLocation!.latitude,
            _sourceLocation!.longitude > _destinationLocation!.longitude
                ? _sourceLocation!.longitude
                : _destinationLocation!.longitude,
          ),
        );

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100.0),
        );
      }
    } catch (e) {
      print('Error in map creation: $e');
    }
  }

  Future<void> _startTrip() async {
    // Navigate to trip update screen for uploading start image
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripUpdateScreen(
          dispatchId: dispatchId!,
          driverId: _driverId!,
          updateType: 'start',
        ),
      ),
    );

    if (result == true) {
      // Update driver status to in-progress
      await _updateDriverStatus('in-progress');

      // Set start time
      _startTime = DateTime.now();
      _startTimeFormatted = _formatTime(_startTime!);

      setState(() {
        _isStarted = true;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip started successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _completeTrip() async {
    // Navigate to trip update screen for uploading completion image
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripUpdateScreen(
          dispatchId: dispatchId!,
          driverId: _driverId!,
          updateType: 'complete',
        ),
      ),
    );

    if (result == true) {
      // Update driver status to completed
      await _updateDriverStatus('completed');

      // Show completion message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip completed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Navigate back to assigned trips screen
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  String _formatTime(DateTime time) {
    String period = time.hour >= 12 ? 'PM' : 'AM';
    int hour = time.hour > 12 ? time.hour - 12 : time.hour;
    if (hour == 0) hour = 12;

    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _updateDriverStatus(String status) async {
    try {
      // Update ONLY this driver's status in their assignment map
      // NOT the overall dispatch status - each driver has individual status
      Map<String, dynamic> updateData = {
        'driverAssignments.$_driverId.status': status,
      };

      if (status == 'in-progress') {
        updateData['driverAssignments.$_driverId.startedAt'] =
            FieldValue.serverTimestamp();
        print('Starting trip for driver: $_driverId');
      } else if (status == 'completed') {
        updateData['driverAssignments.$_driverId.completedAt'] =
            FieldValue.serverTimestamp();
        print('Completing trip for driver: $_driverId');
      }

      await _firestore
          .collection('dispatches')
          .doc(dispatchId)
          .update(updateData);

      print('Successfully updated driver $_driverId status to: $status');
    } catch (e) {
      print('Error updating driver status: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating trip status')));
    }
  }

  void _openTripUpdates() {
    // Check if there's an active trip
    if (dispatchId == null || _driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active trip available'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripUpdateScreen(
          dispatchId: dispatchId!,
          driverId: _driverId!,
          updateType: 'update',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false, // Prevent overflow when keyboard appears
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Active Trip',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: _openTripUpdates,
                        icon: Icon(Icons.camera_alt, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dispatch ID: ${dispatchId ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Map
            Expanded(
              flex: 2,
              child:
                  (_sourceLocation != null && _destinationLocation != null) ||
                      _currentLocation != null
                  ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            print('Google Map created successfully');
                            _onMapCreated(controller);
                          },
                          initialCameraPosition: CameraPosition(
                            target:
                                _sourceLocation ??
                                _currentLocation ??
                                const LatLng(33.6844, 73.0479),
                            zoom: _sourceLocation != null ? 10.0 : 15.0,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          mapType: MapType.normal,
                          zoomControlsEnabled: false,
                          compassEnabled: true,
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                        ),
                      ),
                    )
                  : Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.map, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Loading map...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Trip Info & Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Trip Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isStarted
                            ? Colors.orange.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isStarted
                                ? 'Trip In Progress'
                                : 'Trip Not Started',
                            style: TextStyle(
                              color: _isStarted
                                  ? Colors.orange
                                  : AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (_isStarted && _startTimeFormatted != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Started at: $_startTimeFormatted',
                              style: TextStyle(
                                color: _isStarted
                                    ? Colors.orange
                                    : AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Locations
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'From',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dispatch?['sourceLocation'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'To',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dispatch?['destinationLocation'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        if (!_isStarted) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _startTrip,
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Start Trip',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _completeTrip,
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Complete Trip',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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
