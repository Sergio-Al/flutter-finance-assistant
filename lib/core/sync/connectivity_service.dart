import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

/// Service for monitoring network connectivity status.
///
/// Provides real-time connectivity updates and network type detection
/// for offline-first sync decisions.
class ConnectivityService {
  final Connectivity _connectivity;
  final Logger _logger;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _connectivityController =
      StreamController<bool>.broadcast();

  bool _isConnected = false;
  ConnectivityType _currentType = ConnectivityType.none;

  /// Creates a [ConnectivityService] with optional custom [Connectivity] instance.
  ConnectivityService({
    Connectivity? connectivity,
    Logger? logger,
  })  : _connectivity = connectivity ?? Connectivity(),
        _logger = logger ?? Logger();

  /// Stream of connectivity changes (true = connected, false = disconnected).
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Current connectivity status.
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Current connectivity type.
  ConnectivityType get currentType => _currentType;

  /// Whether currently connected to WiFi.
  bool get isWifi => _currentType == ConnectivityType.wifi;

  /// Whether currently on mobile data.
  bool get isMobile => _currentType == ConnectivityType.mobile;

  /// Initialize connectivity monitoring.
  Future<void> initialize() async {
    _logger.i('ConnectivityService: Initializing...');

    // Check initial state
    final results = await _connectivity.checkConnectivity();
    _updateState(results);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateState,
      onError: (error) {
        _logger.e('ConnectivityService: Stream error', error: error);
      },
    );

    _logger.i('ConnectivityService: Initialized - Connected: $_isConnected');
  }

  /// Dispose resources.
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
    _logger.i('ConnectivityService: Disposed');
  }

  /// Update internal state based on connectivity results.
  void _updateState(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasConnection(results);
    _currentType = _getConnectivityType(results);

    _logger.d(
      'ConnectivityService: State update - '
      'Connected: $_isConnected, Type: ${_currentType.name}',
    );

    // Only emit if state changed
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
    }
  }

  /// Check if any of the results indicate a connection.
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  /// Determine the primary connectivity type.
  ConnectivityType _getConnectivityType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityType.wifi;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityType.ethernet;
    } else if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityType.mobile;
    } else if (results.contains(ConnectivityResult.vpn)) {
      return ConnectivityType.vpn;
    }
    return ConnectivityType.none;
  }

  /// Force a connectivity check.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateState(results);
    return _isConnected;
  }
}

/// Represents the type of network connection.
enum ConnectivityType {
  /// No network connection
  none,

  /// WiFi connection
  wifi,

  /// Mobile data connection (3G/4G/5G)
  mobile,

  /// Ethernet connection
  ethernet,

  /// VPN connection
  vpn,
}
