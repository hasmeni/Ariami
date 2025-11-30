import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/connection_service.dart';
import '../download/download_manager.dart';

/// Playback source options
enum PlaybackSource {
  stream,      // Stream from server
  local,       // Play from downloaded file
  unavailable, // Song not available (offline and not downloaded)
}

/// Service for managing offline playback functionality
class OfflinePlaybackService {
  // Singleton pattern
  static final OfflinePlaybackService _instance = OfflinePlaybackService._internal();
  factory OfflinePlaybackService() => _instance;
  OfflinePlaybackService._internal();

  final ConnectionService _connectionService = ConnectionService();
  final DownloadManager _downloadManager = DownloadManager();

  // Offline mode state
  bool _offlineModeEnabled = false;
  bool _preferDownloaded = true;

  // Stream controller for offline state changes
  final StreamController<bool> _offlineStateController =
      StreamController<bool>.broadcast();

  /// Stream of offline state changes (true = offline mode active)
  Stream<bool> get offlineStateStream => _offlineStateController.stream;

  /// Whether offline mode is currently enabled
  bool get isOfflineModeEnabled => _offlineModeEnabled;

  /// Whether to prefer downloaded files over streaming
  bool get preferDownloaded => _preferDownloaded;

  /// Check if currently offline (either forced or no connection)
  bool get isOffline => _offlineModeEnabled || !_connectionService.isConnected;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the service and load saved settings
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _offlineModeEnabled = prefs.getBool('offline_mode_enabled') ?? false;
    _preferDownloaded = prefs.getBool('prefer_downloaded') ?? true;

    // Listen to connection state changes
    _connectionService.connectionStateStream.listen((isConnected) {
      // Notify listeners when connection state affects offline status
      _offlineStateController.add(isOffline);
    });

    print('[OfflinePlaybackService] Initialized - Offline mode: $_offlineModeEnabled');
  }

  // ============================================================================
  // OFFLINE MODE CONTROL
  // ============================================================================

  /// Enable or disable offline mode
  Future<void> setOfflineMode(bool enabled) async {
    _offlineModeEnabled = enabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode_enabled', enabled);

    _offlineStateController.add(isOffline);
    print('[OfflinePlaybackService] Offline mode: $enabled');
  }

  /// Set preference for downloaded files
  Future<void> setPreferDownloaded(bool prefer) async {
    _preferDownloaded = prefer;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('prefer_downloaded', prefer);

    print('[OfflinePlaybackService] Prefer downloaded: $prefer');
  }

  // ============================================================================
  // PLAYBACK SOURCE SELECTION
  // ============================================================================

  /// Determine the playback source for a song
  Future<PlaybackSource> getPlaybackSource(String songId) async {
    final isDownloaded = await _downloadManager.isSongDownloaded(songId);

    if (isOffline) {
      // Offline mode - can only play downloaded songs
      if (isDownloaded) {
        return PlaybackSource.local;
      } else {
        return PlaybackSource.unavailable;
      }
    } else {
      // Online mode - prefer downloaded if setting enabled
      if (isDownloaded && _preferDownloaded) {
        return PlaybackSource.local;
      } else {
        return PlaybackSource.stream;
      }
    }
  }

  /// Get local file path for a downloaded song
  String? getLocalFilePath(String songId) {
    return _downloadManager.getDownloadedSongPath(songId);
  }

  /// Check if a song is available for playback
  Future<bool> isSongAvailable(String songId) async {
    final source = await getPlaybackSource(songId);
    return source != PlaybackSource.unavailable;
  }

  /// Check if a song is downloaded
  Future<bool> isSongDownloaded(String songId) async {
    return await _downloadManager.isSongDownloaded(songId);
  }

  // ============================================================================
  // CONNECTIVITY CHECK
  // ============================================================================

  /// Check current connectivity status
  bool checkConnectivity() {
    return _connectionService.isConnected;
  }

  /// Get the connection state stream
  Stream<bool> get connectionStateStream => _connectionService.connectionStateStream;

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose resources
  void dispose() {
    _offlineStateController.close();
  }
}

