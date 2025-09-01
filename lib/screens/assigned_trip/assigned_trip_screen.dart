import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignedTripScreen extends StatefulWidget {
  const AssignedTripScreen({super.key});

  @override
  State<AssignedTripScreen> createState() => _AssignedTripScreenState();
}

class _AssignedTripScreenState extends State<AssignedTripScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _getDriverId();
  }

  Future<void> _getDriverId() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        print('Current user email: ${user.email}');
        print('Current user UID: ${user.uid}');

        // Find driver document by email
        final driverQuery = await _firestore
            .collection('drivers')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (driverQuery.docs.isNotEmpty) {
          _driverId = driverQuery.docs.first.id;
          print('Found driver ID: $_driverId');

          // Also try the UID as backup
          if (_driverId != user.uid) {
            print(
              'Driver document ID ($_driverId) differs from Auth UID (${user.uid})',
            );
          }

          setState(() {}); // Refresh UI with correct driver ID
        } else {
          print('No driver document found for email: ${user.email}');
          // Fallback to UID
          _driverId = user.uid;
          print('Using Auth UID as driver ID: $_driverId');
          setState(() {});
        }
      }
    } catch (e) {
      print('Error getting driver ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
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
                      'assets/images/AssignedTrip.jpg',
                      width: double.infinity,
                      height: size.height * 0.34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  top: size.height * 0.18,
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(-0.6, 0),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Assigned Trips',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black38,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your upcoming assignments',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black38,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Trip List with animations
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('dispatches').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    print('Stream Error: ${snapshot.error}');
                    return Center(
                      child: Text(
                        'Error loading trips: ${snapshot.error}',
                        style: TextStyle(color: Colors.red[600], fontSize: 16),
                      ),
                    );
                  }

                  if (!snapshot.hasData || _driverId == null) {
                    return const Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  // Filter dispatches to show only those assigned to current driver
                  final assignedDispatches = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final driverAssignments =
                        data['driverAssignments'] as Map<String, dynamic>?;

                    if (driverAssignments == null) return false;
                    if (!driverAssignments.containsKey(_driverId)) return false;

                    final driverMap =
                        driverAssignments[_driverId] as Map<String, dynamic>;
                    final status = driverMap['status'] as String?;

                    // Show dispatches that are assigned or in-progress
                    return status == 'assigned' || status == 'in-progress';
                  }).toList();

                  if (assignedDispatches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Trips Assigned',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You don\'t have any assigned trips at the moment.\nCheck back later for new assignments.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: assignedDispatches.length,
                    itemBuilder: (context, index) {
                      final doc = assignedDispatches[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final driverMap =
                          (data['driverAssignments']
                              as Map<String, dynamic>)[_driverId];
                      return FadeSlideAnimation(
                        duration: Duration(milliseconds: 600 + index * 200),
                        beginOffset: const Offset(0, 0.2),
                        curve: Curves.easeOut,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isWideCard = constraints.maxWidth > 400;

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.only(bottom: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header with responsive layout
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Dispatch ID
                                        Text(
                                          'Dispatch ID: ${doc.id}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isWideCard ? 16 : 15,
                                            color: AppColors.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        // Status badge in a Wrap for better responsiveness
                                        Wrap(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    driverMap['status'] ==
                                                        'in-progress'
                                                    ? Colors.orange.withOpacity(
                                                        0.1,
                                                      )
                                                    : AppColors.primary
                                                          .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                driverMap['status'] ==
                                                        'in-progress'
                                                    ? 'In Progress'
                                                    : 'Assigned',
                                                style: TextStyle(
                                                  color:
                                                      driverMap['status'] ==
                                                          'in-progress'
                                                      ? Colors.orange
                                                      : AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 18,
                                          color: AppColors.textTertiary,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Assigned: ${_formatDate(driverMap['assignedAt']?.toDate() ?? DateTime.now())}',
                                            style: TextStyle(
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            data['sourceLocation'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            data['destinationLocation'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Truck info (simplified and responsive)
                                    if (data['trucksRequired'] != null &&
                                        data['trucksRequired'] is List &&
                                        (data['trucksRequired'] as List)
                                            .isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.local_shipping,
                                              size: 16,
                                              color: AppColors.textTertiary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                (data['trucksRequired']
                                                        as List)[0]['truckType'] ??
                                                    'N/A',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: isWideCard
                                                      ? 14
                                                      : 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    // Action buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/trip_details',
                                                arguments: {
                                                  'dispatch': data,
                                                  'dispatchId': doc.id,
                                                  'driverMap': driverMap,
                                                  'driverId': _driverId,
                                                },
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.info_outline,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'View Details',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child:
                                              driverMap['status'] ==
                                                  'in-progress'
                                              ? ElevatedButton.icon(
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/active_trip',
                                                      arguments: {
                                                        'dispatch': data,
                                                        'dispatchId': doc.id,
                                                        'driverMap': driverMap,
                                                        'driverId': _driverId,
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.navigation,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Continue',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                          horizontal: 8,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    elevation: 2,
                                                  ),
                                                )
                                              : ElevatedButton.icon(
                                                  onPressed: () async {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/active_trip',
                                                      arguments: {
                                                        'dispatch': data,
                                                        'dispatchId': doc.id,
                                                        'driverMap': driverMap,
                                                        'driverId': _driverId,
                                                      },
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.play_arrow,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Begin Trip',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 12,
                                                          horizontal: 8,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    elevation: 2,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
