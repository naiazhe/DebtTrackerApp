class Borrower {
  final int? borrowerId;
  final int userId;
  final String firstName;
  final String lastName;
  final String contactNumber;
  final String address;
  final String referenceName;
  final String referenceContact;
  final String referenceRelationship;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Borrower({
    this.borrowerId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.contactNumber,
    required this.address,
    required this.referenceName,
    required this.referenceContact,
    required this.referenceRelationship,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'borrower_id': borrowerId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'contact_number': contactNumber,
      'address': address,
      'reference_name': referenceName,
      'reference_contact': referenceContact,
      'reference_relationship': referenceRelationship,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Borrower.fromMap(Map<String, dynamic> map) {
    return Borrower(
      borrowerId: map['borrower_id'] as int?,
      userId: map['user_id'] as int,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      contactNumber: map['contact_number'] as String,
      address: map['address'] as String,
      referenceName: (map['reference_name'] as String?) ?? '',
      referenceContact: map['reference_contact'] as String,
      referenceRelationship: (map['reference_relationship'] as String?) ?? '',
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
