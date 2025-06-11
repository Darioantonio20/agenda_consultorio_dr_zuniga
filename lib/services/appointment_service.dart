import 'package:agenda_dr_zuniga/models/appointment.dart';
import 'package:agenda_dr_zuniga/utils/database_helper.dart';

class AppointmentService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertAppointment(Appointment appointment) async {
    return await _dbHelper.insert('appointments', appointment.toMap());
  }

  Future<Appointment?> getAppointmentById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'appointments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Appointment.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Appointment>> getAllAppointments() async {
    final List<Map<String, dynamic>> maps =
        await _dbHelper.queryAll('appointments');
    return List.generate(maps.length, (i) {
      return Appointment.fromMap(maps[i]);
    });
  }

  Future<List<Appointment>> getAppointmentsForPatient(int patientId) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'appointments',
      where: 'patientId = ?',
      whereArgs: [patientId],
      orderBy: 'startTime ASC',
    );
    return List.generate(maps.length, (i) {
      return Appointment.fromMap(maps[i]);
    });
  }

  Future<int> updateAppointment(Appointment appointment) async {
    return await _dbHelper.update(
      'appointments',
      appointment.toMap(),
      'id = ?',
      [appointment.id],
    );
  }

  Future<int> deleteAppointment(int id) async {
    return await _dbHelper.delete(
      'appointments',
      'id = ?',
      [id],
    );
  }
}
