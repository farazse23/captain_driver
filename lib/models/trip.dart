import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Trip {
  final String id;
  final String customerId;
  final String? driverId;
  final String? truckId;
  final String
  status; // 'pending', 'assigned', 'in-progress', 'completed', 'cancelled'
  final String pickupAddress;
  final String dropoffAddress;
  final String truckType;
  final double weight;
  final int numberOfTrucks;
  final String? note;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? inProgressAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? cancelledBy;
  final String? completionImage; // Base64
  final List<String> assignedDriverIds;
  final List<String> assignedTruckIds;
  final int trucksAssigned;
  final int trucksRequested;
  final int totalAssignments;
  final List<Map<String, dynamic>>? assignmentDetails;

  // Customer details
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;

  const Trip({
    required this.id,
    required this.customerId,
    this.driverId,
    this.truckId,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.truckType,
    required this.weight,
    required this.numberOfTrucks,
    this.note,
    required this.createdAt,
    this.assignedAt,
    this.inProgressAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.cancelledBy,
    this.completionImage,
    required this.assignedDriverIds,
    required this.assignedTruckIds,
    required this.trucksAssigned,
    required this.trucksRequested,
    required this.totalAssignments,
    this.assignmentDetails,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
  });

  factory Trip.fromMap(Map<String, dynamic> map, String id) {
    return Trip(
      id: id,
      customerId: map['customerId'] ?? '',
      driverId: map['driverId'],
      truckId: map['truckId'],
      status: map['status'] ?? 'pending',
      pickupAddress: map['pickupAddress'] ?? '',
      dropoffAddress: map['dropoffAddress'] ?? '',
      truckType: map['truckType'] ?? '',
      weight: _parseDouble(map['weight']),
      numberOfTrucks: map['numberOfTrucks'] ?? 1,
      note: map['note'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate(),
      inProgressAt: (map['inProgressAt'] as Timestamp?)?.toDate(),
      completedAt: (map['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (map['cancelledAt'] as Timestamp?)?.toDate(),
      cancellationReason: map['cancellationReason'],
      cancelledBy: map['cancelledBy'],
      completionImage: map['completionImage'],
      assignedDriverIds: List<String>.from(map['assignedDriverIds'] ?? []),
      assignedTruckIds: List<String>.from(map['assignedTruckIds'] ?? []),
      trucksAssigned: map['trucksAssigned'] ?? 0,
      trucksRequested: map['trucksRequested'] ?? 1,
      totalAssignments: map['totalAssignments'] ?? 0,
      assignmentDetails: map['assignmentDetails'] is List
          ? List<Map<String, dynamic>>.from(
              (map['assignmentDetails'] as List).map(
                (item) => Map<String, dynamic>.from(item),
              ),
            )
          : null,
      customerName: map['customerName'],
      customerEmail: map['customerEmail'],
      customerPhone: map['customerPhone'],
      customerAddress: map['customerAddress'],
    );
  }

  // Helper method to parse string or numeric values to double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'driverId': driverId,
      'truckId': truckId,
      'status': status,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'truckType': truckType,
      'weight': weight,
      'numberOfTrucks': numberOfTrucks,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'inProgressAt': inProgressAt != null
          ? Timestamp.fromDate(inProgressAt!)
          : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'completionImage': completionImage,
      'assignedDriverIds': assignedDriverIds,
      'assignedTruckIds': assignedTruckIds,
      'trucksAssigned': trucksAssigned,
      'trucksRequested': trucksRequested,
      'totalAssignments': totalAssignments,
      'assignmentDetails': assignmentDetails,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
    };
  }

  Trip copyWith({
    String? id,
    String? customerId,
    String? driverId,
    String? truckId,
    String? status,
    String? pickupAddress,
    String? dropoffAddress,
    String? truckType,
    double? weight,
    int? numberOfTrucks,
    String? note,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? inProgressAt,
    DateTime? completedAt,
    String? completionImage,
    List<String>? assignedDriverIds,
    List<String>? assignedTruckIds,
    int? trucksAssigned,
    int? trucksRequested,
    int? totalAssignments,
    List<Map<String, dynamic>>? assignmentDetails,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String? customerAddress,
  }) {
    return Trip(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      truckId: truckId ?? this.truckId,
      status: status ?? this.status,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      truckType: truckType ?? this.truckType,
      weight: weight ?? this.weight,
      numberOfTrucks: numberOfTrucks ?? this.numberOfTrucks,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      inProgressAt: inProgressAt ?? this.inProgressAt,
      completedAt: completedAt ?? this.completedAt,
      completionImage: completionImage ?? this.completionImage,
      assignedDriverIds: assignedDriverIds ?? this.assignedDriverIds,
      assignedTruckIds: assignedTruckIds ?? this.assignedTruckIds,
      trucksAssigned: trucksAssigned ?? this.trucksAssigned,
      trucksRequested: trucksRequested ?? this.trucksRequested,
      totalAssignments: totalAssignments ?? this.totalAssignments,
      assignmentDetails: assignmentDetails ?? this.assignmentDetails,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerPhone,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
    );
  }

  String get formattedWeight => '${weight.toStringAsFixed(1)} kg';

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Pending Assignment';
      case 'assigned':
        return 'Assigned';
      case 'in-progress':
        return 'On the way';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in-progress':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
