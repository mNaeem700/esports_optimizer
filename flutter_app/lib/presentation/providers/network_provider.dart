import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/network_service.dart';
import '../../data/models/network_metrics.dart';

final networkServiceProvider = Provider<NetworkService>((ref) {
  final service = NetworkService();
  ref.onDispose(service.dispose);
  return service;
});

final networkMetricsProvider = StreamProvider<NetworkMetrics>((ref) {
  final service = ref.watch(networkServiceProvider);
  return service.metricsStream;
});

final selectedRelayProvider = FutureProvider.family<RelayServer?, ({double lat, double lon})>((ref, coords) async {
  final service = ref.watch(networkServiceProvider);
  return service.selectBestRelay(lat: coords.lat, lon: coords.lon);
});
