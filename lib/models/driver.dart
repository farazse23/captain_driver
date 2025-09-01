import 'dart:convert';
import 'dart:typed_data';

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String cnic;
  final String licenseNumber;
  final String licenseImage; // Base64
  final String profileImage; // Base64
  final String address;
  final String status;
  final String role;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.cnic,
    required this.licenseNumber,
    required this.licenseImage,
    required this.profileImage,
    required this.address,
    required this.status,
    required this.role,
  });

  factory Driver.fromMap(Map<String, dynamic> map, String id) {
    return Driver(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      cnic: map['cnic'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      licenseImage: map['licenseImage'] ?? '',
      profileImage: map['profileImage'] ?? '',
      address: map['address'] ?? '',
      status: map['status'] ?? '',
      role: map['role'] ?? '',
    );
  }

  factory Driver.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Driver(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      cnic: data['cnic'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      licenseImage: data['licenseImage'] ?? '',
      profileImage: data['profileImage'] ?? '',
      address: data['address'] ?? '',
      status: data['status'] ?? '',
      role: data['role'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'cnic': cnic,
      'licenseNumber': licenseNumber,
      'licenseImage': licenseImage,
      'profileImage': profileImage,
      'address': address,
      'status': status,
      'role': role,
    };
  }

  // Convert Base64 string to Uint8List for image display
  Uint8List? getProfileImageBytes() {
    if (profileImage.isNotEmpty) {
      // If it's a URL, return null so UI can load via NetworkImage
      if (profileImage.startsWith('http')) {
        return null;
      }
      try {
        // Remove data URL prefix if present
        String base64String = profileImage;
        if (base64String.startsWith('data:image/')) {
          base64String = base64String.substring(base64String.indexOf(',') + 1);
        }
        return base64Decode(base64String);
      } catch (e) {
        print('Error decoding profile image: $e');
        return null;
      }
    }
    return null;
  }

  // Convert Base64 string to Uint8List for license image
  Uint8List? getLicenseImageBytes() {
    if (licenseImage.isNotEmpty) {
      // If it's a URL, return null so UI can load via NetworkImage
      if (licenseImage.startsWith('http')) {
        return null;
      }
      try {
        // Remove data URL prefix if present
        String base64String = licenseImage;
        if (base64String.startsWith('data:image/')) {
          base64String = base64String.substring(base64String.indexOf(',') + 1);
        }
        return base64Decode(base64String);
      } catch (e) {
        print('Error decoding license image: $e');
        return null;
      }
    }
    return null;
  }

  // Helpers to detect URL-based images
  bool get hasProfileImageUrl => profileImage.startsWith('http');
  bool get hasLicenseImageUrl => licenseImage.startsWith('http');
}
