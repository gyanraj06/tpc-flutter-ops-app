import 'dart:developer' as developer;

class AppLogger {
  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? 'TPC_DEBUG',
      level: 500,
    );
  }

  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? 'TPC_INFO',
      level: 800,
    );
  }

  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: tag ?? 'TPC_WARNING',
      level: 900,
    );
  }

  static void error(String message, {Object? error, StackTrace? stackTrace, String? tag}) {
    developer.log(
      message,
      name: tag ?? 'TPC_ERROR',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
