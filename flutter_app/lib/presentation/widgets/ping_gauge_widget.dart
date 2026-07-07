import 'dart:math';
import 'package:flutter/material.dart';

class PingGaugeWidget extends StatelessWidget {
  final int ping;
  final String targetGame;

  const PingGaugeWidget({super.key, required this.ping, required this.targetGame});

  Color _colorFor(int ping) {
    if (ping < 50) return Colors.greenAccent;
    if (ping < 100) return Colors.amber;
    return Colors.redAccent;
  }

  String _levelFor(int ping) {
    if (ping < 30) return 'Professional Level';
    if (ping < 50) return 'High Competitive';
    if (ping < 80) return 'Good';
    if (ping < 120) return 'Acceptable';
    return 'Poor — Needs Optimization';
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(ping);
    return SizedBox(
      height: 220,
      child: CustomPaint(
        painter: _GaugePainter(percentage: (1 - (ping / 300).clamp(0, 1)), color: color),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$ping ms', style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.bold)),
              Text(targetGame, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(_levelFor(ping), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  _GaugePainter({required this.percentage, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      Paint()
        ..color = Colors.grey.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi * percentage,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.color != color;
}
