import 'package:flutter/material.dart';

/// Core maritime palette shared by light & dark themes.
class AppColors {
  AppColors._();

  // Navy family — primary brand color, evokes deep offshore water.
  static const Color navy900 = Color(0xFF071426);
  static const Color navy800 = Color(0xFF0B1F3A);
  static const Color navy700 = Color(0xFF123A5E);
  static const Color navy600 = Color(0xFF1B4E7A);
  static const Color navy500 = Color(0xFF2A6796);
  static const Color navy100 = Color(0xFFE7EEF5);

  // Teal accent — buoy / wave highlight.
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);

  // Amber accent — deck-light warning / highlight.
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber600 = Color(0xFFD97706);

  // Status colors.
  static const Color statusActive = Color(0xFF22C55E);
  static const Color statusStandby = Color(0xFFFBBF24);
  static const Color statusPort = Color(0xFF60A5FA);
  static const Color statusMaintenance = Color(0xFFF87171);

  // Neutral surfaces.
  static const Color slate50 = Color(0xFFF5F8FB);
  static const Color slate100 = Color(0xFFEBF0F6);
  static const Color slate200 = Color(0xFFDCE4EE);
  static const Color slate400 = Color(0xFF8CA0B3);
  static const Color slate600 = Color(0xFF4C6079);

  static LinearGradient heroGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy900, navy700, teal600],
  );

  static LinearGradient tankFillGradient(Color color) => LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [color, color.withValues(alpha: 0.55)],
      );

  static Color statusColor(String status) {
    switch (status) {
      case 'active':
        return statusActive;
      case 'standby':
        return statusStandby;
      case 'port':
        return statusPort;
      case 'maintenance':
        return statusMaintenance;
      default:
        return statusActive;
    }
  }
}
