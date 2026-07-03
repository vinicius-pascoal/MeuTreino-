class RestTimerValue {
  final int initialSeconds;
  final int remainingSeconds;
  final DateTime? endsAt;

  const RestTimerValue({
    required this.initialSeconds,
    required this.remainingSeconds,
    required this.endsAt,
  });

  factory RestTimerValue.initial({required int initialSeconds}) {
    final safeInitialSeconds = initialSeconds < 0 ? 0 : initialSeconds;

    return RestTimerValue(
      initialSeconds: safeInitialSeconds,
      remainingSeconds: safeInitialSeconds,
      endsAt: null,
    );
  }

  factory RestTimerValue.fromJson(Map<String, dynamic> json) {
    final endsAtRaw = json['endsAt'];

    return RestTimerValue(
      initialSeconds: (json['initialSeconds'] as num?)?.toInt() ?? 0,
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt() ?? 0,
      endsAt: endsAtRaw is String ? DateTime.tryParse(endsAtRaw) : null,
    );
  }

  bool get isRunning => endsAt != null;

  bool get isModified => isRunning || remainingSeconds != initialSeconds;

  int remainingAt(DateTime now) {
    if (!isRunning) {
      return _clampSeconds(remainingSeconds, initialSeconds);
    }

    final remainingMilliseconds = endsAt!.difference(now).inMilliseconds;
    if (remainingMilliseconds <= 0) {
      return 0;
    }

    final remainingSecondsFromClock = (remainingMilliseconds / 1000).ceil();
    return _clampSeconds(remainingSecondsFromClock, initialSeconds);
  }

  RestTimerValue normalized({
    required int initialSeconds,
    DateTime? now,
  }) {
    final safeInitialSeconds = initialSeconds < 0 ? 0 : initialSeconds;
    final referenceTime = now ?? DateTime.now();
    final resolvedRemaining = isRunning
        ? remainingAt(referenceTime)
        : _clampSeconds(remainingSeconds, safeInitialSeconds);

    return RestTimerValue(
      initialSeconds: safeInitialSeconds,
      remainingSeconds: resolvedRemaining,
      endsAt: isRunning && resolvedRemaining > 0 ? endsAt : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'initialSeconds': initialSeconds,
      'remainingSeconds': remainingSeconds,
      'endsAt': endsAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RestTimerValue &&
        other.initialSeconds == initialSeconds &&
        other.remainingSeconds == remainingSeconds &&
        other.endsAt == endsAt;
  }

  @override
  int get hashCode => Object.hash(initialSeconds, remainingSeconds, endsAt);

  static int _clampSeconds(int value, int maxValue) {
    if (value < 0) return 0;
    if (value > maxValue) return maxValue;
    return value;
  }
}
