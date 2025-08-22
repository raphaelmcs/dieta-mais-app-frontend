import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
import '../models/food_suggestion.dart';
//import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart'; // Importa nosso container de vidro

class SuggestionScreen extends StatefulWidget {
  final String foodName;

  const SuggestionScreen({super.key, required this.foodName});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  Future<List<FoodSuggestion>>? _suggestionsFuture;

  @override
  void initState() {
    super.initState();
    _suggestionsFuture = _loadSuggestions();
  }

  Future<List<FoodSuggestion>> _loadSuggestions() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      // Idealmente, teríamos uma lógica para deslogar o usuário aqui
      throw Exception('Token não encontrado.');
    }
    return _apiService.getFoodSuggestions(token, widget.foodName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: Text('Alternativas para ${widget.foodName}'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<FoodSuggestion>>(
        future: _suggestionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao buscar sugestões: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final suggestions = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                // Usando nosso container de vidro no lugar do Card
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GlassmorphicContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quantidade: ${suggestion.quantity}',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            suggestion.reason,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Nenhuma sugestão encontrada.'));
        },
      ),
    );
  }
}
