import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/customer.dart';
import '../../models/driver.dart';
import '../../models/truck.dart';
import '../../widgets/custom_animation.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? dispatch;
  String? dispatchId;
  Map<String, dynamic>? driverMap;
  Customer? customer;
  List<Map<String, dynamic>> allDriversAndTrucks = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      dispatch = args['dispatch'];
      dispatchId = args['dispatchId'];
      driverMap = args['driverMap'];
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    try {
      // Load customer details
      if (dispatch?['customerId'] != null) {
        final customerDoc = await _firestore
            .collection('customers')
            .doc(dispatch!['customerId'])
            .get();
        if (customerDoc.exists) {
          customer = Customer.fromFirestore(
            customerDoc.data()!,
            customerDoc.id,
          );
        }
      }

      // Load all drivers and trucks assigned to this dispatch
      final driverAssignments =
          dispatch?['driverAssignments'] as Map<String, dynamic>? ?? {};

      for (String driverId in driverAssignments.keys) {
        final driverAssignment = driverAssignments[driverId];
        final truckId = driverAssignment['truckId'];

        // Get driver details
        final driverDoc = await _firestore
            .collection('drivers')
            .doc(driverId)
            .get();
        Driver? driver;
        if (driverDoc.exists) {
          driver = Driver.fromFirestore(driverDoc.data()!, driverDoc.id);
        }

        // Get truck details
        final truckDoc = await _firestore
            .collection('trucks')
            .doc(truckId)
            .get();
        Truck? truck;
        if (truckDoc.exists) {
          truck = Truck.fromFirestore(truckDoc.data()!, truckDoc.id);
        }

        allDriversAndTrucks.add({
          'driver': driver,
          'truck': truck,
          'assignment': driverAssignment,
        });
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isWideScreen = size.width > 600;

    if (isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Header with responsive height
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
                      'assets/images/TripDetails.jpg',
                      width: double.infinity,
                      height: size.height * (isSmallScreen ? 0.20 : 0.25),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: isWideScreen ? 32 : 20,
                  top: size.height * (isSmallScreen ? 0.08 : 0.12),
                  child: FadeSlideAnimation(
                    duration: const Duration(milliseconds: 1000),
                    beginOffset: const Offset(-0.6, 0),
                    curve: Curves.easeOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip Details',
                          style: TextStyle(
                            fontSize: isWideScreen ? 26 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Dispatch ID: ${dispatchId ?? 'N/A'}',
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
            SizedBox(height: isSmallScreen ? 8 : 16),

            // Content with responsive padding
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWideScreen ? 24 : 16,
                  vertical: isSmallScreen ? 8 : 16,
                ),
                children: [
                  // Trip Information
                  _buildTripInfoCard(isWideScreen, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Customer Information
                  _buildCustomerCard(isWideScreen, isSmallScreen),
                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // All Drivers & Trucks
                  _buildDriversAndTrucksCard(isWideScreen, isSmallScreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard([
    bool isWideScreen = false,
    bool isSmallScreen = false,
  ]) {
    // Calculate overall dispatch status
    final driverAssignments =
        dispatch?['driverAssignments'] as Map<String, dynamic>? ?? {};
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

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Trip Information',
                  style: TextStyle(
                    fontSize: isWideScreen ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // Overall Dispatch Status
            Container(
              padding: EdgeInsets.all(isWideScreen ? 16 : 12),
              decoration: BoxDecoration(
                color: overallStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: overallStatusColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.assessment,
                    color: overallStatusColor,
                    size: isWideScreen ? 24 : 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Dispatch Status',
                          style: TextStyle(
                            fontSize: isWideScreen ? 14 : 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          overallStatus,
                          style: TextStyle(
                            fontSize: isWideScreen ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: overallStatusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$completedDrivers/$totalDrivers Drivers Completed',
                    style: TextStyle(
                      fontSize: isWideScreen ? 13 : 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Pickup Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
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
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: isWideScreen ? 14 : 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dispatch?['sourceLocation'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: isWideScreen ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Drop-off Location
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
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
                        'Drop-off Location',
                        style: TextStyle(
                          fontSize: isWideScreen ? 14 : 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dispatch?['destinationLocation'] ?? 'N/A',
                        style: TextStyle(
                          fontSize: isWideScreen ? 18 : 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            // Pickup Date & Time
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup Date: ${_formatDateTime(dispatch?['pickupDateTime'])}',
                    style: TextStyle(
                      fontSize: isWideScreen ? 15 : 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard([
    bool isWideScreen = false,
    bool isSmallScreen = false,
  ]) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Customer Information',
                  style: TextStyle(
                    fontSize: isWideScreen ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            if (customer != null) ...[
              _buildDetailRow('Name', customer!.name, isWideScreen),
              _buildDetailRow('Phone', customer!.phone, isWideScreen),
              if (customer!.email != null)
                _buildDetailRow('Email', customer!.email!, isWideScreen),
              if (customer!.address != null)
                _buildDetailRow('Address', customer!.address!, isWideScreen),
            ] else
              Text(
                'Customer information not available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: isWideScreen ? 16 : 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriversAndTrucksCard([
    bool isWideScreen = false,
    bool isSmallScreen = false,
  ]) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(isWideScreen ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Assigned Drivers & Trucks',
                  style: TextStyle(
                    fontSize: isWideScreen ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),

            ...allDriversAndTrucks.map((item) {
              final Driver? driver = item['driver'];
              final Truck? truck = item['truck'];
              final assignment = item['assignment'];

              return Container(
                margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
                padding: EdgeInsets.all(isWideScreen ? 16 : 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Driver and Truck sections side by side on wide screens
                    isWideScreen
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Driver Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Driver',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (driver != null) ...[
                                      Text(
                                        'Name: ${driver.name}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Phone: ${driver.phone}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        'Driver info not available',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Truck Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Truck',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (truck != null) ...[
                                      Text(
                                        'Plate: ${truck.plateNumber}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Model: ${truck.model}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Type: ${truck.truckType}',
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ] else
                                      Text(
                                        'Truck info not available',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Driver Info
                              Text(
                                'Driver',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (driver != null) ...[
                                Text(
                                  'Name: ${driver.name}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Phone: ${driver.phone}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ] else
                                Text(
                                  'Driver info not available',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),

                              const SizedBox(height: 12),

                              // Truck Info
                              Text(
                                'Truck',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (truck != null) ...[
                                Text(
                                  'Plate Number: ${truck.plateNumber}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Model: ${truck.model}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Type: ${truck.truckType}',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ] else
                                Text(
                                  'Truck info not available',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),

                    SizedBox(height: isSmallScreen ? 6 : 8),

                    // Assignment Status and Timing
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWideScreen ? 12 : 10,
                            vertical: isWideScreen ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              assignment['status'],
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(assignment['status']),
                            style: TextStyle(
                              color: _getStatusColor(assignment['status']),
                              fontSize: isWideScreen ? 14 : 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (assignment['assignedAt'] != null)
                          Text(
                            'Assigned: ${_formatDate(assignment['assignedAt'].toDate())}',
                            style: TextStyle(
                              fontSize: isWideScreen ? 12 : 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),

                    // Show timing details based on status
                    if (assignment['startedAt'] != null ||
                        assignment['completedAt'] != null) ...[
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          if (assignment['startedAt'] != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Started: ${_formatDateTime(assignment['startedAt'])}',
                                  style: TextStyle(
                                    fontSize: isWideScreen ? 13 : 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          if (assignment['completedAt'] != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed: ${_formatDateTime(assignment['completedAt'])}',
                                  style: TextStyle(
                                    fontSize: isWideScreen ? 13 : 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, [
    bool isWideScreen = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWideScreen ? 100 : 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: isWideScreen ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isWideScreen ? 16 : 14,
                color: AppColors.textPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Not specified';

    DateTime dt;
    if (dateTime is Timestamp) {
      dt = dateTime.toDate();
    } else if (dateTime is DateTime) {
      dt = dateTime;
    } else {
      return 'Invalid date';
    }

    return '${dt.day}/${dt.month}/${dt.year} at ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'in-progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'assigned':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'in-progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      case 'assigned':
        return 'ASSIGNED';
      default:
        return 'UNKNOWN';
    }
  }
}
