import 'package:flutter/material.dart';

/// Application configuration constants
class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'Adyela Patient';
  static const String appVersion = '0.1.0';
  static const String appBuildNumber = '1';

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const String apiPrefix = '/api/v1';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Localization
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('es', 'ES'),
  ];
  static const Locale defaultLocale = Locale('es', 'ES');

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Hive Boxes
  static const String authBoxName = 'auth';
  static const String userBoxName = 'user';
  static const String settingsBoxName = 'settings';
  static const String cacheBoxName = 'cache';

  // Features
  static const bool enableBiometrics = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration imageCacheExpiration = Duration(days: 7);

  // Appointment
  static const int minAdvanceBookingHours = 2;
  static const int maxAdvanceBookingDays = 90;
  static const Duration appointmentDuration = Duration(minutes: 30);

  // Video Call
  static const String jitsiServerUrl = String.fromEnvironment(
    'JITSI_SERVER_URL',
    defaultValue: 'https://meet.jit.si',
  );
}
