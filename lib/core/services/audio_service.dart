import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../utils/logger.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;
    _isInitialized = true;

    // Set audio player mode
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);

    AppLogger.info('AudioService initialized');
  }

  bool get isSoundEnabled {
    if (!_isInitialized) return true;
    return _prefs.getBool(StorageKeys.soundEnabled) ?? true;
  }

  Future<void> playSuccessSound() async {
    if (!isSoundEnabled) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/scan_successful.wav'));
      AppLogger.info('Playing success sound');
    } catch (e, stackTrace) {
      AppLogger.error('Error playing success sound', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> playInvalidSound() async {
    if (!isSoundEnabled) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/scan_invalid.wav'));
      AppLogger.info('Playing invalid sound');
    } catch (e, stackTrace) {
      AppLogger.error('Error playing invalid sound', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}
