import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:agenda_dr_zuniga/providers/appointment_provider.dart';
import 'package:agenda_dr_zuniga/providers/patient_provider.dart';
import 'package:agenda_dr_zuniga/views/home_view.dart';
import 'package:agenda_dr_zuniga/utils/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_ES';
  await DatabaseHelper().init(); // Initialize the database
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: MaterialApp(
        title: 'Agenda Dr. Zuñiga',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'ES'),
        ],
        home: const HomeView(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
