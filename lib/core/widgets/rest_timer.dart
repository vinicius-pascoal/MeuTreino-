import 'dart:async';

import 'package:flutter/material.dart';

class RestTimer extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onFinished;

  const RestTimer({super.key, required this.initialSeconds, this.onFinished});

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.initialSeconds;
  }

  @override
  void didUpdateWidget(covariant RestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSeconds != widget.initialSeconds) {
      _timer?.cancel();
      _remainingSeconds = widget.initialSeconds;
      _running = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;

    setState(() => _running = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
          _running = false;
        });

        widget.onFinished?.call();
        return;
      }

      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _pause() {
    _timer?.cancel();

    setState(() {
      _running = false;
    });
  }

  void _reset() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = widget.initialSeconds;
      _running = false;
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            const Text('Descanso', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(
              _formattedTime,
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _running ? _pause : _start,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pausar' : 'Iniciar'),
                ),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
