import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../api/api_service.dart';
import '../widgets/gradient_scaffold.dart';

class LogMealScreen extends StatefulWidget {
  final int dietId;
  final DateTime date; // <-- RECEBE A DATA

  const LogMealScreen({super.key, required this.dietId, required this.date});

  @override
  State<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends State<LogMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;

  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _submitMeal() async {
    final consumedDate = DateFormat('yyyy-MM-dd').format(widget.date);
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final token = await _storage.read(key: 'auth_token');
        if (token == null) throw Exception('Token não encontrado');

        await _apiService.logMeal(
          token: token,
          dietId: widget.dietId,
          foodName: _foodNameController.text,
          quantity: int.parse(_quantityController.text),
          consumedAt: widget.date, // <-- PASSA A DATA
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Refeição registrada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(title: const Text('Registrar Refeição')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _foodNameController,
                decoration:
                    const InputDecoration(labelText: 'Nome do Alimento'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Campo obrigatório'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration:
                    const InputDecoration(labelText: 'Quantidade (em gramas)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Campo obrigatório';
                  if (int.tryParse(value) == null)
                    return 'Insira um número válido';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                CircularProgressIndicator(color: theme.primaryColor)
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitMeal,
                    child: const Text('Salvar Refeição'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
