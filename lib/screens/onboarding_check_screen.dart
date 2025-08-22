import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_service.dart';
import '../widgets/gradient_scaffold.dart';
import 'main_screen.dart';
import 'welcome_empty_state_screen.dart';

class OnboardingCheckScreen extends StatefulWidget {
  const OnboardingCheckScreen({super.key});
  @override
  State<OnboardingCheckScreen> createState() => _OnboardingCheckScreenState();
}

class _OnboardingCheckScreenState extends State<OnboardingCheckScreen> {
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkStatusAndNavigate();
  }

  Future<void> _checkStatusAndNavigate() async {
    await Future.delayed(
        const Duration(milliseconds: 500)); // Pequeno delay para fluidez
    final token = await _storage.read(key: 'auth_token');
    if (token == null || !mounted) return;

    try {
      final hasActiveDiet = await _apiService.checkUserStatus(token);
      if (!mounted) return;

      if (hasActiveDiet) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const WelcomeEmptyStateScreen()),
        );
      }
    } catch (e) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const GradientScaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
