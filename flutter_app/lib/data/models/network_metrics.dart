class PingDataPoint {
  final DateTime time;
  final int latencyMs;
  PingDataPoint({required this.time, required this.latencyMs});
}

class NetworkMetrics {
  final int latency;
  final int jitter;
  final double packetLoss; // 0.0 - 1.0
  final int signalStrength; // 0 - 100
  final List<PingDataPoint> jitterHistory;

  NetworkMetrics({
    required this.latency,
    required this.jitter,
    required this.packetLoss,
    required this.signalStrength,
    this.jitterHistory = const [],
  });

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) {
    return NetworkMetrics(
      latency: (json['latency_ms'] ?? json['latency'] ?? 0) as int,
      jitter: (json['jitter_ms'] ?? json['jitter'] ?? 0) as int,
      packetLoss: (json['packet_loss_percent'] ?? json['packetLoss'] ?? 0.0).toDouble(),
      signalStrength: (json['signal_strength'] ?? 80) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'latency_ms': latency,
        'jitter_ms': jitter,
        'packet_loss_percent': packetLoss,
        'signal_strength': signalStrength,
      };

  int get stabilityScore {
    final jitterPenalty = (jitter / 2).clamp(0, 100).toInt();
    final lossPenalty = (packetLoss * 100).clamp(0, 100).toInt();
    return (100 - jitterPenalty - lossPenalty).clamp(0, 100);
  }
}

class RelayServer {
  final int id;
  final String name;
  final String region;
  final int predictedLatencyMs;

  RelayServer({required this.id, required this.name, required this.region, required this.predictedLatencyMs});

  factory RelayServer.fromJson(Map<String, dynamic> json) {
    final relay = json['relay'] ?? json;
    return RelayServer(
      id: relay['id'],
      name: relay['server_name'] ?? relay['name'] ?? 'Unknown',
      region: relay['region'] ?? '',
      predictedLatencyMs: json['predictedLatencyMs'] ?? 0,
    );
  }
}
