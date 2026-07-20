import 'dart:async';

import 'package:flutter/material.dart';

import '../models/rest_timer_value.dart';

class RestTimer extends StatefulWidget {
  final int initialSeconds;
  final RestTimerValue? initialValue;
  final ValueChanged<RestTimerValue>? onChanged;
  final VoidCallback? onFinished;
  final bool compact;

  const RestTimer({
    super.key,
    required this.initialSeconds,
    this.initialValue,
    this.onChanged,
    this.onFinished,
    this.compact = false,
  });

  @override
  State<RestTimer> createState() => _RestTimerState();
}

class _RestTimerState extends State<RestTimer> with WidgetsBindingObserver {
  Timer? _timer;
  late RestTimerValue _value;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreFromWidget(notifyIfNormalized: true);
  }

  @override
  void didUpdateWidget(covariant RestTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSeconds != widget.initialSeconds ||
        oldWidget.initialValue != widget.initialValue) {
      _restoreFromWidget(notifyIfNormalized: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDisplay();
    }
  }

  void _restoreFromWidget({required bool notifyIfNormalized}) {
    final now = DateTime.now();
    final rawValue =
        widget.initialValue ??
        RestTimerValue.initial(initialSeconds: widget.initialSeconds);
    final restoredValue = rawValue.normalized(
      initialSeconds: widget.initialSeconds,
      now: now,
    );
    final finishedWhileAway =
        rawValue.isRunning &&
        !restoredValue.isRunning &&
        restoredValue.remainingSeconds == 0;

    _timer?.cancel();
    _value = restoredValue;
    _remainingSeconds = restoredValue.remainingAt(now);
    _restartTickerIfNeeded();

    if (notifyIfNormalized && rawValue != restoredValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        widget.onChanged?.call(restoredValue);

        if (finishedWhileAway) {
          widget.onFinished?.call();
        }
      });
    }
  }

  void _start() {
    if (_value.isRunning || _remainingSeconds <= 0) return;

    final now = DateTime.now();
    final nextValue = RestTimerValue(
      initialSeconds: widget.initialSeconds,
      remainingSeconds: _remainingSeconds,
      endsAt: now.add(Duration(seconds: _remainingSeconds)),
    ).normalized(initialSeconds: widget.initialSeconds, now: now);

    setState(() {
      _value = nextValue;
      _remainingSeconds = nextValue.remainingAt(now);
    });

    _restartTickerIfNeeded();
    widget.onChanged?.call(nextValue);
  }

  void _pause() {
    final now = DateTime.now();
    final nextValue = RestTimerValue(
      initialSeconds: widget.initialSeconds,
      remainingSeconds: _value.remainingAt(now),
      endsAt: null,
    ).normalized(initialSeconds: widget.initialSeconds, now: now);

    setState(() {
      _timer?.cancel();
      _value = nextValue;
      _remainingSeconds = nextValue.remainingSeconds;
    });

    widget.onChanged?.call(nextValue);
  }

  void _reset() {
    final nextValue = RestTimerValue.initial(initialSeconds: widget.initialSeconds);

    setState(() {
      _timer?.cancel();
      _value = nextValue;
      _remainingSeconds = nextValue.remainingSeconds;
    });

    widget.onChanged?.call(nextValue);
  }

  void _restartTickerIfNeeded() {
    _timer?.cancel();

    if (!_value.isRunning) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshDisplay();
    });
  }

  void _refreshDisplay() {
    final now = DateTime.now();
    final nextRemaining = _value.remainingAt(now);

    if (_value.isRunning && nextRemaining == 0) {
      final finishedValue = RestTimerValue(
        initialSeconds: widget.initialSeconds,
        remainingSeconds: 0,
        endsAt: null,
      );

      _timer?.cancel();

      setState(() {
        _value = finishedValue;
        _remainingSeconds = 0;
      });

      widget.onChanged?.call(finishedValue);
      widget.onFinished?.call();
      return;
    }

    if (nextRemaining == _remainingSeconds) {
      return;
    }

    setState(() {
      _remainingSeconds = nextRemaining;
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B).withValues(alpha: 0.96),
              const Color(0xFF111827).withValues(alpha: 0.96),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descanso',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formattedTime,
                      style: const TextStyle(
                        fontSize: 24,
                        height: 1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 40,
                child: FilledButton.icon(
                  onPressed: _value.isRunning ? _pause : _start,
                  icon: Icon(_value.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_value.isRunning ? 'Pausar' : 'Iniciar'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Reiniciar',
                child: IconButton(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                  onPressed: _value.isRunning ? _pause : _start,
                  icon: Icon(_value.isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_value.isRunning ? 'Pausar' : 'Iniciar'),
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
