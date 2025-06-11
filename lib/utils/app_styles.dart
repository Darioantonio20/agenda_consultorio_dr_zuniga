import 'package:flutter/material.dart';
import 'package:agenda_dr_zuniga/utils/constants.dart';

class AppStyles {
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle heading1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: secondaryColor,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryColor,
  );

  static const TextStyle bodyText1 = TextStyle(
    fontSize: 16,
    color: Colors.black87,
  );

  static const TextStyle bodyText2 = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 14,
    color: Colors.black54,
  );

  static const TextStyle statusPending = TextStyle(
    color: pendingAppointmentColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statusAttended = TextStyle(
    color: attendedAppointmentColor,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle statusMissed = TextStyle(
    color: missedAppointmentColor,
    fontWeight: FontWeight.bold,
  );
}
