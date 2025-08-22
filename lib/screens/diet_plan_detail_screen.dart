import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../models/diet_plan.dart';
//import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart';
import 'suggestion_screen.dart';

class DietPlanDetailScreen extends StatefulWidget {
  final int dietPlanId;

  const DietPlanDetailScreen({super.key, required this.dietPlanId});

  @override
  State<DietPlanDetailScreen> createState() => _DietPlanDetailScreenState();
}

class _DietPlanDetailScreenState extends State<DietPlanDetailScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  Future<DietPlan>? _planDetailFuture;

  @override
  void initState() {
    super.initState();
    _planDetailFuture = _loadPlanDetails();
  }

  Future<DietPlan> _loadPlanDetails() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Token não encontrado');
    return _apiService.getDietPlanDetails(token, widget.dietPlanId);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Plano'),
        centerTitle: true,
      ),
      body: FutureBuilder<DietPlan>(
        future: _planDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: Theme.of(context).textTheme.bodySmall?.color));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final plan = snapshot.data!;
            // Garante que meals não seja nulo antes de construir a lista
            final meals = plan.meals ?? [];

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Adiciona um card com o resumo das metas
                GlassmorphicContainer(
                  borderRadius: 12,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        const Divider(height: 20),
                        Text('Calorias: ${plan.targetCalories} kcal'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Constrói a lista de refeições
                ...meals.map((meal) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassmorphicContainer(
                        borderRadius: 12,
                        child: ExpansionTile(
                          title: Text(meal.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 17)),
                          subtitle: Text(meal.time ?? '',
                              style: const TextStyle(fontSize: 13)),
                          childrenPadding: const EdgeInsets.only(
                              left: 32, right: 16, bottom: 12),
                          children: meal.foods.map((food) {
                            return ListTile(
                              dense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              title: Text('• ${food.quantity} de ${food.name}'),
                              onTap: () {
                                // Navega para a tela de sugestões ao tocar
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SuggestionScreen(foodName: food.name),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ))
              ],
            );
          }
          return const Center(child: Text('Nenhum detalhe encontrado.'));
        },
      ),
    );
  }
}
