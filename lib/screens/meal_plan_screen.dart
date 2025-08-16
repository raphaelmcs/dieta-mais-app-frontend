import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'create_diet_screen.dart';
import 'suggestion_screen.dart';
import '../api/api_service.dart';
import '../models/diet_plan.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import '../widgets/glassmorphic_container.dart';

class MealPlanScreen extends StatefulWidget {
  final VoidCallback onDietActivated;
  const MealPlanScreen({super.key, required this.onDietActivated});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  Future<List<DietPlan>>? _plansFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  // A função agora é async
  void _loadPlans() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return;
    setState(() {
      _plansFuture = _apiService.getAllDietPlans(token);
    });
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
          _loadPlans(); // Recarrega a lista
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
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showAddDietOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemes.glassColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(color: AppThemes.glassColor.withOpacity(0.3)),
            ),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('Importar de PDF'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickAndUploadPdf();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note),
                  title: const Text('Criar Manualmente'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                          builder: (context) => const CreateDietScreen()),
                    );
                    if (result == true) {
                      _loadPlans();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Meus Planos'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_diet_fab',
        onPressed: _showAddDietOptions,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FutureBuilder<List<DietPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: theme.primaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final plans = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassmorphicContainer(
                    child: ListTile(
                      title: Text(plan.name),
                      subtitle: Text(
                          '${plan.targetCalories} kcal - Criado em ${DateFormat.yMd('pt_BR').format(plan.createdAt)}'),
                      leading: plan.isActive
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'activate', child: Text('Ativar')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Excluir')),
                        ],
                        onSelected: (value) async {
                          final token = await _storage.read(key: 'auth_token');
                          if (token == null) return;

                          if (value == 'activate') {
                            await _apiService.setActiveDiet(token, plan.id);
                            // Mostra a mensagem de sucesso
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Plano alimentar ativado com sucesso!'),
                                    backgroundColor: Colors.green),
                              );
                            }
                            widget
                                .onDietActivated(); // Avisa a MainScreen para recarregar o dashboard
                            _loadPlans(); // Recarrega a lista NESTA tela
                          } else if (value == 'delete') {
                            await _apiService.deleteDiet(token, plan.id);
                          }
                          _loadPlans();
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book,
                      size: 80, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(height: 24),
                  Text(
                    'Você ainda não tem nenhum plano.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22, color: theme.textTheme.bodyLarge?.color),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
