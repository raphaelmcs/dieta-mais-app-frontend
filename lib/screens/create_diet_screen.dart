import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
//import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart';
import 'dart:ui';

// Classes de modelo para ajudar a gerenciar o estado do formulário
class FoodEntry {
  TextEditingController nameController = TextEditingController();
  TextEditingController quantityController = TextEditingController();
}

class MealEntry {
  String? selectedMealName;
  TextEditingController timeController = TextEditingController();
  List<FoodEntry> foods = [FoodEntry()];
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

  // Lista de refeições pré-definidas para o usuário escolher
  final List<String> _predefinedMeals = [
    'Café da Manhã',
    'Lanche da Manhã',
    'Almoço',
    'Lanche da Tarde',
    'Jantar',
    'Ceia',
  ];

  List<MealEntry> _meals = [MealEntry()]; // Começa com uma refeição

  @override
  void dispose() {
    _planNameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _hydrationController.dispose();
    for (var meal in _meals) {
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

  void _removeMeal(int index) {
    setState(() {
      _meals.removeAt(index);
    });
  }

  void _addFoodToMeal(int mealIndex) {
    setState(() {
      _meals[mealIndex].foods.add(FoodEntry());
    });
  }

  void _removeFoodFromMeal(int mealIndex, int foodIndex) {
    setState(() {
      _meals[mealIndex].foods.removeAt(foodIndex);
    });
  }

  Future<void> _saveDietPlan() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
          .where((meal) => meal.selectedMealName != null)
          .map((meal) => {
                'name': meal.selectedMealName,
                'time': meal.timeController.text,
                'foods': meal.foods
                    .where((food) => food.nameController.text.isNotEmpty)
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
        Navigator.of(context).pop(true); // Retorna 'true' para indicar sucesso
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
            _buildSectionTitle('Informações do Plano'),
            TextFormField(
              controller: _planNameController,
              decoration: const InputDecoration(
                  labelText: 'Nome do Plano (ex: Cutting Semana 1)'),
              validator: (v) => (v == null || v.isEmpty)
                  ? 'O nome do plano é obrigatório.'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildSectionTitle('Metas Diárias'),
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

  return GlassmorphicContainer(
  borderRadius: 16,
  margin: const EdgeInsets.symmetric(vertical: 8),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: meal.selectedMealName,
                hint: const Text('Selecione a Refeição'),
                items: _predefinedMeals.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    meal.selectedMealName = newValue;
                  });
                },
                validator: (v) =>
                    v == null ? 'Selecione uma refeição' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeMeal(mealIndex),
            ),
          ],
        ),
        TextFormField(
          controller: meal.timeController,
          decoration: const InputDecoration(labelText: 'Horário (ex: 08:00)'),
        ),
        const SizedBox(height: 16),
        const Text('Alimentos:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...meal.foods.asMap().entries.map((foodEntry) {
          int foodIndex = foodEntry.key;
          FoodEntry food = foodEntry.value;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: food.nameController,
                  decoration: const InputDecoration(labelText: 'Alimento'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: food.quantityController,
                  decoration: const InputDecoration(labelText: 'Quantidade'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => _removeFoodFromMeal(mealIndex, foodIndex),
              ),
            ],
          );
        }).toList(),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _addFoodToMeal(mealIndex),
            child: const Text('Adicionar Alimento'),
          ),
        ),
      ],
    ),
  ),
);
    }).toList();
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title,
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor)),
    );
  }
}
