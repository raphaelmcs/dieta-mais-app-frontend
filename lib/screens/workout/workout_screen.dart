// lib/screens/workout/workout_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// UI utilitários
import '../../widgets/gradient_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glassmorphic_container.dart';

// API / modelos
import '../../api/api_service.dart';
import '../../models/workout_exercise_dto.dart';
import '../../models/program_dtos.dart';

// Componentes da tela
import 'widgets/modality_picker.dart';
import 'panels/bodybuilding_panel.dart';
import 'panels/crossfit_panel.dart';
import 'panels/hyrox_panel.dart';

// Criar série
import '../workout/program_builder_screen.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _api = ApiService();
  final _storage = const FlutterSecureStorage();

  /// slug da modalidade selecionada: 'bodybuilding' | 'crossfit' | 'hyrox'
  String? _selectedModality;

  /// exercícios carregados do backend para a modalidade
  List<WorkoutExerciseDto> _exercises = [];

  /// estado de carregamento/erro dos exercícios
  bool _loading = false;
  String? _error;

  /// Programa ativo para a modalidade selecionada
  ProgramDto? _activeProgram;
  bool _loadingProgram = false;

  @override
  void initState() {
    super.initState();
    // default: musculação selecionada ao abrir
    _selectedModality = 'bodybuilding';
    _reloadForModality();
  }

  Future<void> _reloadForModality() async {
    await Future.wait([
      _loadExercises(),
      _loadActiveProgram(),
    ]);
  }

  Future<void> _loadActiveProgram() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || _selectedModality == null) return;

    setState(() => _loadingProgram = true);
    try {
      final list = await _api.getPrograms(token);
      // escolhe o primeiro programa ativo da modalidade atual
      final p = list.firstWhere(
        (p) => p.isActive && p.modality == _selectedModality,
        orElse: () =>
            ProgramDto(id: -1, name: '', modality: '', isActive: false),
      );
      setState(() => _activeProgram = (p.id == -1) ? null : p);
    } catch (_) {
      // silencioso; opcionalmente mostrar SnackBar
    } finally {
      if (mounted) setState(() => _loadingProgram = false);
    }
  }

  // ---------- Helpers catálogo ----------

  Future<void> _loadExercises() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || _selectedModality == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _exercises = [];
    });

    try {
      final list = await _api.getWorkoutExercises(token, _selectedModality!);
      if (!mounted) return;
      setState(() => _exercises = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSelectModality(String slug) {
    setState(() {
      _selectedModality = slug;
      _exercises = [];
      _error = null;
      _activeProgram = null;
    });
    _loadExercises();
    _loadActiveProgram();
  }

  // ---------- Ações ----------

  void _openProgramBuilder() async {
    // Usa a modalidade atualmente selecionada (fallback para bodybuilding)
    final initial = _selectedModality ?? 'bodybuilding';

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProgramBuilderScreen(initialModality: initial),
      ),
    );

    if (result == true) {
      // Recarrega programa ativo e (se quiser) sessões
      await _loadActiveProgram();
      // _reloadSessions(); // se/quando houver listagem de sessões do dia
    }
  }

  // ---------- UI ----------

  Widget _emptyMusclePanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GlassmorphicContainer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Musculação',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Você ainda não possui uma série ativa.\n'
                'Crie uma série ABC/ABCD para os próximos meses e nós '
                'distribuiremos automaticamente seus treinos no calendário.',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openProgramBuilder,
                  icon: const Icon(Icons.post_add_outlined),
                  label: const Text('Criar série (ABC/ABCD)'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // futuro: importar PDF/foto
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Em breve: importar série.')),
                  );
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Importar série (PDF/Foto)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeProgramBanner() {
    if (_loadingProgram) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (_activeProgram == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: GlassmorphicContainer(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: const Icon(Icons.flag_circle_outlined),
          title: Text(
            'Série ativa: ${_activeProgram!.name}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: const Text('Distribuída automaticamente no calendário.'),
          trailing: IconButton(
            tooltip: 'Criar nova série',
            onPressed: _openProgramBuilder,
            icon: const Icon(Icons.post_add_outlined),
          ),
        ),
      ),
    );
  }

  Widget _panelByModality() {
    if (_selectedModality == null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassmorphicContainer(
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Selecione uma modalidade para ver os exercícios.'),
          ),
        ),
      );
    }

    // banner de programa ativo (se houver)
    final banner = _activeProgramBanner();

    if (_selectedModality == 'bodybuilding') {
      // Se não tem série ativa, mostra a tela vazia com CTA de criar série
      if (_activeProgram == null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _emptyMusclePanel(),
          ],
        );
      }

      // Com série ativa: pode mostrar banner e (opcionalmente) o catálogo
      if (_loading) {
        return Column(
          children: [
            banner,
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        );
      }
      if (_error != null) {
        return Column(
          children: [
            banner,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassmorphicContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Erro: $_error'),
                ),
              ),
            ),
          ],
        );
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          children: [
            banner,
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BodybuildingPanel(
                exercises: _exercises,
                onCreateWorkout: _openProgramBuilder, // agora cria série
                onPickExercise: (_) {}, // não usado neste fluxo
              ),
            ),
          ],
        ),
      );
    }

    // CrossFit / Hyrox (mantém como estava)
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassmorphicContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Erro: $_error'),
          ),
        ),
      );
    }

    switch (_selectedModality) {
      case 'crossfit':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: CrossfitPanel(
            exercises: _exercises,
            onCreateWorkout: _openProgramBuilder,
            onPickExercise: (_) {},
          ),
        );
      case 'hyrox':
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: HyroxPanel(
            exercises: _exercises,
            onCreateWorkout: _openProgramBuilder,
            onPickExercise: (_) {},
          ),
        );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final dfHeader = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR');

    return GradientScaffold(
      appBar: AppBar(
        title: Text('Treinos • ${dfHeader.format(DateTime.now())}'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Criar série (ABC/ABCD)',
            icon: const Icon(Icons.post_add_outlined),
            onPressed: _openProgramBuilder,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Picker de modalidade
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ModalityPicker(
              selectedSlug: _selectedModality,
              onSelected: _onSelectModality,
            ),
          ),
          // Painel dinâmico por modalidade
          _panelByModality(),
        ],
      ),
    );
  }
}
