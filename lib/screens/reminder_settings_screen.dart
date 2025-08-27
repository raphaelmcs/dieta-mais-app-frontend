import 'package:dieta_mais_app/api/firebase_api.dart';
import 'package:dieta_mais_app/widgets/gradient_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  final _api = FirebaseApi();

  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  int _hydrationInterval = 120; // minutes

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final breakfast = await _storage.read(key: 'breakfast_time');
    final lunch = await _storage.read(key: 'lunch_time');
    final dinner = await _storage.read(key: 'dinner_time');
    final interval = await _storage.read(key: 'hydration_interval');

    setState(() {
      if (breakfast != null) _breakfastTime = _parseTime(breakfast);
      if (lunch != null) _lunchTime = _parseTime(lunch);
      if (dinner != null) _dinnerTime = _parseTime(dinner);
      if (interval != null) _hydrationInterval = int.tryParse(interval) ?? 120;
    });
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickTime(TimeOfDay initial, Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _save() async {
    await _storage.write(
        key: 'breakfast_time', value: _formatTime(_breakfastTime));
    await _storage.write(key: 'lunch_time', value: _formatTime(_lunchTime));
    await _storage.write(key: 'dinner_time', value: _formatTime(_dinnerTime));
    await _storage.write(
        key: 'hydration_interval', value: _hydrationInterval.toString());

    await _api.scheduleRemindersFromPreferences();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lembretes atualizados')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Configurar Lembretes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.free_breakfast),
            title: const Text('Café da manhã'),
            subtitle: Text(_formatTime(_breakfastTime)),
            onTap: () => _pickTime(_breakfastTime, (t) {
              setState(() => _breakfastTime = t);
            }),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lunch_dining),
            title: const Text('Almoço'),
            subtitle: Text(_formatTime(_lunchTime)),
            onTap: () => _pickTime(_lunchTime, (t) {
              setState(() => _lunchTime = t);
            }),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.dinner_dining),
            title: const Text('Jantar'),
            subtitle: Text(_formatTime(_dinnerTime)),
            onTap: () => _pickTime(_dinnerTime, (t) {
              setState(() => _dinnerTime = t);
            }),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_drink),
            title: const Text('Intervalo de hidratação (min)'),
            subtitle: Text('$_hydrationInterval'),
            onTap: () async {
              final controller =
                  TextEditingController(text: _hydrationInterval.toString());
              final result = await showDialog<int>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Intervalo em minutos'),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: 'minutos'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                            context, int.tryParse(controller.text) ?? 120);
                      },
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

