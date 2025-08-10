import 'dart:io';
import 'dart:ui'; // Import para o efeito de vidro
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
import '../models/diet_plan.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'suggestion_screen.dart';
import '../widgets/glassmorphic_container.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  Future<DietPlan>? _dietPlanFuture;

  // ▼▼▼ VARIÁVEL QUE FALTAVA DECLARAR ▼▼▼
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _dietPlanFuture = _loadDietPlan();
  }

  Future<DietPlan> _loadDietPlan() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('Token não encontrado.');
    }
    return _apiService.getActiveDietPlan(token);
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      final file = File(result.files.single.path!);

      try {
        final token = await _storage.read(key: 'auth_token');
        if (token == null) throw Exception('Token não encontrado.');

        await _apiService.uploadDietPdf(token, file);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Nova dieta importada com sucesso!'),
                backgroundColor: Colors.green),
          );
          // Recarrega os dados do plano alimentar
          setState(() => _dietPlanFuture = _loadDietPlan());
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro no upload: $e'),
                backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Meu Plano Alimentar'),
        centerTitle: true,
      ),
      // BOTÃO NO ESTILO VIDRO
      floatingActionButton: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.glassColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                width: 1.5,
                color: AppTheme.glassColor.withOpacity(0.25),
              ),
            ),
            child: FloatingActionButton.extended(
              onPressed: _isUploading ? null : _pickAndUploadPdf,
              label: _isUploading
                  ? const Text('Enviando...')
                  : const Text('Importar Nova Dieta'),
              icon: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.upload_file),
              backgroundColor: Colors.transparent, // Deixa o botão transparente
              elevation: 0,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FutureBuilder<DietPlan>(
        future: _dietPlanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accentColor));
          }
          if (snapshot.hasError) {
            // Tela de incentivo ao upload quando não há dieta
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.menu_book,
                        size: 80, color: AppTheme.secondaryTextColor),
                    SizedBox(height: 24),
                    Text(
                      'Nenhum plano alimentar encontrado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22, color: AppTheme.primaryTextColor),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Importe sua dieta em PDF para começar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: AppTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data!.meals.isNotEmpty) {
            final dietPlan = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16,
                  80), // Padding extra no final para o botão não cobrir o conteúdo
              itemCount: dietPlan.meals.length,
              itemBuilder: (context, index) {
                final meal = dietPlan.meals[index];
                return Padding(
                  // ***** ALTERAÇÃO 1: Diminuindo o espaçamento ENTRE os cards *****
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassmorphicContainer(
                    borderRadius: 12,
                    child: ExpansionTile(
                      // ***** ALTERAÇÃO 2: Diminuindo o espaçamento INTERNO do card *****
                      dense: true,
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: Text(
                        meal.name,
                        // ***** ALTERAÇÃO 3: Diminuindo a fonte do título *****
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Colors.white),
                      ),
                      subtitle: Text(meal.time ?? '',
                          style: const TextStyle(
                              color: AppTheme.secondaryTextColor,
                              fontSize: 13)),
                      childrenPadding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 12),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: meal.foods.map((food) {
                        // Cada alimento agora é um ListTile clicável
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 0),
                          dense: true,
                          title: Text('• ${food.quantity} de ${food.name}',
                              style: const TextStyle(fontSize: 16)),
                          onTap: () {
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
                );
              },
            );
          }
          // Tela de incentivo também se a dieta não tiver refeições
          return const Center(
              child: Text('Dieta importada, mas sem refeições detalhadas.'));
        },
      ),
    );
  }
}
