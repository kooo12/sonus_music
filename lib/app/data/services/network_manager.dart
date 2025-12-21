import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

enum NetworkStatus { connected, connecting, disconnected }

class NetworkManager extends GetxService {
  Rx<NetworkStatus> networkStatus = NetworkStatus.disconnected.obs;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  RxBool showConnectedBanner = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _subscription =
        _connectivity.onConnectivityChanged.listen(_updateNetworkStatus);
    await _initializeNetworkStatus();
  }

  Future<void> _initializeNetworkStatus() async {
    final initialStatus = await _connectivity.checkConnectivity();
    _updateNetworkStatus(initialStatus);
  }

  void _updateNetworkStatus(List<ConnectivityResult> results) {
    debugPrint(results.toString());
    if (results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.vpn)) {
      networkStatus.value = NetworkStatus.connected;
      _stopRetryTimer();
    } else if (results.contains(ConnectivityResult.none)) {
      networkStatus.value = NetworkStatus.disconnected;
      _startRetryTimer();
    } else {
      networkStatus.value = NetworkStatus.connecting;
      _startRetryTimer();
    }
  }

  Future<void> refreshNetworkStatus() async {
    final status = await _connectivity.checkConnectivity();
    debugPrint(status.toString());
    _updateNetworkStatus(status);
  }

  void _startRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await refreshNetworkStatus();
    });
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _stopRetryTimer();
    super.onClose();
  }
}
