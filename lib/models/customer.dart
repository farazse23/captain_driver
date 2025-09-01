class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
  });

  factory Customer.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Customer(
      id: documentId,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      address: data['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'phone': phone, 'email': email, 'address': address};
  }
}
