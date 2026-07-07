import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import '../config/app_constants.dart';
import '../data/models/network_metrics.dart';

/// Handles the WebSocket connection to the backend for real-time ping
/// and metrics, and REST calls for relay/subscription data.
class NetworkService {
  WebSocketChannel? _channel;
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
  final StreamController<NetworkMetrics> _metricsController = StreamController.broadcast();
  final List<PingDataPoint> _history = [];
  Timer? _pingTimer;

  Stream<NetworkMetrics> get metricsStream => _metricsController.stream;
  List<PingDataPoint> get pingHistory => List.unmodifiable(_history);

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void connect({required String deviceId, double? lat, double? lon}) {
    _channel = WebSocketChannel.connect(Uri.parse(AppConstants.wsUrl));

    _channel!.stream.listen(
      (raw) => _handleMessage(raw),
      onError: (e) => print('[ws] error: $e'),
      onDone: () => print('[ws] closed'),
    );

    _send({
      'event': 'client-connected',
      'data': {
        'deviceId': deviceId,
        'location': lat != null && lon != null ? {'lat': lat, 'lon': lon} : null,
      },
    });

    // Measure round-trip latency every 2 seconds.
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _sendPing());
  }

  void _sendPing() {
    _send({
      'event': 'ping',
      'data': {'timestamp': DateTime.now().millisecondsSinceEpoch},
    });
  }

  void _send(Map<String, dynamic> payload) {
    // Socket.IO's actual wire protocol differs from raw JSON; in a real
    // build use `socket_io_client` package instead of raw WebSocketChannel.
    // Kept as raw JSON here to keep the reference implementation dependency-light.
    _channel?.sink.add(jsonEncode(payload));
  }

  void _handleMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      final event = decoded['event'];
      final data = decoded['data'];

      if (event == 'pong') {
        final sentAt = data['originalTimestamp'] as int;
        final rtt = DateTime.now().millisecondsSinceEpoch - sentAt;
        _recordLatency(rtt);
      }
    } catch (e) {
      print('[ws] failed to parse message: $e');
    }
  }

  void _recordLatency(int latencyMs) {
    _history.add(PingDataPoint(time: DateTime.now(), latencyMs: latencyMs));
    if (_history.length > 60) _history.removeAt(0);

    final jitter = _history.length > 1 ? (latencyMs - _history[_history.length - 2].latencyMs).abs() : 0;

    _metricsController.add(NetworkMetrics(
      latency: latencyMs,
      jitter: jitter,
      packetLoss: 0.0,
      signalStrength: 85,
      jitterHistory: List.of(_history),
    ));
  }

  Future<RelayServer?> selectBestRelay({required double lat, required double lon}) async {
    final response = await _dio.post('/api/relays/select', data: {'latitude': lat, 'longitude': lon});
    if (response.statusCode == 200 && response.data != null) {
      return RelayServer.fromJson(response.data);
    }
    return null;
  }

  void dispose() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _metricsController.close();
  }
}
