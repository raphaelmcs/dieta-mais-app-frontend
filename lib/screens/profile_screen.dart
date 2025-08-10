import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  bool _hydrationReminders = true;
  bool _mealReminders = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');

      final settings = await _apiService.getUserSettings(token);
      setState(() {
        _hydrationReminders = settings['wants_hydration_reminders'] ?? true;
        _mealReminders = settings['wants_meal_reminders'] ?? true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao carregar configurações: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');

      await _apiService.updateUserSettings(token, {key: value});

      // Atualiza o estado local apenas após o sucesso da API
      setState(() {
        if (key == 'wants_hydration_reminders') {
          _hydrationReminders = value;
        } else if (key == 'wants_meal_reminders') {
          _mealReminders = value;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar configuração: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Perfil e Configurações'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor))
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text(
                  'Notificações',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Lembretes para beber água'),
                  subtitle: const Text(
                      'Receba alertas a cada 2 horas para se manter hidratado.'),
                  value: _hydrationReminders,
                  onChanged: (bool value) {
                    _updateSetting('wants_hydration_reminders', value);
                  },
                  activeColor: AppTheme.accentColor,
                ),
                SwitchListTile(
                  title: const Text('Lembretes de refeições'),
                  subtitle: const Text(
                      'Receba um alerta no horário de cada refeição do seu plano.'),
                  value: _mealReminders,
                  onChanged: (bool value) {
                    _updateSetting('wants_meal_reminders', value);
                  },
                  activeColor: AppTheme.accentColor,
                ),
              ],
            ),
    );
  }
}
