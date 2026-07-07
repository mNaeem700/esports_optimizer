import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_provider.dart';
import '../widgets/ping_gauge_widget.dart';
import '../widgets/jitter_graph_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Kick off the websocket connection once the widget tree is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(networkServiceProvider).connect(deviceId: 'demo-device-01');
    });
  }

  @override
  Widget build(BuildContext context) {
    final metrics = ref.watch(networkMetricsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Network Performance'),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
      ),
      body: metrics.when(
        data: (m) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              PingGaugeWidget(ping: m.latency, targetGame: 'PUBG Mobile'),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Latency history', style: TextStyle(color: Colors.white70)),
                      JitterGraphWidget(history: m.jitterHistory),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _StabilityRow(score: m.stabilityScore, jitter: m.jitter, loss: m.packetLoss),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Connection error: $e', style: const TextStyle(color: Colors.redAccent))),
      ),
    );
  }
}

class _StabilityRow extends StatelessWidget {
  final int score;
  final int jitter;
  final double loss;
  const _StabilityRow({required this.score, required this.jitter, required this.loss});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(label: 'Stability', value: '$score/100'),
        _StatTile(label: 'Jitter', value: '${jitter}ms'),
        _StatTile(label: 'Packet Loss', value: '${(loss * 100).toStringAsFixed(1)}%'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: const Color(0xFF1E1E1E),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
