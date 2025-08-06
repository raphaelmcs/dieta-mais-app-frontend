import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Importante para detectar a web
import 'package:http/http.dart' as http;
import '../models/daily_summary.dart'; // Importa nosso novo modelo

class ApiService {
  // Esta lógica agora escolhe a URL base correta automaticamente!
  final String _baseUrl = kIsWeb
      ? "http://127.0.0.1:8000/api/v1" // URL para quando estiver rodando na WEB
      : "http://10.0.2.2:8000/api/v1"; // URL para quando estiver rodando no EMULADOR ANDROID

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token'];
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Falha ao fazer login.');
    }
  }

  Future<DailySummary> getDailySummary(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/daily-summary'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Envia o token para autenticação
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DailySummary.fromJson(data);
    } else {
      throw Exception('Falha ao carregar o resumo diário.');
    }
  }
}
