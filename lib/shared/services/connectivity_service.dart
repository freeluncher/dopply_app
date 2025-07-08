import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service untuk mengelola koneksi dan offline support
class ConnectivityService {
  final Connectivity _connectivity;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  bool _hasInternetAccess = true;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _initializeConnectivity();
  }

  /// Stream untuk mendengarkan perubahan koneksi
  Stream<bool> get connectionStream => _connectionStateController.stream;

  /// Status koneksi saat ini
  bool get isConnected => _isConnected && _hasInternetAccess;

  /// Inisialisasi monitoring koneksi
  Future<void> _initializeConnectivity() async {
    try {
      // Cek koneksi awal
      await _checkConnectivity();

      // Listen untuk perubahan koneksi
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
        List<ConnectivityResult> results,
      ) async {
        await _checkConnectivity();
      });
    } catch (e) {
      print('[CONNECTIVITY] Error initializing connectivity: $e');
    }
  }

  /// Cek status koneksi dan internet access
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      // Cek apakah ada koneksi network
      _isConnected =
          connectivityResults.isNotEmpty &&
          !connectivityResults.contains(ConnectivityResult.none);

      if (_isConnected) {
        // Cek akses internet dengan ping ke server
        _hasInternetAccess = await _checkInternetAccess();
      } else {
        _hasInternetAccess = false;
      }

      // Notify listeners
      _connectionStateController.add(isConnected);

      print(
        '[CONNECTIVITY] Connection status: connected=$_isConnected, internet=$_hasInternetAccess',
      );
    } catch (e) {
      print('[CONNECTIVITY] Error checking connectivity: $e');
      _isConnected = false;
      _hasInternetAccess = false;
      _connectionStateController.add(false);
    }
  }

  /// Cek akses internet dengan ping ke server
  Future<bool> _checkInternetAccess() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      print('[CONNECTIVITY] Error checking internet access: $e');
      return false;
    }
  }

  /// Cleanup resources
  void dispose() {
    _connectivitySubscription.cancel();
    _connectionStateController.close();
  }
}
