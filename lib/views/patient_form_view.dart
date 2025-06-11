import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:agenda_dr_zuniga/models/patient.dart';
import 'package:agenda_dr_zuniga/providers/patient_provider.dart';
import 'package:agenda_dr_zuniga/utils/constants.dart';
import 'package:agenda_dr_zuniga/utils/app_styles.dart';

class PatientFormView extends StatefulWidget {
  final Patient? patient;

  const PatientFormView({super.key, this.patient});

  @override
  State<PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends State<PatientFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _addressController;
  String? _selectedPaymentType;
  bool _willInvoice = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.patient?.fullName ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.patient?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: widget.patient?.address ?? '');
    _selectedPaymentType = widget.patient?.paymentType;
    _willInvoice = widget.patient?.willInvoice ?? false;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _savePatient() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final patient = Patient(
        id: widget.patient?.id,
        fullName: _fullNameController.text,
        phoneNumber: _phoneNumberController.text,
        paymentType: _selectedPaymentType!,
        willInvoice: _willInvoice,
        address: _addressController.text,
      );

      try {
        if (widget.patient == null) {
          await Provider.of<PatientProvider>(context, listen: false)
              .addPatient(patient);
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Éxito',
            desc: 'Paciente registrado correctamente.',
            btnOkOnPress: () {
              Navigator.pop(context);
            },
            btnOkColor: primaryColor,
          ).show();
        } else {
          await Provider.of<PatientProvider>(context, listen: false)
              .updatePatient(patient);
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            animType: AnimType.rightSlide,
            title: 'Éxito',
            desc: 'Paciente actualizado correctamente.',
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
          title: 'Error',
          desc: e.toString().replaceFirst('Exception: ', ''),
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
        ).show();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.patient == null ? 'Registrar Paciente' : 'Editar Paciente',
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
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre completo.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: lightBackgroundColor,
                ),
                keyboardType: TextInputType.phone,
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
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentType = value;
                  });
                },
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
                  onChanged: (value) {
                    setState(() {
                      _willInvoice = value;
                    });
                  },
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el domicilio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.patient == null
                      ? 'Guardar Paciente'
                      : 'Actualizar Paciente',
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
