import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../widgets/custom_animation.dart';

class CompletedTripScreen extends StatefulWidget {
  const CompletedTripScreen({super.key});

  @override
  State<CompletedTripScreen> createState() => _CompletedTripScreenState();
}

class _CompletedTripScreenState extends State<CompletedTripScreen> {
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
        // Find driver document by email
        final driverQuery = await _firestore
            .collection('drivers')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (driverQuery.docs.isNotEmpty) {
          _driverId = driverQuery.docs.first.id;
        } else {
          _driverId = user.uid;
        }
        setState(() {});
      }
    } catch (e) {
      print('Error getting driver ID: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isWideScreen = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header with responsive image height
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
                      height: size.height * (isSmallScreen ? 0.22 : 0.28),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: isWideScreen ? 32 : 20,
                  top: size.height * (isSmallScreen ? 0.12 : 0.16),
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(-0.6, 0),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed Trips',
                          style: TextStyle(
                            fontSize: isWideScreen ? 26 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Trip history',
                          style: TextStyle(
                            fontSize: isWideScreen ? 18 : 16,
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

            SizedBox(height: isSmallScreen ? 12 : 16),

            // Content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('dispatches').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading completed trips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Filter dispatches where this driver is completed
                  final completedDispatches = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final driverAssignments =
                        data['driverAssignments'] as Map<String, dynamic>?;
                    if (driverAssignments == null || _driverId == null) {
                      return false;
                    }

                    final user = _auth.currentUser;
                    var driverMap = driverAssignments[_driverId];

                    // Try UID if document ID doesn't work
                    if (driverMap == null && user != null) {
                      driverMap = driverAssignments[user.uid];
                    }

                    // Try email if UID doesn't work
                    if (driverMap == null && user?.email != null) {
                      driverMap = driverAssignments[user!.email];
                    }

                    if (driverMap == null) return false;
                    final status = driverMap['status'] ?? '';
                    return status == 'completed';
                  }).toList();

                  // If no completed trips, show empty state
                  if (completedDispatches.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FadeSlideAnimation(
                            duration: const Duration(milliseconds: 800),
                            beginOffset: const Offset(0, 0.3),
                            curve: Curves.easeOut,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          FadeSlideAnimation(
                            duration: const Duration(milliseconds: 1000),
                            beginOffset: const Offset(0, 0.2),
                            curve: Curves.easeOut,
                            child: Text(
                              'No Completed Trips',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FadeSlideAnimation(
                            duration: const Duration(milliseconds: 1200),
                            beginOffset: const Offset(0, 0.2),
                            curve: Curves.easeOut,
                            child: Text(
                              'You haven\'t completed any trips yet.\nStart by accepting assigned trips.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          FadeSlideAnimation(
                            duration: const Duration(milliseconds: 1400),
                            beginOffset: const Offset(0, 0.2),
                            curve: Curves.easeOut,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/assigned_trip');
                              },
                              icon: const Icon(Icons.assignment),
                              label: const Text('View Assigned Trips'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Show completed trips list
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmallScreen = constraints.maxHeight < 600;
                      final horizontalPadding = size.width > 600 ? 24.0 : 16.0;

                      return ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isSmallScreen ? 8 : 16,
                          horizontalPadding,
                          isSmallScreen ? 8 : 24,
                        ),
                        itemCount: completedDispatches.length,
                        itemBuilder: (context, index) {
                          final doc = completedDispatches[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final driverAssignments =
                              data['driverAssignments'] as Map<String, dynamic>;

                          // Get the correct driver map
                          final user = _auth.currentUser;
                          var driverMap = driverAssignments[_driverId];
                          if (driverMap == null && user != null) {
                            driverMap = driverAssignments[user.uid];
                          }
                          if (driverMap == null && user?.email != null) {
                            driverMap = driverAssignments[user!.email];
                          }

                          return _buildTripCard(data, doc.id, driverMap);
                        },
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

  Widget _buildTripCard(
    Map<String, dynamic> dispatch,
    String dispatchId,
    Map<String, dynamic> driverMap,
  ) {
    // Calculate overall dispatch status
    final driverAssignments =
        dispatch['driverAssignments'] as Map<String, dynamic>? ?? {};
    final allStatuses = driverAssignments.values
        .map((v) => v['status'] as String?)
        .toList();
    final totalDrivers = allStatuses.length;
    final completedDrivers = allStatuses
        .where((status) => status == 'completed')
        .length;
    final inProgressDrivers = allStatuses
        .where((status) => status == 'in-progress')
        .length;

    String overallStatus;
    Color overallStatusColor;

    if (completedDrivers == totalDrivers) {
      overallStatus = 'ALL COMPLETED';
      overallStatusColor = Colors.green;
    } else if (inProgressDrivers > 0) {
      overallStatus = 'IN PROGRESS';
      overallStatusColor = Colors.orange;
    } else {
      overallStatus = 'ASSIGNED';
      overallStatusColor = AppColors.primary;
    }

    return FadeSlideAnimation(
      duration: Duration(milliseconds: 600 + (dispatchId.hashCode % 400)),
      beginOffset: const Offset(0, 0.2),
      curve: Curves.easeOut,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideCard = constraints.maxWidth > 600;
          final cardMargin = isWideCard ? 20.0 : 12.0;

          return Card(
            margin: EdgeInsets.only(bottom: cardMargin),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isWideCard ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Trip header with dispatch ID and status - responsive layout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispatch ID: $dispatchId',
                        style: TextStyle(
                          fontSize: isWideCard ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideCard ? 10 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'MY STATUS: COMPLETED',
                              style: TextStyle(
                                fontSize: isWideCard ? 11 : 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideCard ? 10 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: overallStatusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              overallStatus,
                              style: TextStyle(
                                fontSize: isWideCard ? 11 : 10,
                                fontWeight: FontWeight.bold,
                                color: overallStatusColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWideCard ? 10 : 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$completedDrivers/$totalDrivers Drivers',
                              style: TextStyle(
                                fontSize: isWideCard ? 11 : 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: isWideCard ? 16 : 12),

                  // Overall dispatch status info (simplified)
                  Container(
                    padding: EdgeInsets.all(isWideCard ? 12 : 10),
                    decoration: BoxDecoration(
                      color: overallStatusColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: overallStatusColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          size: isWideCard ? 18 : 16,
                          color: overallStatusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Overall Status: $overallStatus',
                            style: TextStyle(
                              fontSize: isWideCard ? 13 : 12,
                              fontWeight: FontWeight.w600,
                              color: overallStatusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$completedDrivers/$totalDrivers',
                          style: TextStyle(
                            fontSize: isWideCard ? 13 : 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Pickup location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pickup',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dispatch['sourceLocation'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: isWideCard ? 15 : 14,
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

                  const SizedBox(height: 12),

                  // Drop-off location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Drop-off',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dispatch['destinationLocation'] ?? 'N/A',
                              style: TextStyle(
                                fontSize: isWideCard ? 15 : 14,
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

                  const SizedBox(height: 16),

                  // Trip timing information (simplified and responsive)
                  if (driverMap['startedAt'] != null ||
                      driverMap['completedAt'] != null) ...[
                    Container(
                      padding: EdgeInsets.all(isWideCard ? 12 : 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (driverMap['startedAt'] != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Started: ${_formatDateTime(driverMap['startedAt']?.toDate())}',
                                    style: TextStyle(
                                      fontSize: isWideCard ? 12 : 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (driverMap['completedAt'] != null) ...[
                            if (driverMap['startedAt'] != null)
                              const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Completed: ${_formatDateTime(driverMap['completedAt']?.toDate())}',
                                    style: TextStyle(
                                      fontSize: isWideCard ? 12 : 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (driverMap['startedAt'] != null &&
                              driverMap['completedAt'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Duration: ${_formatDuration(_calculateDuration(driverMap['startedAt']?.toDate(), driverMap['completedAt']?.toDate()))}',
                                    style: TextStyle(
                                      fontSize: isWideCard ? 12 : 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // View Details Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/trip_details',
                          arguments: {
                            'dispatch': dispatch,
                            'dispatchId': dispatchId,
                            'driverMap': driverMap,
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'View Full Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isWideCard ? 16 : 14,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return DateFormat('MMM dd, HH:mm').format(dateTime);
  }

  Duration _calculateDuration(DateTime? start, DateTime? end) {
    if (start == null || end == null) return Duration.zero;
    return end.difference(start);
  }

  // ignore: unused_element
  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'N/A';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
