class DailyHydrationLog {
  final int day;
  final int totalMl;

  DailyHydrationLog({required this.day, required this.totalMl});

  factory DailyHydrationLog.fromJson(Map<String, dynamic> json) {
    return DailyHydrationLog(
      day: (json['day'] as num).toInt(),
      totalMl: (json['total_ml'] as num).toInt(),
    );
  }
}
