import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/connectivity/connectivity_service.dart';

/// Emits the current online status and updates on every connectivity change.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  yield await ConnectivityService.instance.isOnline();
  yield* ConnectivityService.instance.onConnectivityChanged;
});
