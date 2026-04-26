import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._();
  ConnectivityService._();

  final _connectivity = Connectivity();

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Emits true when online, false when offline.
  Stream<bool> get onConnectivityChanged => _connectivity
      .onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
}
