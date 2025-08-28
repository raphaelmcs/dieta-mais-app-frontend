// lib/screens/workout/workout_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/gradient_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_container.dart';

import '../../api/api_service.dart';
import 'widgets/modality_picker.dart';
import 'panels/bodybuilding_panel.dart';
import 'panels/crossfit_panel.dart';
import 'panels/hyrox_panel.dart';
import '../workout/add_edit_workout_sheet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  String? _selectedModality; // bodybuilding | crossfit | hyrox
  List<Map<String, dynamic>> _exercises = [];
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  String? _error;

  Future<void> _loadExercises() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || _selectedModality == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getWorkoutExercises(token, _selectedModality!);
      setState(() => _exercises = list);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSelectModality(String slug) {
    setState(() {
      _selectedModality = slug;
      _exercises = [];
    });
    _loadExercises();
  }

  void _openAddEdit() async {
    // Abre bottom sheet de criação/edição já com a modalidade atual.
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: AppThemes.glassColor.withOpacity(0.25),
            child: AddEditWorkoutSheet(
              initial: null,
              defaultDate: _selectedDate,
              // se seu AddEdit já detecta modalidade pelo state, ignore este comentário;
              // caso queira, adicione um argumento `forcedModality: _selectedModality`
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR');

    Widget _panel() {
      if (_selectedModality == null) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GlassmorphicContainer(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Selecione uma modalidade para ver os exercícios.',
                style: TextStyle(color: theme.textTheme.bodySmall?.color),
              ),
            ),
          ),
        );
      }
      if (_loading)
        return const Center(
            child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ));
      if (_error != null) return Center(child: Text('Erro: $_error'));

      switch (_selectedModality) {
        case 'bodybuilding':
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: BodybuildingPanel(
              exercises: _exercises,
              onCreateWorkout: _openAddEdit,
              onPickExercise: (ex) {/* pré-preencher AddEdit se quiser */},
            ),
          );
        case 'crossfit':
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: CrossfitPanel(
              exercises: _exercises,
              onCreateWorkout: _openAddEdit,
              onPickExercise: (ex) {},
            ),
          );
        case 'hyrox':
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: HyroxPanel(
              exercises: _exercises,
              onCreateWorkout: _openAddEdit,
              onPickExercise: (ex) {},
            ),
          );
      }
      return const SizedBox.shrink();
    }

    return GradientScaffold(
      appBar: AppBar(
        title: Text('Treinos • ${df.format(_selectedDate)}'),
        centerTitle: false,
        actions: [
          if (_selectedModality != null)
            IconButton(
              tooltip: 'Novo treino',
              icon: const Icon(Icons.add),
              onPressed: _openAddEdit,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Picker de modalidade
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ModalityPicker(
              selectedSlug: _selectedModality,
              onSelected: _onSelectModality,
            ),
          ),
          // Painel dinâmico
          _panel(),
        ],
      ),
      floatingActionButton: (_selectedModality == null)
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddEdit,
              label: const Text('Novo treino'),
              icon: const Icon(Icons.fitness_center),
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
    );
  }
}
