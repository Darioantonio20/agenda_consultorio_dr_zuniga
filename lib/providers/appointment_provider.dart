import 'package:flutter/material.dart';
import 'package:agenda_dr_zuniga/models/appointment.dart';
import 'package:agenda_dr_zuniga/services/appointment_service.dart';

class AppointmentProvider with ChangeNotifier {
  final AppointmentService _appointmentService = AppointmentService();
  List<Appointment> _appointments = [];

  List<Appointment> get appointments => _appointments;

  AppointmentProvider() {
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    _appointments = await _appointmentService.getAllAppointments();
    notifyListeners();
  }

  Future<void> addAppointment(Appointment appointment) async {
    print('AppointmentProvider: Adding appointment: ${appointment.toMap()}');
    final newId = await _appointmentService.insertAppointment(appointment);
    _appointments.add(appointment.copyWith(id: newId));
    print(
        'AppointmentProvider: Appointment added with ID: $newId. Current appointments: ${_appointments.length}');
    notifyListeners();
  }

  Future<void> updateAppointment(Appointment appointment) async {
    print(
        'AppointmentProvider: Updating appointment with ID: ${appointment.id}, Status: ${appointment.status}');
    await _appointmentService.updateAppointment(appointment);
    final index = _appointments.indexWhere((app) => app.id == appointment.id);
    if (index != -1) {
      _appointments[index] = appointment; // Update the item in the list
      print(
          'AppointmentProvider: Appointment updated. Current status: ${appointment.status}');
      notifyListeners();
    } else {
      print(
          'AppointmentProvider: Appointment with ID ${appointment.id} not found for update.');
    }
  }

  Future<void> deleteAppointment(int id) async {
    print('AppointmentProvider: Deleting appointment with ID: $id');
    await _appointmentService.deleteAppointment(id);
    _appointments.removeWhere((app) => app.id == id);
    print(
        'AppointmentProvider: Appointment deleted. Remaining appointments: ${_appointments.length}');
    notifyListeners();
  }

  List<Appointment> getAppointmentsForPatient(int patientId) {
    return _appointments
        .where((appointment) => appointment.patientId == patientId)
        .toList();
  }

  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments
        .where(
          (appointment) =>
              appointment.startTime.year == date.year &&
              appointment.startTime.month == date.month &&
              appointment.startTime.day == date.day,
        )
        .toList();
  }

  List<Appointment> getFilteredAppointments(String status) {
    return _appointments
        .where((appointment) => appointment.status == status)
        .toList();
  }
}
