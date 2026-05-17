import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

enum BuildMode {
  dev,
  stage,
  prod,
}

class Env {
  static BuildMode? _buildMode;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      print('🔵 Env: .env file loaded successfully');
    } catch (e) {
      print('🔵 Env: .env file not found or could not be loaded: $e');
      print('🔵 Env: Using default values');
    }
    _buildMode = _getBuildModeFromString(dotenv.env['BUILD_MODE'] ?? 'dev');
    print('🔵 Env: Build mode set to: $_buildMode');
    print('🔵 Env: isDevelopment: $isDevelopment');
    print('🔵 Env: Base URL: $baseUrl');
    print('🔵 Env: Full Base URL: $fullBaseUrl');
  }

  static BuildMode _getBuildModeFromString(String mode) {
    switch (mode.toLowerCase()) {
      case 'dev':
        return BuildMode.dev;
      case 'stage':
        return BuildMode.stage;
      case 'prod':
        return BuildMode.prod;
      default:
        return BuildMode.dev;
    }
  }

  static BuildMode get buildMode => _buildMode ?? BuildMode.dev;

  static String get baseUrlDev {
    return dotenv.env['BASE_URL_DEV'] ?? 'https://api-dev.gyaanbuddy.com';
  }

  static String get baseUrlStage {
    return dotenv.env['BASE_URL_STAGE'] ?? 'https://api-stage.gyaanbuddy.com';
  }

  static String get baseUrlProd {
    return dotenv.env['BASE_URL_PROD'] ?? 'https://api.gyaanbuddy.com';
  }

  static String get baseUrl {
    switch (buildMode) {
      case BuildMode.dev:
        return baseUrlDev;
      case BuildMode.stage:
        return baseUrlStage;
      case BuildMode.prod:
        return baseUrlProd;
    }
  }

  static String get apiVersion => dotenv.env['API_VERSION'] ?? '/v1';

  static String get fullBaseUrl => '$baseUrl/api';

  static bool get isDevelopment => buildMode == BuildMode.dev;
  static bool get isStaging => buildMode == BuildMode.stage;
  static bool get isProduction => buildMode == BuildMode.prod;
  static bool get enableNetworkLogging =>
      (dotenv.env['ENABLE_NETWORK_LOGGING'] ?? '').toLowerCase() == 'true';

  // Timeout configurations
  static int get connectTimeout =>
      int.tryParse(dotenv.env['CONNECT_TIMEOUT'] ?? '30') ?? 30;
  static int get receiveTimeout =>
      int.tryParse(dotenv.env['RECEIVE_TIMEOUT'] ?? '30') ?? 30;
  static int get sendTimeout =>
      int.tryParse(dotenv.env['SEND_TIMEOUT'] ?? '30') ?? 30;
}
