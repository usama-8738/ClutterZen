import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity() {
    _init();
  }

  final Connectivity _connectivity;
  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isConnected = true;

  /// Stream of connectivity status changes
  Stream<bool> get connectivityStream {
    _connectivityController ??= StreamController<bool>.broadcast();
    return _connectivityController!.stream;
  }

  /// Current connectivity status
  bool get isConnected => _isConnected;

  Future<void> _init() async {
    // Get initial status
    final results = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(results);
    _connectivityController?.add(_isConnected);

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasConnected = _isConnected;
      _isConnected = _hasConnection(results);
      
      if (wasConnected != _isConnected) {
        _connectivityController?.add(_isConnected);
        if (kDebugMode) {
          debugPrint('Connectivity changed: ${_isConnected ? "Online" : "Offline"}');
        }
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    // Check if any result indicates connectivity
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return true;
      }
    }
    return false;
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(results);
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _connectivityController?.close();
    _connectivityController = null;
  }
}

/// Global connectivity service instance
final connectivityService = ConnectivityService();

