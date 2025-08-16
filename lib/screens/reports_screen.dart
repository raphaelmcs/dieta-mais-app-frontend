import 'package:flutter/material.dart';
//import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'reports/views/monthly_report_view.dart'; // Importa a nova view
import 'reports/views/weekly_report_view.dart'; // Importa a view semanal
import 'reports/views/annual_report_view.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 abas
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Semanal'),
            Tab(text: 'Mensal'),
            Tab(text: 'Anual'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const WeeklyReportView(),
          const MonthlyReportView(),
          const AnnualReportView(),
        ],
      ),
    );
  }
}
