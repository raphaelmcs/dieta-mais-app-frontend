// lib/screens/reminder_settings_screen.dart
// ---------------------------------------------------------------------------
// Configura lembretes a partir do plano alimentar ativo (horários) + hidratação.
// - Busca plano ativo (ou detalhes do ativo) e mapeia para slots.
// - NÃO sobrescreve horários do plano com o que está no storage.
// - Aceita "HH:mm" e "HH:mm:ss" (ou variantes) → usa "HH:mm".
// - Ordena os slots por horário na UI.
// - Ao salvar, persiste no SecureStorage e reagenda no FirebaseApi.
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/firebase_api.dart';
import '../api/api_service.dart';
import '../models/diet_plan.dart';
import '../models/meal.dart';
import '../widgets/gradient_scaffold.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _apiService = ApiService();
  final _firebaseApi = FirebaseApi();

  // Rótulos dos slots (mesmas keys usadas no storage)
  static const Map<String, String> _slotTitles = FirebaseApi.slotTitles;

  // Times default (caso nada venha do plano nem do storage)
  final Map<String, TimeOfDay> _slotTimes = {
    'breakfast_time': const TimeOfDay(hour: 8, minute: 0),
    'snack_morning_time': const TimeOfDay(hour: 10, minute: 0),
    'lunch_time': const TimeOfDay(hour: 12, minute: 0),
    'snack_afternoon_time': const TimeOfDay(hour: 16, minute: 0),
    'dinner_time': const TimeOfDay(hour: 19, minute: 0),
    'snack_night_time': const TimeOfDay(hour: 21, minute: 0),
  };

  int _hydrationInterval = 120; // minutos
  bool _loading = true;
  String? _sourceHint;
  List<Meal> _planMeals = [];

  // Guarda quais slots foram preenchidos a partir do plano
  final Set<String> _filledFromPlan = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // ---------------------------------------------------------------------------
  // Bootstrap: busca plano ativo → aplica aos slots → completa com storage
  // ---------------------------------------------------------------------------
  Future<void> _bootstrap() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      if (token != null && token.isNotEmpty) {
        // 1) tenta pegar plano ativo direto
        DietPlan? plan;
        try {
          plan = await _apiService.getActiveDietPlan(token);
        } catch (e) {
          debugPrint('[reminder] getActiveDietPlan falhou: $e');
        }

        // 2) se não tem/refeições vazias, busca via lista -> detalhes
        if (plan == null || plan.meals == null || plan.meals!.isEmpty) {
          try {
            final plans = await _apiService.getDietPlans(token);
            final active = plans.firstWhere(
              (p) => p.isActive,
              orElse: () => plans.isNotEmpty
                  ? plans.first
                  : throw Exception('Sem planos'),
            );
            plan = await _apiService.getDietPlanDetails(token, active.id);
            debugPrint(
                '[reminder] carregado via getDietPlanDetails id=${active.id}');
          } catch (e) {
            debugPrint('[reminder] fallback via detalhes falhou: $e');
          }
        }

        // 3) caso tenhamos refeições no plano, aplica
        if (plan != null && plan.meals != null && plan.meals!.isNotEmpty) {
          _planMeals = plan.meals!;
          final filledNow = _applyPlanToSlots(
              _planMeals); // <- preenche e retorna slots preenchidos
          _filledFromPlan
            ..clear()
            ..addAll(filledNow);

          // fallback heurístico: se nada casou por alias, tenta 3 primeiras por horário
          if (_filledFromPlan.isEmpty) {
            _fallbackHeuristicFromMeals(_planMeals);
          }
          _sourceHint = 'Horários carregados do plano alimentar ativo';
        } else {
          _sourceHint =
              'Plano ativo sem horários; usando preferências salvas/padrão';
        }
      } else {
        _sourceHint = 'Sem autenticação; usando preferências salvas/padrão';
      }

      // 4) completa com storage SOMENTE slots que não vieram do plano
      await _loadRemainingSlotsFromStorage();

      // 5) hidratação do storage (ou default)
      final interval = await _storage.read(key: 'hydration_interval');
      _hydrationInterval = int.tryParse(interval ?? '') ?? 120;
    } catch (e) {
      debugPrint('[reminder] bootstrap erro geral: $e');
      // Falhou tudo? Pega do storage (ou defaults) para TODOS os slots
      await _loadAllSlotsFromStorage();
      final interval = await _storage.read(key: 'hydration_interval');
      _hydrationInterval = int.tryParse(interval ?? '') ?? 120;
      _sourceHint ??=
          'Falha ao carregar plano; usando preferências salvas/padrão';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Plano → Slots (via aliases)
  // Retorna os slotKeys preenchidos a partir do plano.
  // ---------------------------------------------------------------------------
  Set<String> _applyPlanToSlots(List<Meal> meals) {
    final filled = <String>{};

    final Map<String, List<String>> aliases = {
      'breakfast_time': [
        'café da manhã',
        'cafe da manha',
        'desjejum',
        'breakfast'
      ],
      'lunch_time': ['almoço', 'almoco', 'lunch'],
      'dinner_time': ['jantar', 'dinner', 'ceia'],
      'snack_morning_time': [
        'lanche da manhã',
        'lanche manhã',
        'morning snack',
        'snack morning'
      ],
      'snack_afternoon_time': [
        'lanche da tarde',
        'afternoon snack',
        'snack afternoon'
      ],
      'snack_night_time': [
        'lanche da noite',
        'night snack',
        'snack night',
        'ceia'
      ],
    };

    String norm(String s) {
      final lower = s.toLowerCase().trim();
      return lower
          .replaceAll('á', 'a')
          .replaceAll('à', 'a')
          .replaceAll('â', 'a')
          .replaceAll('ã', 'a')
          .replaceAll('é', 'e')
          .replaceAll('ê', 'e')
          .replaceAll('í', 'i')
          .replaceAll('ó', 'o')
          .replaceAll('ô', 'o')
          .replaceAll('õ', 'o')
          .replaceAll('ú', 'u')
          .replaceAll('ç', 'c')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ');
    }

    for (final slot in _slotTitles.keys) {
      final ali = (aliases[slot] ?? const <String>[]).map(norm).toList();

      Meal? selected;
      for (final m in meals) {
        if (ali.contains(norm(m.name))) {
          selected = m;
          break;
        }
      }

      final raw = (selected?.time ?? '').trim();
      final hhmm = _extractHHmm(raw); // aceita HH:mm e HH:mm:ss
      if (hhmm != null) {
        _slotTimes[slot] = _toTimeOfDay(hhmm);
        filled.add(slot);
      }
    }

    return filled;
  }

  // ---------------------------------------------------------------------------
  // Heurística de fallback: usa as 3 primeiras refeições com horário ordenadas.
  // ---------------------------------------------------------------------------
  void _fallbackHeuristicFromMeals(List<Meal> meals) {
    final items = <_MealAt>[];

    for (final m in meals) {
      final hhmm = _extractHHmm((m.time ?? '').trim());
      if (hhmm != null)
        items.add(_MealAt(name: m.name, time: _toTimeOfDay(hhmm)));
    }
    if (items.isEmpty) return;

    items.sort((a, b) {
      final ah = a.time.hour, am = a.time.minute;
      final bh = b.time.hour, bm = b.time.minute;
      return ah != bh ? ah.compareTo(bh) : am.compareTo(bm);
    });

    if (items.isNotEmpty) _slotTimes['breakfast_time'] = items[0].time;
    if (items.length >= 2) _slotTimes['lunch_time'] = items[1].time;
    if (items.length >= 3) _slotTimes['dinner_time'] = items[2].time;
  }

  // ---------------------------------------------------------------------------
  // Storage fallbacks
  // ---------------------------------------------------------------------------
  Future<void> _loadRemainingSlotsFromStorage() async {
    for (final slot in _slotTitles.keys) {
      if (_filledFromPlan.contains(slot))
        continue; // NÃO sobrescreve o que veio do plano
      final v = await _storage.read(key: slot);
      final hhmm = _extractHHmm(v ?? '');
      if (hhmm != null) {
        _slotTimes[slot] = _toTimeOfDay(hhmm);
      }
    }
  }

  Future<void> _loadAllSlotsFromStorage() async {
    for (final slot in _slotTitles.keys) {
      final v = await _storage.read(key: slot);
      final hhmm = _extractHHmm(v ?? '');
      if (hhmm != null) {
        _slotTimes[slot] = _toTimeOfDay(hhmm);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers de horário
  // ---------------------------------------------------------------------------
  /// Extrai "HH:mm" de "HH:mm", "HH:mm:ss" ou strings com sufixos.
  String? _extractHHmm(String raw) {
    if (raw.isEmpty) return null;
    final re = RegExp(r'^(\d{2}):(\d{2})(?::\d{2})?');
    final m = re.firstMatch(raw);
    if (m != null) {
      final hh = m.group(1)!;
      final mm = m.group(2)!;
      if (_isValidHHmm('$hh:$mm')) return '$hh:$mm';
    }
    if (raw.length >= 5 && RegExp(r'^\d{2}:\d{2}').hasMatch(raw)) {
      final hhmm = raw.substring(0, 5);
      if (_isValidHHmm(hhmm)) return hhmm;
    }
    return null;
  }

  bool _isValidHHmm(String s) {
    final re = RegExp(r'^\d{2}:\d{2}$');
    if (!re.hasMatch(s)) return false;
    final p = s.split(':');
    final h = int.tryParse(p[0]) ?? -1;
    final m = int.tryParse(p[1]) ?? -1;
    return h >= 0 && h < 24 && m >= 0 && m < 60;
  }

  TimeOfDay _toTimeOfDay(String hhmm) {
    final p = hhmm.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------------------
  // Ações de UI
  // ---------------------------------------------------------------------------
  Future<void> _pickTime(String slot) async {
    final picked =
        await showTimePicker(context: context, initialTime: _slotTimes[slot]!);
    if (picked != null) setState(() => _slotTimes[slot] = picked);
  }

  Future<void> _save() async {
    for (final e in _slotTimes.entries) {
      await _storage.write(key: e.key, value: _formatTime(e.value));
    }
    await _storage.write(
      key: 'hydration_interval',
      value: _hydrationInterval.toString(),
    );

    await _firebaseApi.scheduleRemindersFromPreferences();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lembretes atualizados')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  List<MapEntry<String, TimeOfDay>> _orderedSlots() {
    final list = _slotTimes.entries.toList();
    list.sort((a, b) {
      final ah = a.value.hour, am = a.value.minute;
      final bh = b.value.hour, bm = b.value.minute;
      return ah != bh ? ah.compareTo(bh) : am.compareTo(bm);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Configurar Lembretes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_sourceHint != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_sourceHint!)),
                      ],
                    ),
                  ),
                ..._orderedSlots().map((entry) {
                  final slotKey = entry.key;
                  final time = entry.value;
                  final label = _slotTitles[slotKey] ?? slotKey;
                  return Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.alarm),
                        title: Text(label),
                        subtitle: Text(_formatTime(time)),
                        onTap: () => _pickTime(slotKey),
                      ),
                      const Divider(),
                    ],
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.local_drink),
                  title: const Text('Intervalo de hidratação (min)'),
                  subtitle: Text('$_hydrationInterval'),
                  onTap: () async {
                    final controller = TextEditingController(
                        text: _hydrationInterval.toString());
                    final result = await showDialog<int>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Intervalo em minutos'),
                        content: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(hintText: 'minutos'),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(
                                context, int.tryParse(controller.text) ?? 120),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                    if (result != null) {
                      setState(() => _hydrationInterval = result);
                    }
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Salvar'),
                ),
              ],
            ),
    );
  }
}

// Struct simples para ordenação heurística
class _MealAt {
  final String name;
  final TimeOfDay time;
  _MealAt({required this.name, required this.time});
}
