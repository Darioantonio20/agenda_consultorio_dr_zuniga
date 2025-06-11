import 'package:agenda_dr_zuniga/models/patient.dart';
import 'package:agenda_dr_zuniga/utils/database_helper.dart';

class PatientService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertPatient(Patient patient) async {
    return await _dbHelper.insert('patients', patient.toMap());
  }

  Future<Patient?> getPatientById(int id) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'patients',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  Future<Patient?> getPatientByPhoneNumber(String phoneNumber) async {
    final List<Map<String, dynamic>> maps = await _dbHelper.query(
      'patients',
      where: 'phoneNumber = ?',
      whereArgs: [phoneNumber],
    );
    if (maps.isNotEmpty) {
      return Patient.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Patient>> getAllPatients() async {
    final List<Map<String, dynamic>> maps =
        await _dbHelper.queryAll('patients');
    return List.generate(maps.length, (i) {
      return Patient.fromMap(maps[i]);
    });
  }

  Future<int> updatePatient(Patient patient) async {
    return await _dbHelper.update(
      'patients',
      patient.toMap(),
      'id = ?',
      [patient.id],
    );
  }

  Future<int> deletePatient(int id) async {
    return await _dbHelper.delete(
      'patients',
      'id = ?',
      [id],
    );
  }
}
