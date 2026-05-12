import 'package:flutter/material.dart';
import 'dart:async';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? textStyle;
  final bool compact;

  const CountdownTimer({
    Key? key,
    required this.endTime,
    this.textStyle,
    this.compact = false,
  }) : super(key: key);

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _remaining = _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  Duration _calcRemaining() {
    final remaining = widget.endTime.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _updateRemaining() {
    final remaining = _calcRemaining();
    if (remaining == Duration.zero) _timer?.cancel();
    if (!mounted) return;
    setState(() => _remaining = remaining);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration() {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    if (widget.compact) {
      if (days > 0) {
        return '${days}d ${hours}h';
      } else if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m ${seconds}s';
      }
    }

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    if (days > 0) {
      return '${days}d ${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(),
      style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
    );
  }
}
