import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/gradient_scaffold.dart';
//import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:fl_chart/fl_chart.dart';
import 'login_screen.dart';
import '../api/api_service.dart';
import '../models/daily_summary.dart';
import '../models/macro_data.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final _pageController = PageController();
  Future<DailySummary>? _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<DailySummary> _loadSummary() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token de autenticação não encontrado.');
    }
    return _apiService.getDailySummary(token);
  }

  Future<void> _performLogout(BuildContext context) async {
    await _storage.delete(key: 'auth_token');
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // O método build agora ficou muito mais simples e legível!
    return GradientScaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _performLogout(context)),
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _summaryFuture = _loadSummary())),
        ],
      ),
      body: FutureBuilder<DailySummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            //final summary = snapshot.data!;
            return Column(
                // ... o conteúdo do Column continua o mesmo ...
                );
          }
          return const Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }

  Widget _buildChartPage(String title, MacroData data, MacroData targets) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: targets.calories.toDouble(),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                            color: AppTheme.secondaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14);
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = 'Kcal';
                            break;
                          case 1:
                            text = 'Prot';
                            break;
                          case 2:
                            text = 'Carb';
                            break;
                          case 3:
                            text = 'Gord';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return SideTitleWidget(
                            meta: meta, child: Text(text, style: style));
                      },
                      reservedSize: 38,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _makeBarGroup(
                      0, data.calories.toDouble(), AppTheme.accentColor),
                  _makeBarGroup(
                      1, data.protein.toDouble() * 4, Colors.lightBlueAccent),
                  _makeBarGroup(
                      2, data.carbs.toDouble() * 4, Colors.orangeAccent),
                  _makeBarGroup(3, data.fats.toDouble() * 9, Colors.pinkAccent),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
