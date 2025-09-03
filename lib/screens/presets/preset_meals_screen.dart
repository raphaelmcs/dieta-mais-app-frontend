import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../api/api_service.dart';
import '../../models/food_estimate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../widgets/glassmorphic_container.dart';
import '../food/food_photo_screen.dart';

/// Modelo simples para preset salvo localmente
class PresetMeal {
  final String name;
  final FoodEstimate estimate;

  PresetMeal({required this.name, required this.estimate});

  Map<String, dynamic> toJson() => {
        'name': name,
        'estimate': estimate.toJson(), // formato “plano” (sem wrapper data)
      };

  factory PresetMeal.fromJson(Map<String, dynamic> json) {
    final estJson = json['estimate'];
    // FoodEstimate.fromJson espera wrapper {data:{...}}. Envelopamos.
    final estimate = FoodEstimate.fromJson({'data': estJson});
    return PresetMeal(name: json['name'] ?? 'Sem nome', estimate: estimate);
  }
}

class PresetMealsScreen extends StatefulWidget {
  /// Se vier de “Salvar como refeição”, podemos receber a estimativa e um nome
  final FoodEstimate? initialEstimate;
  final String? initialName;

  const PresetMealsScreen({super.key, this.initialEstimate, this.initialName});

  @override
  State<PresetMealsScreen> createState() => _PresetMealsScreenState();
}

class _PresetMealsScreenState extends State<PresetMealsScreen> {
  static const _kStorageKey = 'preset_meals_v1';
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();

  List<PresetMeal> _presets = [];
  bool _loading = false;
  String? _error;

  int? _activeDietId;
  String _activeDietName = '—';

  @override
  void initState() {
    super.initState();
    _loadActiveDiet();
    _loadPresets().then((_) async {
      // Se veio com uma refeição pronta para salvar, já adiciona
      if (widget.initialEstimate != null && widget.initialName != null) {
        await _addPreset(widget.initialName!, widget.initialEstimate!);
      }
    });
  }

  Future<void> _loadActiveDiet() async {
    try {
      final plan = await _api.tryGetActiveDietPlan();
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

  Future<void> _loadPresets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _storage.read(key: _kStorageKey);
      if (raw == null || raw.isEmpty) {
        setState(() => _presets = []);
        return;
      }
      final list = (jsonDecode(raw) as List)
          .map((e) => PresetMeal.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() => _presets = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _savePresets() async {
    final data = _presets.map((e) => e.toJson()).toList();
    await _storage.write(key: _kStorageKey, value: jsonEncode(data));
  }

  Future<void> _addPreset(String name, FoodEstimate estimate) async {
    setState(() => _presets.insert(0, PresetMeal(name: name, estimate: estimate)));
    await _savePresets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refeição padrão salva!')),
    );
  }

  Future<void> _deletePreset(int index) async {
    final removed = _presets.removeAt(index);
    setState(() {});
    await _savePresets();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excluído: ${removed.name}')),
    );
  }

  Future<void> _usePreset(PresetMeal p) async {
    // Registra no dia atual, com plano ativo
    try {
      setState(() => _loading = true);
      await _api.registerEstimateIntoMealLog(
        p.estimate,
        consumedAt: DateTime.now(),
        dietId: _activeDietId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${p.name}” registrada no seu dia!')),
      );
      Navigator.of(context).pop(); // fecha o detalhe
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(PresetMeal p) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) {
        // Somatório de macros (quando existentes)
        double? totalP, totalC, totalF;
        final items = p.estimate.items;
        final hasP = items.any((e) => e.proteinG != null);
        final hasC = items.any((e) => e.carbsG != null);
        final hasF = items.any((e) => e.fatsG != null);
       if (hasP) {
  totalP = items.fold<double>(0.0, (s, e) => s + (e.proteinG ?? 0.0));
}
if (hasC) {
  totalC = items.fold<double>(0.0, (s, e) => s + (e.carbsG ?? 0.0));
}
if (hasF) {
  totalF = items.fold<double>(0.0, (s, e) => s + (e.fatsG ?? 0.0));
}

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.14),
                  border: Border.all(color: Colors.white.withOpacity(.18)),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: AppTheme.cardTitleStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                          tooltip: 'Fechar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Itens
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            ...items.map((it) {
                              final macro = (it.proteinG != null ||
                                      it.carbsG != null ||
                                      it.fatsG != null)
                                  ? ' • P:${(it.proteinG ?? 0).toStringAsFixed(1)}g  '
                                      'C:${(it.carbsG ?? 0).toStringAsFixed(1)}g  '
                                      'G:${(it.fatsG ?? 0).toStringAsFixed(1)}g'
                                  : '';
                              return GlassmorphicContainer(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${it.label}\n${it.portionGrams} g • ${it.calories} kcal$macro',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            // Total
                            GlassmorphicContainer(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total', style: AppTheme.cardTitleStyle),
                                      Text('${p.estimate.totalCalories} kcal',
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Ações
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : () => _usePreset(p),
                            icon: const Icon(Icons.playlist_add_check_outlined),
                            label: const Text('Utilizar refeição'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Refeições padrão'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Center(
              child: Text(
                _activeDietId != null ? 'Plano: $_activeDietName' : 'Sem plano ativo',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Botão "Nova" — estilo glass e volta para FoodPhotoScreen
              Align(
                alignment: Alignment.centerRight,
                child: GlassmorphicContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      // volta para a tela de foto (vazia, pois lá fazemos reset)
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const FoodPhotoScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 6),
                        Text('Nova'),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_presets.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Você ainda não salvou nenhuma refeição padrão.\nToque em “Nova” para criar.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _presets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final p = _presets[index];
                      return Dismissible(
                        key: ValueKey('${p.name}-$index'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(.25),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                        onDismissed: (_) => _deletePreset(index),
                        child: GlassmorphicContainer(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              p.name,
                              style: AppTheme.cardTitleStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${p.estimate.items.length} itens • ${p.estimate.totalCalories} kcal',
                            ),
                            onTap: () => _openDetail(p),
                            trailing: IconButton(
                              tooltip: 'Utilizar',
                              icon: const Icon(Icons.playlist_add_check_outlined),
                              onPressed: _loading ? null : () => _usePreset(p),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
