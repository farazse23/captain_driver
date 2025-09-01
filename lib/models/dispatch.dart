import 'package:cloud_firestore/cloud_firestore.dart';

class DispatchImage {
  final String id;
  final String dispatchId;
  final String driverId;
  final String imageUrl;
  final String? message;
  final DateTime uploadedAt;
  final String imageName;

  DispatchImage({
    required this.id,
    required this.dispatchId,
    required this.driverId,
    required this.imageUrl,
    this.message,
    required this.uploadedAt,
    required this.imageName,
  });

  factory DispatchImage.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return DispatchImage(
      id: documentId,
      dispatchId: data['dispatchId'] ?? '',
      driverId: data['driverId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      message: data['message'],
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageName: data['imageName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dispatchId': dispatchId,
      'driverId': driverId,
      'imageUrl': imageUrl,
      'message': message,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'imageName': imageName,
    };
  }
}
