class Appointment {
  int? id;
  int patientId;
  DateTime startTime;
  DateTime endTime;
  bool isFirstAppointment;
  String status;

  Appointment({
    this.id,
    required this.patientId,
    required this.startTime,
    required this.endTime,
    required this.isFirstAppointment,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isFirstAppointment': isFirstAppointment ? 1 : 0,
      'status': status,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      patientId: map['patientId'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      isFirstAppointment: map['isFirstAppointment'] == 1,
      status: map['status'],
    );
  }

  Appointment copyWith({
    int? id,
    int? patientId,
    DateTime? startTime,
    DateTime? endTime,
    bool? isFirstAppointment,
    String? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isFirstAppointment: isFirstAppointment ?? this.isFirstAppointment,
      status: status ?? this.status,
    );
  }
}
