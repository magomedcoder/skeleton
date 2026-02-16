enum ReconnectMode { hybrid, exponential, fixed }

class ReconnectPolicy {
  final ReconnectMode mode;
  final Duration fixed;
  final Duration expoBase;
  final Duration maxDelay;
  final double jitter;
  final List<Duration> fastProbe;

  const ReconnectPolicy.hybrid({
    this.mode = ReconnectMode.hybrid,
    this.fixed = const Duration(seconds: 2),
    this.expoBase = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = 0.2,
    this.fastProbe = const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 5),
    ],
  });

  const ReconnectPolicy.exponential({
    this.mode = ReconnectMode.exponential,
    this.fixed = const Duration(seconds: 2),
    this.expoBase = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = 0.2,
    this.fastProbe = const [],
  });

  const ReconnectPolicy.fixed({
    this.mode = ReconnectMode.fixed,
    this.fixed = const Duration(seconds: 2),
    this.expoBase = const Duration(milliseconds: 500),
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = 0.0,
    this.fastProbe = const [],
  });

  Duration next(int attempt) {
    switch (mode) {
      case ReconnectMode.fixed:
        return fixed;

      case ReconnectMode.hybrid:
        if (attempt < fastProbe.length) {
          return fastProbe[attempt];
        }
        final shifted = attempt - fastProbe.length;
        return _expo(shifted);

      case ReconnectMode.exponential:
        return _expo(attempt);
    }
  }

  Duration _expo(int attempt) {
    final pow2 = 1 << attempt;
    int ms = expoBase.inMilliseconds * pow2;
    if (ms > maxDelay.inMilliseconds) {
      ms = maxDelay.inMilliseconds;
    }

    if (jitter > 0) {
      final j = (ms * jitter).toInt();
      final rnd = DateTime.now().microsecond % (2 * j + 1) - j;
      ms += rnd;
      if (ms < 0) {
        ms = 0;
      }
    }
    return Duration(milliseconds: ms);
  }
}
