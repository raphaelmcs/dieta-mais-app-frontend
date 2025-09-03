import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_service.dart';
import '../../models/food_estimate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glassmorphic_container.dart';
import '../presets/preset_meals_screen.dart';
import '../main_screen.dart'; // para navegar aos Planos (aba 1)

class FoodPhotoScreen extends StatefulWidget {
  const FoodPhotoScreen({super.key});

  @override
  State<FoodPhotoScreen> createState() => _FoodPhotoScreenState();
}

class _FoodPhotoScreenState extends State<FoodPhotoScreen> {
  final _picker = ImagePicker();
  File? _imageFile;
  FoodEstimate? _estimate;
  bool _loading = false;
  String? _error;

  DateTime _takenAt = DateTime.now();

  // Plano ativo (para registrar no dia)
  int? _activeDietId;
  String _activeDietName = '—';

  @override
  void initState() {
    super.initState();
    _loadActiveDiet();
  }

  Future<void> _loadActiveDiet() async {
    try {
      final api = ApiService();
      final plan = await api.tryGetActiveDietPlan();
      if (!mounted) return;
      setState(() {
        _activeDietId = plan?.id;
        _activeDietName = plan?.name ?? 'Nenhum plano ativo';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activeDietId = null;
        _activeDietName = 'Erro ao carregar plano';
      });
    }
  }

  Future<void> _takePhoto() async {
    setState(() => _error = null);
    final picked =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _estimate = null;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _error = null);
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _estimate = null;
      });
    }
  }

  Future<void> _openPresets() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PresetMealsScreen()),
    );
    if (!mounted) return;
    // ao voltar, limpa a tela
    setState(() {
      _imageFile = null;
      _estimate = null;
      _error = null;
      _takenAt = DateTime.now();
    });
  }

  Future<void> _estimateCalories() async {
    if (_imageFile == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final result = await api.estimateCaloriesFromPhoto(_imageFile!);
      setState(() => _estimate = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onPortionChanged(int index, double grams) {
    if (_estimate == null) return;
    final items = List<FoodItemEstimate>.from(_estimate!.items);
    final it = items[index];

    final double g = grams;
    final int newKcal = (it.kcalPerGram * g).round();
    final double? newP =
        it.proteinPerGram != null ? (it.proteinPerGram! * g) : null;
    final double? newC =
        it.carbsPerGram != null ? (it.carbsPerGram! * g) : null;
    final double? newF = it.fatsPerGram != null ? (it.fatsPerGram! * g) : null;

    items[index] = it.copyWith(
      portionGrams: g.round(),
      calories: newKcal,
      proteinG: newP,
      carbsG: newC,
      fatsG: newF,
    );

    final int totalKcal = items.fold<int>(0, (sum, e) => sum + e.calories);
    setState(() {
      _estimate = _estimate!.copyWith(items: items, totalCalories: totalKcal);
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
    );
    if (time == null) return;

    setState(() {
      _takenAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // =========== DIÁLOGOS ===========
  /// Diálogo com blur que pergunta se quer salvar e já coleta o nome.
  Future<String?> _confirmAndAskNameDialog() async {
    final controller = TextEditingController();

    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Salvar como refeição',
      barrierColor: Colors.transparent,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (ctx, anim, _, __) {
        final opacity =
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return Stack(
          children: [
            // blur de fundo
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(color: Colors.black.withOpacity(0.25)),
                ),
              ),
            ),
            // card
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: opacity.value,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.14),
                          border: Border.all(
                            color: Colors.white.withOpacity(.18),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Salvar como refeição?',
                                style: AppTheme.cardTitleStyle),
                            const SizedBox(height: 8),
                            Text(
                              'Isso criará um atalho em “Refeições padrão”.\nDê um nome para identificá-la depois.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Nome da refeição',
                                hintText:
                                    'Ex.: Almoço (frango, arroz, feijão)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(null),
                                    child: const Text('Cancelar'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final name = controller.text.trim();
                                      Navigator.of(ctx)
                                          .pop(name.isEmpty ? null : name);
                                    },
                                    child: const Text('Salvar'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Sem plano ativo: informa e oferece ir para a aba de Planos.
  Future<void> _noActivePlanDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Plano ativo necessário'),
        content: const Text(
          'Para registrar no seu dia, você precisa ter um plano alimentar ativo.\n'
          'Você pode tirar a foto e salvar como refeição normalmente; '
          'mas para registrar no dia, ative/crie um plano.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(initialIndex: 1),
                ),
              );
            },
            child: const Text('Ir para Planos'),
          ),
        ],
      ),
    );
  }

  // =========== AÇÕES ===========
  /// Salvar como refeição: agora pergunta e coleta nome.
  Future<void> _saveEstimatedMeal() async {
    if (_estimate == null) return;

    // 1) Pergunta e coleta nome
    final name = await _confirmAndAskNameDialog();
    if (name == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 2) Salva no backend (EstimatedMealsController@store)
      final api = ApiService();
      await api.saveEstimatedMeal(_estimate!, takenAt: _takenAt);

      if (!mounted) return;

      // 3) Encaminha para a lista de “Refeições padrão”,
      //    que adiciona localmente (via initialEstimate/initialName)
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PresetMealsScreen(
            initialEstimate: _estimate,
            initialName: name,
          ),
        ),
      );

      if (!mounted) return;
      // 4) Limpa a tela ao voltar
      setState(() {
        _imageFile = null;
        _estimate = null;
        _error = null;
        _takenAt = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refeição salva com sucesso!')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Só registra se houver plano ativo.
  Future<void> _registerIntoMealLog() async {
    if (_estimate == null) return;

    if (_activeDietId == null) {
      await _noActivePlanDialog();
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      await api.registerEstimateIntoMealLog(
        _estimate!,
        consumedAt: _takenAt,
        dietId: _activeDietId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrado no seu dia (MealLog)!')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_takenAt.day.toString().padLeft(2, '0')}/${_takenAt.month.toString().padLeft(2, '0')}/${_takenAt.year} '
        '${_takenAt.hour.toString().padLeft(2, '0')}:${_takenAt.minute.toString().padLeft(2, '0')}';

    double? totalP, totalC, totalF;
    if (_estimate != null) {
      final hasP = _estimate!.items.any((e) => e.proteinG != null);
      final hasC = _estimate!.items.any((e) => e.carbsG != null);
      final hasF = _estimate!.items.any((e) => e.fatsG != null);

      if (hasP) {
        totalP = _estimate!.items.fold<double>(
            0, (s, e) => s + (e.proteinG ?? 0.0));
      }
      if (hasC) {
        totalC =
            _estimate!.items.fold<double>(0, (s, e) => s + (e.carbsG ?? 0.0));
      }
      if (hasF) {
        totalF =
            _estimate!.items.fold<double>(0, (s, e) => s + (e.fatsG ?? 0.0));
      }
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Foto do prato'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_outline),
            tooltip: 'Refeições padrão',
            onPressed: _openPresets,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                'Tire uma foto do seu prato ou selecione da galeria para estimar as calorias aproximadas.',
                style: AppTheme.subtitleStyle,
              ),
              const SizedBox(height: 16),

              // Ações principais (Câmera | Galeria)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Câmera'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Galeria'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_imageFile != null)
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(12),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),

              const SizedBox(height: 12),

              if (_imageFile != null && !_loading)
                ElevatedButton.icon(
                  onPressed: _estimateCalories,
                  icon: const Icon(Icons.local_fire_department_outlined),
                  label: const Text('Estimar calorias'),
                ),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (_estimate != null) ...[
                const SizedBox(height: 16),
                Text('Sugestões detectadas',
                    style: AppTheme.sectionTitleStyle),
                const SizedBox(height: 8),

                ..._estimate!.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final it = entry.value;

                  final macroStr = (it.proteinG != null ||
                          it.carbsG != null ||
                          it.fatsG != null)
                      ? ' • P:${(it.proteinG ?? 0).toStringAsFixed(1)}g  '
                          'C:${(it.carbsG ?? 0).toStringAsFixed(1)}g  '
                          'G:${(it.fatsG ?? 0).toStringAsFixed(1)}g'
                      : '';

                  const double kMinG = 10.0;
                  const double kMaxG = 600.0;
                  final double sliderValue =
                      it.portionGrams.toDouble().clamp(kMinG, kMaxG);

                  return GlassmorphicContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${it.label} • ${(it.confidence * 100).toStringAsFixed(0)}% conf.',
                          style: AppTheme.cardTitleStyle,
                        ),
                        const SizedBox(height: 6),
                        Text(
                            'Porção: ${it.portionGrams} g  •  ${it.calories} kcal$macroStr'),
                        Slider(
                          value: sliderValue,
                          min: kMinG,
                          max: kMaxG,
                          divisions: ((kMaxG - kMinG) / 5).round(),
                          label: '${sliderValue.round()} g',
                          onChanged: (v) => _onPortionChanged(idx, v),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // Totais
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total estimado',
                              style: AppTheme.cardTitleStyle),
                          Text('${_estimate!.totalCalories} kcal',
                              style: AppTheme.cardTitleStyle),
                        ],
                      ),
                      if (totalP != null ||
                          totalC != null ||
                          totalF != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Macros • '
                          '${totalP != null ? 'P:${totalP.toStringAsFixed(1)}g  ' : ''}'
                          '${totalC != null ? 'C:${totalC.toStringAsFixed(1)}g  ' : ''}'
                          '${totalF != null ? 'G:${totalF.toStringAsFixed(1)}g' : ''}',
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Quando e plano ativo
                GlassmorphicContainer(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined),
                          const SizedBox(width: 8),
                          Expanded(child: Text('Consumido em: $dateStr')),
                          TextButton(
                              onPressed: _pickDateTime,
                              child: const Text('Alterar')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.restaurant_menu_outlined),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Plano ativo: $_activeDietName',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _saveEstimatedMeal,
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Salvar como refeição'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _registerIntoMealLog,
                        icon:
                            const Icon(Icons.playlist_add_check_outlined),
                        label: const Text('Registrar no meu dia'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
