import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  static const String _compileTimeApiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://preemotional-ungainly-maryann.ngrok-free.dev',
  );

  /// Resolved API base URL. Call [init] before using.
  static late String apiBaseUrl;

  /// Initialize config: prefer compile-time value; if it appears to be
  /// the default/failing value, try to load `.env` asset and read
  /// `API_BASE_URL=` from it. Falls back to the compile-time value.
  static Future<void> init() async {
    apiBaseUrl = _compileTimeApiBase;

    // If compile-time value looks like the placeholder/ngrok default,
    // attempt to read `.env` from assets as a runtime override.
    try {
      if (apiBaseUrl.isEmpty || apiBaseUrl.contains('ngrok-free.dev')) {
        final envText = await rootBundle.loadString('.env');
        for (final rawLine in envText.split(RegExp(r"\r?\n"))) {
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('#')) continue;
          final idx = line.indexOf('=');
          if (idx <= 0) continue;
          final key = line.substring(0, idx).trim();
          final val = line.substring(idx + 1).trim();
          if (key == 'API_BASE_URL' && val.isNotEmpty) {
            apiBaseUrl = val;
            break;
          }
        }
      }
    } catch (_) {
      // Ignore errors reading .env and keep compile-time value.
    }
  }
}
