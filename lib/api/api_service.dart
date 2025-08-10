import 'dart:io';
import 'dart:convert';
import 'package:dieta_mais_app/models/food_suggestion.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Importante para detectar a web
import 'package:http/http.dart' as http;
import '../models/daily_summary.dart'; // Importa nosso novo modelo
import '../models/meal_log.dart';
import '../models/diet_plan.dart';

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

  Future<void> logMeal({
    required String token,
    required int dietId,
    required String foodName,
    required int quantity, // Agora é um int
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/meal-logs'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'diet_id': dietId,
        'food_name': foodName,
        'quantity': quantity,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Falha ao registrar a refeição.');
    }
  }

  Future<List<FoodSuggestion>> getFoodSuggestions(
      String token, String foodName) async {
    // Prepara a URL com o parâmetro de query
    final uri = Uri.parse('$_baseUrl/food-suggestions').replace(
      queryParameters: {'food_name': foodName},
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // A API retorna um objeto {"suggestions": [...]}, então precisamos acessar a lista
      List<dynamic> suggestionsList = data['suggestions'];
      return suggestionsList
          .map((json) => FoodSuggestion.fromJson(json))
          .toList();
    } else {
      throw Exception('Falha ao buscar sugestões.');
    }
  }

  Future<List<MealLog>> getTodaysMeals(String token) async {
    final uri = Uri.parse('$_baseUrl/meal-logs/today');
    print('📡 GET $uri');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('🔹 Status: ${response.statusCode}');
    print('🔹 Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data.map((json) => MealLog.fromJson(json)).toList();
        } else {
          throw Exception("Formato inesperado da resposta (não é lista)");
        }
      } catch (e) {
        throw Exception("Erro ao processar refeições: $e");
      }
    } else {
      throw Exception(
          'Falha ao carregar as refeições do dia. Status: ${response.statusCode} | Body: ${response.body}');
    }
  }

  // ***** NOVO MÉTODO PARA UPLOAD DE ARQUIVO *****
  Future<void> uploadDietPdf(String token, File pdfFile) async {
    final uri = Uri.parse('$_baseUrl/diets');

    // Cria uma requisição do tipo multipart
    var request = http.MultipartRequest('POST', uri);

    // Adiciona os headers de autenticação
    request.headers['Accept'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $token';

    // Anexa o arquivo à requisição
    request.files.add(
      await http.MultipartFile.fromPath(
        'diet_pdf', // Este nome DEVE ser o mesmo que o backend espera
        pdfFile.path,
      ),
    );

    // Envia a requisição e espera a resposta
    final streamedResponse = await request.send();

    // Converte a resposta para um formato legível
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 201) {
      throw Exception(
          'Falha ao enviar o PDF. Status: ${response.statusCode} | Body: ${response.body}');
    }
  }

  Future<DietPlan> getActiveDietPlan(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/diets/active'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return DietPlan.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar o plano alimentar.');
    }
  }

  Future<void> deleteMealLog(String token, int mealLogId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/meal-logs/$mealLogId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // 204 No Content é a resposta de sucesso para um DELETE
    if (response.statusCode != 204) {
      throw Exception('Falha ao deletar a refeição.');
    }
  }

  Future<void> sendDeviceToken(String authToken, String fcmToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/device-token'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(<String, String>{
        'fcm_token': fcmToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao registrar o token do dispositivo.');
    }
  }

  Future<Map<String, bool>> getUserSettings(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/user/settings'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // A API retorna um Map<String, dynamic>, convertemos para Map<String, bool>
      final data = Map<String, bool>.from(jsonDecode(response.body));
      return data;
    } else {
      throw Exception('Falha ao carregar as configurações.');
    }
  }

  Future<void> updateUserSettings(
      String token, Map<String, bool> settings) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/settings'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(settings),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar as configurações.');
    }
  }
}
