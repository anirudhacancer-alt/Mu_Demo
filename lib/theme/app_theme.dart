import 'package:flutter/material.dart';

/// Premium color palette — deep indigo/navy base with electric teal &
/// amber accents. Designed to feel modern and "aurora"-like without
/// requiring any image assets or network fonts (fully offline-safe for demos).
class AppColors {
  static const Color bgDeep = Color(0xFF0B1220);
  static const Color bgDeep2 = Color(0xFF121A2E);
  static const Color surface = Color(0xFF1A2340);
  static const Color surfaceLight = Color(0xFF232E52);
  static const Color primary = Color(0xFF6C8CFF);
  static const Color primaryDark = Color(0xFF3E5BDB);
  static const Color accentTeal = Color(0xFF2DD4BF);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentCoral = Color(0xFFFB7185);
  static const Color textPrimary = Color(0xFFF3F5FB);
  static const Color textSecondary = Color(0xFFA7B0C8);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);

  static const List<Color> aurora = [
    Color(0xFF3E5BDB),
    Color(0xFF6C8CFF),
    Color(0xFF2DD4BF),
  ];
}

Color severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'critical':
      return AppColors.danger;
    case 'high':
      return AppColors.accentCoral;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'open':
      return AppColors.info;
    case 'in progress':
      return AppColors.accentAmber;
    case 'blocked':
      return AppColors.danger;
    case 'resolved':
    case 'delivered':
    case 'confirmed':
    case 'closed':
      return AppColors.success;
    case 'delayed':
      return AppColors.accentCoral;
    case 'in transit':
      return AppColors.info;
    default:
      return AppColors.textSecondary;
  }
}

/// Priority is distinct from severity: severity = how bad the issue is;
/// priority = how urgently it should be worked, set during the
/// capture-to-task reflection step.
Color priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'urgent':
      return AppColors.danger;
    case 'high':
      return AppColors.accentCoral;
    case 'medium':
      return AppColors.warning;
    default:
      return AppColors.info; // Low
  }
}

/// Colors for the cloud-sync status badge shown on captures/tasks once
/// Firebase is wired up.
Color cloudSyncColor(String status) {
  switch (status) {
    case 'synced':
      return AppColors.success;
    case 'syncing':
      return AppColors.accentAmber;
    case 'failed':
      return AppColors.danger;
    default:
      return AppColors.textSecondary; // local
  }
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bgDeep,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      secondary: AppColors.accentTeal,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'Roboto',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgDeep2,
      selectedItemColor: AppColors.accentTeal,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surfaceLight,
      labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    ),
    dividerColor: Colors.white.withOpacity(0.08),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.accentTeal,
      foregroundColor: AppColors.bgDeep,
    ),
    useMaterial3: true,
  );
}
