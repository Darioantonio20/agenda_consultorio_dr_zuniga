class Patient {
  int? id;
  String fullName;
  String phoneNumber;
  String paymentType;
  bool willInvoice;
  String address;

  Patient({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.paymentType,
    required this.willInvoice,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'paymentType': paymentType,
      'willInvoice': willInvoice ? 1 : 0,
      'address': address,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      fullName: map['fullName'],
      phoneNumber: map['phoneNumber'],
      paymentType: map['paymentType'],
      willInvoice: map['willInvoice'] == 1,
      address: map['address'],
    );
  }

  Patient copyWith({
    int? id,
    String? fullName,
    String? phoneNumber,
    String? paymentType,
    bool? willInvoice,
    String? address,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paymentType: paymentType ?? this.paymentType,
      willInvoice: willInvoice ?? this.willInvoice,
      address: address ?? this.address,
    );
  }
}
