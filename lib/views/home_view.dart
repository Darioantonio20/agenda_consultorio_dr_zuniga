import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sfcalendar;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:agenda_dr_zuniga/models/appointment.dart';
import 'package:agenda_dr_zuniga/models/patient.dart';
import 'package:agenda_dr_zuniga/providers/appointment_provider.dart';
import 'package:agenda_dr_zuniga/providers/patient_provider.dart';
import 'package:agenda_dr_zuniga/utils/constants.dart';
import 'package:agenda_dr_zuniga/utils/app_styles.dart';
import 'package:agenda_dr_zuniga/utils/date_utils.dart';
import 'package:agenda_dr_zuniga/views/appointment_form_view.dart';
import 'package:agenda_dr_zuniga/views/patient_form_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _use24HourFormat = true;
  sfcalendar.CalendarController _calendarController =
      sfcalendar.CalendarController();

  @override
  void initState() {
    super.initState();
    _calendarController.view = sfcalendar.CalendarView.month;
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  Color _getAppointmentColor(Appointment appointment) {
    if (appointment.status == 'no asistio') {
      return missedAppointmentColor;
    } else if (appointment.status == 'asistio') {
      return attendedAppointmentColor;
    } else if (appointment.status == 'pendiente') {
      return pendingAppointmentColor;
    } else if (appointment.isFirstAppointment) {
      return patientFirstAppointmentColor;
    } else {
      return patientSubsequentAppointmentColor;
    }
  }

  AwesomeDialog _showPatientDetailsDialog(Patient patient) {
    return AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.rightSlide,
      headerAnimationLoop: false,
      title: 'Detalles del Paciente',
      desc: '''Nombre: ${patient.fullName}
Teléfono: ${patient.phoneNumber}
Tipo de Pago: ${patient.paymentType}
Facturar: ${patient.willInvoice ? 'Sí' : 'No'}
Domicilio: ${patient.address}''',
      btnOkOnPress: () async {
        Navigator.pop(context);
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PatientFormView(patient: patient)),
        );
      },
      btnOkText: 'Editar',
      btnOkColor: Colors.blue,
      btnCancelOnPress: () {},
      btnCancelText: 'Cerrar',
      btnCancelColor: primaryColor,
    );
  }

  Future<bool?> _showDeleteConfirmationDialog(
      BuildContext dialogContext, Appointment appointment) async {
    return await AwesomeDialog(
      context: dialogContext, // Use the provided stable context
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'Eliminar Cita',
      desc: '¿Estás seguro de que quieres eliminar esta cita?',
      btnCancelOnPress: () {
        Navigator.of(dialogContext)
            .pop(false); // Explicitly pop and return false
      },
      btnOkOnPress: () {
        Navigator.of(dialogContext).pop(true); // Explicitly pop and return true
      },
      btnOkColor: Colors.red,
      btnCancelColor: primaryColor,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda Dr. Zuñiga', style: AppStyles.appBarTitle),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientFormView()),
              );
            },
            tooltip: 'Registrar Paciente',
          ),
        ],
      ),
      body: Consumer<AppointmentProvider>(
        builder: (context, appointmentProvider, child) {
          final appointments = appointmentProvider.appointments;
          return sfcalendar.SfCalendar(
            view: _calendarController.view ?? sfcalendar.CalendarView.month,
            initialDisplayDate: DateTime.now(),
            dataSource: _getCalendarDataSource(appointments),
            monthViewSettings: const sfcalendar.MonthViewSettings(
              appointmentDisplayMode:
                  sfcalendar.MonthAppointmentDisplayMode.appointment,
              showAgenda: true,
            ),
            timeSlotViewSettings: sfcalendar.TimeSlotViewSettings(
              startHour: 0,
              endHour: 24,
              timeFormat: _use24HourFormat ? 'HH:mm' : 'hh:mm a',
            ),
            onTap: (sfcalendar.CalendarTapDetails details) async {
              if (details.targetElement ==
                  sfcalendar.CalendarElement.calendarCell) {
                final DateTime selectedDate = details.date!;
                showModalBottomSheet(
                  context: context,
                  builder: (modalSheetContext) {
                    return Consumer<AppointmentProvider>(
                      builder: (consumerContext, appointmentProvider, child) {
                        final appointmentsForDay = appointmentProvider
                            .getAppointmentsForDate(selectedDate);
                        return Container(
                          height: MediaQuery.of(modalSheetContext).size.height *
                              0.5,
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Citas para ${AppDateUtils.formatDate(selectedDate)}',
                                style: AppStyles.heading1,
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                child: appointmentsForDay.isEmpty
                                    ? Center(
                                        child: Text(
                                          'No hay citas para este día.',
                                          style: AppStyles.bodyText1,
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: appointmentsForDay.length,
                                        itemBuilder: (listViewContext, index) {
                                          final appointment =
                                              appointmentsForDay[index];
                                          final patient =
                                              Provider.of<PatientProvider>(
                                                      consumerContext,
                                                      listen: false)
                                                  .getPatientById(
                                                      appointment.patientId);
                                          return Slidable(
                                            key: ValueKey(appointment.id),
                                            endActionPane: ActionPane(
                                              motion: const ScrollMotion(),
                                              children: [
                                                SlidableAction(
                                                  onPressed:
                                                      (slidableActionContext) async {
                                                    await Navigator.push(
                                                      slidableActionContext,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (newRouteContext) =>
                                                                AppointmentFormView(
                                                          appointment:
                                                              appointment,
                                                          patient: patient,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  backgroundColor: Colors.blue,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.edit,
                                                  label: 'Editar',
                                                ),
                                                SlidableAction(
                                                  onPressed:
                                                      (slidableActionContext) async {
                                                    // 1. Close the bottom sheet FIRST.
                                                    if (modalSheetContext
                                                        .mounted) {
                                                      Navigator.of(
                                                              modalSheetContext)
                                                          .pop();
                                                    }

                                                    // 2. Then delete the appointment
                                                    await appointmentProvider
                                                        .deleteAppointment(
                                                            appointment.id!);

                                                    // 3. Show the snackbar using HomeView's context
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Cita eliminada correctamente')),
                                                      );
                                                    }
                                                  },
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                  icon: Icons.delete,
                                                  label: 'Eliminar',
                                                ),
                                              ],
                                            ),
                                            child: Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              elevation: 2,
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor:
                                                      _getAppointmentColor(
                                                          appointment),
                                                  child: Text(
                                                    patient?.fullName[0] ?? '?',
                                                    style: const TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                                title: Text(
                                                  '${patient?.fullName ?? 'Paciente desconocido'}',
                                                  style: AppStyles.cardTitle,
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${AppDateUtils.formatTime(appointment.startTime, use24HourFormat: _use24HourFormat)} - ${AppDateUtils.formatTime(appointment.endTime, use24HourFormat: _use24HourFormat)}',
                                                      style: AppStyles
                                                          .cardSubtitle,
                                                    ),
                                                    Text(
                                                      'Estado: ${appointment.status}',
                                                      style:
                                                          _getStatusTextStyle(
                                                              appointment
                                                                  .status),
                                                    ),
                                                    if (appointment
                                                        .isFirstAppointment)
                                                      Text(
                                                        'Primera Cita',
                                                        style: AppStyles
                                                            .bodyText2
                                                            .copyWith(
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic),
                                                      ),
                                                  ],
                                                ),
                                                onTap: () {
                                                  if (patient != null) {
                                                    _showPatientDetailsDialog(
                                                            patient)
                                                        .show();
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      modalSheetContext,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AppointmentFormView(
                                          selectedDate: selectedDate,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add_circle_outline,
                                      color: Colors.white),
                                  label: const Text('Agregar Cita',
                                      style: AppStyles.buttonTextStyle),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              } else if (details.targetElement ==
                  sfcalendar.CalendarElement.appointment) {
                final Appointment appointment =
                    details.appointments![0] as Appointment;
                final patient =
                    Provider.of<PatientProvider>(context, listen: false)
                        .getPatientById(appointment.patientId);
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.info,
                  animType: AnimType.rightSlide,
                  headerAnimationLoop: false,
                  title: 'Detalles de la Cita',
                  desc: '''Paciente: ${patient?.fullName ?? 'Desconocido'}
Fecha: ${AppDateUtils.formatDate(appointment.startTime)}
Hora: ${AppDateUtils.formatTime(appointment.startTime, use24HourFormat: _use24HourFormat)} - ${AppDateUtils.formatTime(appointment.endTime, use24HourFormat: _use24HourFormat)}
Estado: ${appointment.status}
Tipo: ${appointment.isFirstAppointment ? 'Primera Cita' : 'Cita Subsecuente'}''',
                  btnOkOnPress: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentFormView(
                          appointment: appointment,
                          patient: patient,
                        ),
                      ),
                    );
                    Navigator.pop(
                        context); // Close the AwesomeDialog after editing appointment
                  },
                  btnOkText: 'Editar Cita',
                  btnCancelOnPress: () {},
                  btnCancelText: 'Cerrar',
                  btnOkColor: primaryColor,
                  btnCancelColor: secondaryColor,
                ).show();
              }
            },
            onDragEnd: (sfcalendar.AppointmentDragEndDetails details) async {
              final Appointment draggedAppointment =
                  details.appointment as Appointment;
              final DateTime newStartTime = details.droppingTime!;
              final DateTime newEndTime = newStartTime.add(
                draggedAppointment.endTime
                    .difference(draggedAppointment.startTime),
              );

              final updatedAppointment = Appointment(
                id: draggedAppointment.id,
                patientId: draggedAppointment.patientId,
                startTime: newStartTime,
                endTime: newEndTime,
                isFirstAppointment: draggedAppointment.isFirstAppointment,
                status: draggedAppointment.status,
              );
              await appointmentProvider.updateAppointment(updatedAppointment);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cita reagendada correctamente')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AppointmentFormView()),
          );
        },
        label: const Text('Agendar Cita', style: AppStyles.buttonTextStyle),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  _AppointmentDataSource _getCalendarDataSource(
      List<Appointment> appointments) {
    List<sfcalendar.Appointment> calendarAppointments = [];
    for (var app in appointments) {
      calendarAppointments.add(sfcalendar.Appointment(
        startTime: app.startTime,
        endTime: app.endTime,
        subject: 'Cita con Paciente ID: ${app.patientId}',
        color: _getAppointmentColor(app),
        isAllDay: false,
      ));
    }
    return _AppointmentDataSource(calendarAppointments, _getAppointmentColor);
  }

  TextStyle _getStatusTextStyle(String status) {
    switch (status) {
      case 'pendiente':
        return AppStyles.statusPending;
      case 'asistio':
        return AppStyles.statusAttended;
      case 'no asistio':
        return AppStyles.statusMissed;
      default:
        return AppStyles.bodyText1;
    }
  }
}

class _AppointmentDataSource extends sfcalendar.CalendarDataSource {
  final Function(Appointment) _getAppointmentColor;

  _AppointmentDataSource(
      List<sfcalendar.Appointment> source, this._getAppointmentColor) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getAppointmentData(index).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return _getAppointmentData(index).endTime;
  }

  @override
  String getSubject(int index) {
    return _getAppointmentData(index).subject;
  }

  @override
  Color getColor(int index) {
    return _getAppointmentColor(_getAppointmentData(index) as Appointment);
  }

  @override
  bool isAllDay(int index) {
    return false;
  }

  sfcalendar.Appointment _getAppointmentData(int index) {
    return appointments![index] as sfcalendar.Appointment;
  }
}
