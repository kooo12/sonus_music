class FCMCleanupResult {
  final int totalProcessed;
  final int expiredCount;
  final int inactiveCount;
  final int invalidCount;
  final bool success;
  final String? error;

  FCMCleanupResult({
    required this.totalProcessed,
    required this.expiredCount,
    required this.inactiveCount,
    required this.invalidCount,
    required this.success,
    this.error,
  });

  int get totalCleaned => expiredCount + inactiveCount + invalidCount;

  @override
  String toString() {
    return 'FCMCleanupResult{totalProcessed: $totalProcessed, expired: $expiredCount, inactive: $inactiveCount, invalid: $invalidCount, success: $success}';
  }
}

class FCMTokenStats {
  final int totalTokens;
  final int activeTokens;
  final int inactiveTokens;
  final int recentTokens;
  final int oldTokens;

  FCMTokenStats({
    required this.totalTokens,
    required this.activeTokens,
    required this.inactiveTokens,
    required this.recentTokens,
    required this.oldTokens,
  });

  double get activePercentage =>
      totalTokens > 0 ? (activeTokens / totalTokens) * 100 : 0.0;
  double get recentPercentage =>
      activeTokens > 0 ? (recentTokens / activeTokens) * 100 : 0.0;

  @override
  String toString() {
    return 'FCMTokenStats{total: $totalTokens, active: $activeTokens, inactive: $inactiveTokens, recent: $recentTokens, old: $oldTokens}';
  }
}
