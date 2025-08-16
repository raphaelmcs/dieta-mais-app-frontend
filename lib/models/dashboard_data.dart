import 'daily_summary.dart';
import 'meal_log.dart';

// A classe agora vive em seu próprio arquivo
class DashboardData {
  final DailySummary summary;
  final List<MealLog> todaysMeals;

  DashboardData({required this.summary, required this.todaysMeals});
}
