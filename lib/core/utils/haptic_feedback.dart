import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AppHapticFeedback {
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error() async {
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(duration: 500);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> warning() async {
    if (await Vibration.hasVibrator() ?? false) {
      await Vibration.vibrate(pattern: [0, 50, 50, 50]);
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
}
