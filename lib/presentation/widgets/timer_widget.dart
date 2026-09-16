import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';

class TimerWidget extends StatefulWidget {
  final Duration duration;
  const TimerWidget({super.key, required this.duration});

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  @override
  Widget build(BuildContext context) {
    final isLong = widget.duration.inMinutes > 30;
    final isVeryLong = widget.duration.inMinutes > 60;
    final color = isVeryLong ? Colors.red : (isLong ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        Formatters.formatDuration(widget.duration),
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
