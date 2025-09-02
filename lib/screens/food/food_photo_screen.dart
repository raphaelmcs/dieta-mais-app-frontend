import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_service.dart';
import '../../models/food_estimate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glassmorphic_container.dart';

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
  final _dietIdCtrl = TextEditingController(); // opcional

  @override
  void dispose() {
    _dietIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    setState(() {
      _error = null;
    });
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
    setState(() {
      _error = null;
    });
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _estimate = null;
      });
    }
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
      setState(() {
        _estimate = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Recalcula kcal e macros proporcionalmente ao novo peso (g)
  void _onPortionChanged(int index, double grams) {
    if (_estimate == null) return;
    final items = List<FoodItemEstimate>.from(_estimate!.items);
    final it = items[index];

    final double g = grams;
    // kcal
    final int newKcal = (it.kcalPerGram * g).round();
    // macros (podem ser null se backend não enviou)
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

  Future<void> _saveEstimatedMeal() async {
    if (_estimate == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      await api.saveEstimatedMeal(_estimate!, takenAt: _takenAt);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Refeição (estimada) salva com sucesso!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _registerIntoMealLog() async {
    if (_estimate == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final dietId = int.tryParse(_dietIdCtrl.text.trim());
      await api.registerEstimateIntoMealLog(_estimate!,
          consumedAt: _takenAt, dietId: dietId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrado no seu dia! (MealLog)')),
        );
        // Se quiser, navegar pro dashboard:
        // Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${_takenAt.day.toString().padLeft(2, '0')}/${_takenAt.month.toString().padLeft(2, '0')}/${_takenAt.year} '
        '${_takenAt.hour.toString().padLeft(2, '0')}:${_takenAt.minute.toString().padLeft(2, '0')}';

    // agregados de macros (quando houver pelo menos um item com macros)
    double? totalP, totalC, totalF;
    if (_estimate != null) {
      final hasP = _estimate!.items.any((e) => e.proteinG != null);
      final hasC = _estimate!.items.any((e) => e.carbsG != null);
      final hasF = _estimate!.items.any((e) => e.fatsG != null);

      if (hasP)
        totalP =
            _estimate!.items.fold<double>(0, (s, e) => s + (e.proteinG ?? 0.0));
      if (hasC)
        totalC =
            _estimate!.items.fold<double>(0, (s, e) => s + (e.carbsG ?? 0.0));
      if (hasF)
        totalF =
            _estimate!.items.fold<double>(0, (s, e) => s + (e.fatsG ?? 0.0));
    }

    return GradientScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text('Foto do prato', style: AppTheme.titleStyle),
              const SizedBox(height: 8),
              Text(
                  'Tire uma foto do seu prato ou selecione da galeria para estimar as calorias aproximadas.',
                  style: AppTheme.subtitleStyle),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Câmera'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Galeria'),
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
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_estimate != null) ...[
                const SizedBox(height: 16),
                Text('Sugestões detectadas', style: AppTheme.sectionTitleStyle),
                const SizedBox(height: 8),
                ..._estimate!.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final it = entry.value;
                  final macroStr = (it.proteinG != null ||
                          it.carbsG != null ||
                          it.fatsG != null)
                      ? ' • P:${(it.proteinG ?? 0).toStringAsFixed(1)}g  C:${(it.carbsG ?? 0).toStringAsFixed(1)}g  G:${(it.fatsG ?? 0).toStringAsFixed(1)}g'
                      : '';
                  return GlassmorphicContainer(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${it.label} • ${(it.confidence * 100).toStringAsFixed(0)}% conf.',
                            style: AppTheme.cardTitleStyle),
                        const SizedBox(height: 6),
                        Text(
                            'Porção: ${it.portionGrams} g  •  ${it.calories} kcal$macroStr'),
                        Slider(
                          value: it.portionGrams.toDouble(),
                          min: 50,
                          max: 400,
                          divisions: 14,
                          label: '${it.portionGrams} g',
                          onChanged: (v) => _onPortionChanged(idx, v),
                        ),
                      ],
                    ),
                  );
                }).toList(),

                // totais
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

                // quando/dieta?
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
                      TextFormField(
                        controller: _dietIdCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'diet_id (opcional)',
                          hintText: 'ex.: 42',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Ações finais
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
                        icon: const Icon(Icons.playlist_add_check_outlined),
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
