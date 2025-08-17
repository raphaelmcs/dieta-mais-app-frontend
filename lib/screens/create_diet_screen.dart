import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_service.dart';
import '../widgets/gradient_scaffold.dart';

// Classes de modelo para ajudar a gerenciar o estado do formulário
class FoodEntry {
  TextEditingController nameController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
}

class MealEntry {
  TextEditingController nameController = TextEditingController();
  TextEditingController timeController = TextEditingController();
  List<FoodEntry> foods = [FoodEntry()]; // Começa com um campo de alimento
}

class CreateDietScreen extends StatefulWidget {
  const CreateDietScreen({super.key});

  @override
  State<CreateDietScreen> createState() => _CreateDietScreenState();
}

class _CreateDietScreenState extends State<CreateDietScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  // Controllers para as metas
  final _planNameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _hydrationController = TextEditingController();

  // Lista dinâmica de refeições
  List<MealEntry> _meals = [MealEntry()]; // Começa com uma refeição
  @override
  void dispose() {
    _planNameController.dispose(); // Limpa o novo controller
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _hydrationController.dispose();
    for (var meal in _meals) {
      meal.nameController.dispose();
      meal.timeController.dispose();
      for (var food in meal.foods) {
        food.nameController.dispose();
        food.quantityController.dispose();
      }
    }
    super.dispose();
  }

  void _addMeal() {
    setState(() {
      _meals.add(MealEntry());
    });
  }

  void _addFoodToMeal(int mealIndex) {
    setState(() {
      _meals[mealIndex].foods.add(FoodEntry());
    });
  }

  Future<void> _saveDietPlan() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      // Constrói o objeto JSON a partir dos controllers
      final dietData = {
        'name': _planNameController.text,
        'target_calories': int.tryParse(_caloriesController.text) ?? 0,
        'target_protein': int.tryParse(_proteinController.text) ?? 0,
        'target_carbs': int.tryParse(_carbsController.text) ?? 0,
        'target_fats': int.tryParse(_fatsController.text) ?? 0,
        'hydration_goal_ml': int.tryParse(_hydrationController.text) ?? 0,
        'meals': _meals
            .map((meal) => {
                  'name': meal.nameController.text,
                  'time': meal.timeController.text,
                  'foods': meal.foods
                      .map((food) => {
                            'name': food.nameController.text,
                            'quantity': food.quantityController.text,
                          })
                      .toList(),
                })
            .toList(),
      };

      try {
        final token = await _storage.read(key: 'auth_token');
        if (token == null) throw Exception('Token não encontrado');

        await _apiService.createManualDiet(token, dietData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Plano criado com sucesso!'),
                backgroundColor: Colors.green),
          );
          Navigator.of(context)
              .pop(true); // Retorna 'true' para indicar sucesso
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Criar Plano Manual'),
        actions: [
          IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveDietPlan),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Metas Diárias'),
            TextFormField(
              controller: _planNameController,
              decoration: const InputDecoration(
                  labelText: 'Nome do Plano (ex: Cutting Semana 1)'),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'O nome do plano é obrigatório.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calorias (kcal)'),
                keyboardType: TextInputType.number),
            TextFormField(
                controller: _proteinController,
                decoration: const InputDecoration(labelText: 'Proteínas (g)'),
                keyboardType: TextInputType.number),
            TextFormField(
                controller: _carbsController,
                decoration:
                    const InputDecoration(labelText: 'Carboidratos (g)'),
                keyboardType: TextInputType.number),
            TextFormField(
                controller: _fatsController,
                decoration: const InputDecoration(labelText: 'Gorduras (g)'),
                keyboardType: TextInputType.number),
            TextFormField(
                controller: _hydrationController,
                decoration:
                    const InputDecoration(labelText: 'Meta de Água (ml)'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            _buildSectionTitle('Refeições'),
            ..._buildMealForms(),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _addMeal,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Adicionar Outra Refeição'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealForms() {
    return _meals.asMap().entries.map((entry) {
      int mealIndex = entry.key;
      MealEntry meal = entry.value;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextFormField(
                  controller: meal.nameController,
                  decoration: const InputDecoration(
                      labelText: 'Nome da Refeição (ex: Café da Manhã)')),
              TextFormField(
                  controller: meal.timeController,
                  decoration:
                      const InputDecoration(labelText: 'Horário (ex: 08:00)')),
              const SizedBox(height: 8),
              ...meal.foods.asMap().entries.map((foodEntry) {
                //int foodIndex = foodEntry.key;
                FoodEntry food = foodEntry.value;
                return Row(
                  children: [
                    Expanded(
                        child: TextFormField(
                            controller: food.nameController,
                            decoration:
                                const InputDecoration(labelText: 'Alimento'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextFormField(
                            controller: food.quantityController,
                            decoration: const InputDecoration(
                                labelText: 'Quantidade'))),
                  ],
                );
              }).toList(),
              TextButton(
                  onPressed: () => _addFoodToMeal(mealIndex),
                  child: const Text('Adicionar Alimento')),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor)),
    );
  }
}
