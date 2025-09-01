class Truck {
  final String id;
  final String plateNumber;
  final String model;
  final String truckType;
  final String? color;
  final String? year;
  final double? capacity;
  final String? ownerId;

  Truck({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.truckType,
    this.color,
    this.year,
    this.capacity,
    this.ownerId,
  });

  factory Truck.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Truck(
      id: documentId,
      plateNumber: data['plateNumber'] ?? '',
      model: data['model'] ?? '',
      truckType: data['truckType'] ?? '',
      color: data['color'],
      year: data['year'],
      capacity: data['capacity']?.toDouble(),
      ownerId: data['ownerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plateNumber': plateNumber,
      'model': model,
      'truckType': truckType,
      'color': color,
      'year': year,
      'capacity': capacity,
      'ownerId': ownerId,
    };
  }
}
