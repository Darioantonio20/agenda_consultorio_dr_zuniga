import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:agenda_dr_zuniga/models/appointment.dart';
import 'package:agenda_dr_zuniga/models/patient.dart';
import 'package:agenda_dr_zuniga/providers/appointment_provider.dart';
import 'package:agenda_dr_zuniga/providers/patient_provider.dart';
import 'package:agenda_dr_zuniga/utils/constants.dart';
import 'package:agenda_dr_zuniga/utils/app_styles.dart';
import 'package:agenda_dr_zuniga/utils/date_utils.dart';

class AppointmentFormView extends StatefulWidget {
  final Appointment? appointment;
  final Patient? patient;
  final DateTime? selectedDate;

  const AppointmentFormView(
      {super.key, this.appointment, this.patient, this.selectedDate});

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _patientSearchController;
  late TextEditingController _patientNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  String? _selectedPaymentType;
  bool _willInvoice = false;
  late DateTime _selectedStartTime;
  late DateTime _selectedEndTime;
  String? _selectedStatus;
  bool _isFirstAppointment = false;
  Patient? _selectedPatient;
  List<Patient> _patientSearchResults = [];
  bool _canEditPatientDetails = false;

  @override
  void initState() {
    super.initState();
    _selectedStartTime =
        widget.appointment?.startTime ?? widget.selectedDate ?? DateTime.now();
    _selectedEndTime = widget.appointment?.endTime ??
        (widget.selectedDate ?? DateTime.now()).add(const Duration(hours: 1));
    _selectedStatus = widget.appointment?.status ?? 'pendiente';
    _isFirstAppointment = widget.appointment?.isFirstAppointment ?? false;
    _selectedPatient = widget.patient;

    _patientSearchController = TextEditingController();
    _patientNameController =
        TextEditingController(text: widget.patient?.fullName ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.patient?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: widget.patient?.address ?? '');
    _selectedPaymentType = widget.patient?.paymentType;
    _willInvoice = widget.patient?.willInvoice ?? false;

    _canEditPatientDetails = widget.patient == null;

    if (widget.appointment != null && widget.patient != null) {
      _patientSearchController.text = widget.patient!.fullName;
    }
  }

  @override
  void dispose() {
    _patientSearchController.dispose();
    _patientNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: secondaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedStartTime) {
      setState(() {
        _selectedStartTime = DateTime(picked.year, picked.month, picked.day,
            _selectedStartTime.hour, _selectedStartTime.minute);
        _selectedEndTime = DateTime(picked.year, picked.month, picked.day,
            _selectedEndTime.hour, _selectedEndTime.minute);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          isStartTime ? _selectedStartTime : _selectedEndTime),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: secondaryColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = DateTime(
              _selectedStartTime.year,
              _selectedStartTime.month,
              _selectedStartTime.day,
              picked.hour,
              picked.minute);
          _selectedEndTime = _selectedStartTime
              .add(const Duration(hours: 1)); // Default 1 hour duration
        } else {
          _selectedEndTime = DateTime(
              _selectedEndTime.year,
              _selectedEndTime.month,
              _selectedEndTime.day,
              picked.hour,
              picked.minute);
        }
      });
    }
  }

  void _searchPatients(String query) {
    final patientProvider =
        Provider.of<PatientProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _patientSearchResults = [];
      } else {
        _patientSearchResults = patientProvider.patients
            .where((patient) =>
                patient.fullName.toLowerCase().contains(query.toLowerCase()) ||
                patient.phoneNumber.contains(query))
            .toList();
      }
    });
  }

  void _selectExistingPatient(Patient patient) async {
    setState(() {
      _selectedPatient = patient;
      _patientNameController.text = patient.fullName;
      _phoneNumberController.text = patient.phoneNumber;
      _addressController.text = patient.address;
      _selectedPaymentType = patient.paymentType;
      _willInvoice = patient.willInvoice;
      _patientSearchController.text =
          patient.fullName; // Update search bar with selected patient's name
      _patientSearchResults = []; // Clear search results
      _canEditPatientDetails = false; // Lock fields after selection
    });

    final appointmentProvider =
        Provider.of<AppointmentProvider>(context, listen: false);
    final patientAppointments = await appointmentProvider
        .getAppointmentsForPatient(_selectedPatient!.id!);
    setState(() {
      _isFirstAppointment = patientAppointments.isEmpty;
    });
  }

  void _saveAppointment() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedStartTime.isAfter(_selectedEndTime)) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Error de Hora',
          desc: 'La hora de inicio no puede ser posterior a la hora de fin.',
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
        ).show();
        return;
      }

      if (_selectedPatient == null && _patientNameController.text.isEmpty) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Error',
          desc: 'Por favor, selecciona un paciente o registra uno nuevo.',
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
        ).show();
        return;
      }

      final patientProvider =
          Provider.of<PatientProvider>(context, listen: false);
      // Handle patient creation/update if details were entered/modified
      if (_selectedPatient == null) {
        // Creating a brand new patient and linking to this appointment
        final newPatient = Patient(
          fullName: _patientNameController.text,
          phoneNumber: _phoneNumberController.text,
          paymentType: _selectedPaymentType!,
          willInvoice: _willInvoice,
          address: _addressController.text,
        );
        await patientProvider.addPatient(newPatient);
        _selectedPatient = newPatient;
      } else if (_canEditPatientDetails &&
          (_selectedPatient!.fullName != _patientNameController.text ||
              _selectedPatient!.phoneNumber != _phoneNumberController.text ||
              _selectedPatient!.paymentType != _selectedPaymentType ||
              _selectedPatient!.willInvoice != _willInvoice ||
              _selectedPatient!.address != _addressController.text)) {
        // Updating existing patient details
        final updatedPatient = _selectedPatient!.copyWith(
          fullName: _patientNameController.text,
          phoneNumber: _phoneNumberController.text,
          paymentType: _selectedPaymentType!,
          willInvoice: _willInvoice,
          address: _addressController.text,
        );
        await patientProvider.updatePatient(updatedPatient);
        _selectedPatient = updatedPatient;
      }

      // Check if existing patient can book appointment based on missed appointments
      final appointmentProvider =
          Provider.of<AppointmentProvider>(context, listen: false);
      final patientAppointments = await appointmentProvider
          .getAppointmentsForPatient(_selectedPatient!.id!);
      final hasMissedAppointment =
          patientAppointments.any((app) => app.status == 'no asistio');

      if (hasMissedAppointment && widget.appointment == null) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          animType: AnimType.rightSlide,
          title: 'Cita No Asistida Previa',
          desc:
              'Este paciente tiene una cita previa a la que no asistió. No puede agendar nuevas citas.',
          btnOkOnPress: () {},
          btnOkColor: Colors.orange,
        ).show();
        return;
      }

      final appointment = Appointment(
        id: widget.appointment?.id,
        patientId: _selectedPatient!.id!,
        startTime: _selectedStartTime,
        endTime: _selectedEndTime,
        isFirstAppointment: _isFirstAppointment,
        status: _selectedStatus!,
      );

      try {
        if (widget.appointment == null) {
          await appointmentProvider.addAppointment(appointment);
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Éxito',
            desc: 'Cita creada correctamente.',
            btnOkOnPress: () {
              Navigator.pop(context);
            },
            btnOkColor: primaryColor,
          ).show();
        } else {
          await appointmentProvider.updateAppointment(appointment);
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Éxito',
            desc: 'Cita actualizada correctamente.',
            btnOkOnPress: () {
              Navigator.pop(context);
            },
            btnOkColor: primaryColor,
          ).show();
        }
      } catch (e) {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.error,
          animType: AnimType.rightSlide,
          title: 'Error al Guardar Cita',
          desc: e.toString(),
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = Provider.of<PatientProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? 'Crear Cita' : 'Editar Cita',
            style: AppStyles.appBarTitle),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _patientSearchController,
                decoration: InputDecoration(
                  labelText: 'Buscar paciente por nombre o teléfono',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                  suffixIcon: _patientSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _patientSearchController.clear();
                            setState(() {
                              _patientSearchResults = [];
                              _selectedPatient = null;
                              _patientNameController.clear();
                              _phoneNumberController.clear();
                              _addressController.clear();
                              _selectedPaymentType = null;
                              _willInvoice = false;
                              _canEditPatientDetails =
                                  true; // Allow editing when clearing search
                            });
                          },
                        )
                      : null,
                ),
                onChanged: _searchPatients,
              ),
              if (_patientSearchResults.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListView.builder(
                    itemCount: _patientSearchResults.length,
                    itemBuilder: (context, index) {
                      final patient = _patientSearchResults[index];
                      return ListTile(
                        title: Text(patient.fullName),
                        subtitle: Text(patient.phoneNumber),
                        onTap: () => _selectExistingPatient(patient),
                      );
                    },
                  ),
                ),
              if (_selectedPatient != null && !_canEditPatientDetails)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _canEditPatientDetails = true;
                        });
                      },
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('Editar detalles del paciente',
                          style: AppStyles.buttonTextStyle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _patientNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo del Paciente',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                readOnly: !_canEditPatientDetails, // Conditionally read-only
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre del paciente.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono del Paciente',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                keyboardType: TextInputType.phone,
                readOnly: !_canEditPatientDetails, // Conditionally read-only
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el número de teléfono.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentType,
                decoration: InputDecoration(
                  labelText: 'Tipo de Pago',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'transferencia', child: Text('Transferencia')),
                  DropdownMenuItem(
                      value: 'en efectivo', child: Text('En Efectivo')),
                ],
                onChanged: _canEditPatientDetails
                    ? (value) {
                        setState(() {
                          _selectedPaymentType = value;
                        });
                      }
                    : null, // Conditionally enabled
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un tipo de pago.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('¿Requiere Factura?'),
                trailing: Switch(
                  value: _willInvoice,
                  onChanged: _canEditPatientDetails
                      ? (value) {
                          setState(() {
                            _willInvoice = value;
                          });
                        }
                      : null, // Conditionally enabled
                  activeColor: primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Domicilio',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                readOnly: !_canEditPatientDetails, // Conditionally read-only
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el domicilio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedPatient != null && _isFirstAppointment)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    '¡Este es la primera cita del paciente!',
                    style: AppStyles.bodyText1.copyWith(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              Text(
                'Fecha y Hora de la Cita',
                style: AppStyles.heading2,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                    'Fecha: ${AppDateUtils.formatDate(_selectedStartTime)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              ListTile(
                title: Text(
                    'Hora de Inicio: ${AppDateUtils.formatTime(_selectedStartTime)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, true),
              ),
              ListTile(
                title: Text(
                    'Hora de Fin: ${AppDateUtils.formatTime(_selectedEndTime)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _selectTime(context, false),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: InputDecoration(
                  labelText: 'Estado de la Cita',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'pendiente', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'asistio', child: Text('Asistió')),
                  DropdownMenuItem(
                      value: 'no asistio', child: Text('No Asistió')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona un estado.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('¿Es Primera Cita?'),
                trailing: Switch(
                  value: _isFirstAppointment,
                  onChanged: (value) {
                    setState(() {
                      _isFirstAppointment = value;
                    });
                  },
                  activeColor: primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.appointment == null
                      ? 'Guardar Cita'
                      : 'Actualizar Cita',
                  style: AppStyles.buttonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
