import 'dart:ui';
import 'package:dieta_mais_app/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa o provider
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'change_password_screen.dart';
import '../api/api_service.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_scaffold.dart';
import 'login_screen.dart';

class ProfileData {
  final User user;
  final Map<String, bool> settings;
  ProfileData({required this.user, required this.settings});
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  Future<ProfileData>? _profileDataFuture;

  @override
  void initState() {
    super.initState();
    _profileDataFuture = _loadProfileData();
  }

  Future<ProfileData> _loadProfileData() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) throw Exception('Token não encontrado');

    final results = await Future.wait([
      _apiService.getUser(token),
      _apiService.getUserSettings(token),
    ]);

    return ProfileData(
      user: results[0] as User,
      settings: results[1] as Map<String, bool>,
    );
  }

  Future<void> _updateSetting(
      String key, bool value, Map<String, bool> currentSettings) async {
    setState(() {
      currentSettings[key] = value;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Token não encontrado');
      await _apiService.updateUserSettings(token, {key: value});
    } catch (e) {
      setState(() {
        currentSettings[key] = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar configuração: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _performLogout(BuildContext context) async {
    await _storage.delete(key: 'auth_token');
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _showGlassEditDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: AppThemes.glassColor.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: AppThemes.glassColor.withOpacity(0.2)),
            ),
            title: Text(title),
            content: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: const InputDecoration(hintText: "Novo valor"),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancelar',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Salvar',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                onPressed: () async {
                  try {
                    await onSave(controller.text);
                    if (mounted) Navigator.of(context).pop();
                    setState(() {
                      _profileDataFuture = _loadProfileData();
                    });
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Erro ao salvar: $e'),
                            backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: AppThemes.glassColor.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: AppThemes.glassColor.withOpacity(0.2)),
            ),
            title: const Text('Confirmar Saída'),
            content: const Text(
                'Você tem certeza de que deseja sair do aplicativo?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancelar',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Sair',
                    style: TextStyle(color: Colors.redAccent)),
                onPressed: () => _performLogout(context),
              ),
            ],
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
        title: const Text('Perfil e Configurações'),
        centerTitle: true,
      ),
      body: FutureBuilder<ProfileData>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(
                    color: theme.textTheme.bodySmall?.color));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erro ao carregar perfil: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final user = snapshot.data!.user;
            final settings = snapshot.data!.settings;

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSectionTitle('Meus Dados'),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Nome'),
                  subtitle: Text(user.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showGlassEditDialog(
                      title: 'Alterar Nome',
                      initialValue: user.name,
                      onSave: (newValue) async {
                        final token = await _storage.read(key: 'auth_token');
                        await _apiService.updateUserProfile(
                            token: token!, name: newValue);
                      },
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showGlassEditDialog(
                      title: 'Alterar Email',
                      initialValue: user.email,
                      keyboardType: TextInputType.emailAddress,
                      onSave: (newValue) async {
                        final token = await _storage.read(key: 'auth_token');
                        await _apiService.updateUserProfile(
                            token: token!, email: newValue);
                      },
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Telefone'),
                  subtitle: Text(user.phoneNumber ?? 'Não informado'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showGlassEditDialog(
                      title: 'Alterar Telefone',
                      initialValue: user.phoneNumber ?? '',
                      keyboardType: TextInputType.phone,
                      onSave: (newValue) async {
                        final token = await _storage.read(key: 'auth_token');
                        await _apiService.updateUserProfile(
                            token: token!, phoneNumber: newValue);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Notificações'),
                SwitchListTile(
                  title: const Text('Lembretes para beber água'),
                  subtitle: const Text(
                      'Receba alertas a cada 2 horas para se manter hidratado.'),
                  value: settings['wants_hydration_reminders'] ?? true,
                  onChanged: (bool value) => _updateSetting(
                      'wants_hydration_reminders', value, settings),
                  activeColor: theme.textTheme.bodySmall?.color,
                ),
                SwitchListTile(
                    title: const Text('Lembretes de refeições'),
                    subtitle: const Text(
                        'Receba um alerta no horário de cada refeição do seu plano.'),
                    value: settings['wants_meal_reminders'] ?? true,
                    onChanged: (bool value) =>
                        _updateSetting('wants_meal_reminders', value, settings),
                    activeColor: theme.textTheme.bodySmall?.color),
                const SizedBox(height: 24),
                _buildSectionTitle('Aparência'),
// ListTile para abrir o seletor de tema
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Tema do Aplicativo'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemePicker(context),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Segurança'),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Alterar Senha'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Sair (Logout)',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap:
                      _showLogoutConfirmationDialog, // <-- CORREÇÃO APLICADA AQUI
                ),
                const Divider(),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'Dieta+ App v1.0.0',
                    style: TextStyle(color: theme.textTheme.bodySmall?.color),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodySmall?.color),
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: AppThemes.themeOptions.length,
          itemBuilder: (context, index) {
            final themeOption = AppThemes.themeOptions[index];
            return ListTile(
              title: Text(themeOption.name),
              onTap: () {
                themeProvider.setTheme(themeOption);
                Navigator.of(context).pop();
              },
              trailing: themeProvider.currentTheme.name == themeOption.name
                  ? Icon(Icons.check, color: theme.textTheme.bodySmall?.color)
                  : null,
            );
          },
        );
      },
    );
  }
}
