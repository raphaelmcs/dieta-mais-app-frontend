import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Seus imports de modelos
import '../models/daily_summary.dart';
import '../models/diet_plan.dart';
import '../models/food_suggestion.dart';
import '../models/meal_log.dart';
import '../models/monthly_average.dart';
import '../models/monthly_report.dart';
import '../models/user.dart';
import '../models/daily_calorie_log.dart';
import '../models/daily_hydration_log.dart';
import '../models/dashboard_data.dart';
//import '../models/recalculated_diet.dart';
import '../models/recalculation_result.dart';

class ApiService {
  final String _baseUrl =
      kIsWeb ? "http://127.0.0.1:8000/api/v1" : "http://10.0.2.2:8000/api/v1";

  String _formatDate(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // --- MÉTODOS DE AUTENTICAÇÃO ---

  Future<String> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    } else {
      throw Exception(
          jsonDecode(response.body)['message'] ?? 'Falha ao fazer login.');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    String? phoneNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    final Map<String, String> body = {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      body['phone_number'] = phoneNumber;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      final data = jsonDecode(response.body);
      final errorMessage =
          (data['errors'] as Map<String, dynamic>).values.first[0];
      throw Exception(errorMessage ?? 'Falha ao registrar.');
    }
  }

  Future<String> forgotPassword({required String identifier}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'identifier': identifier}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'];
    } else {
      throw Exception(data['message'] ?? 'Falha ao solicitar código.');
    }
  }

  Future<String> resetPassword({
    required String identifier,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset-password'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{
        'identifier': identifier,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'];
    } else {
      throw Exception(data['message'] ?? 'Falha ao redefinir a senha.');
    }
  }

  // --- MÉTODOS DO USUÁRIO ---

  Future<User> getUser(String token) async {
    // A rota para buscar o usuário autenticado é /api/user, não precisa de v1
    final uri = kIsWeb
        ? Uri.parse("http://127.0.0.1:8000/api/user")
        : Uri.parse("http://10.0.2.2:8000/api/user");

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar os dados do usuário.');
    }
  }

  Future<User> updateUserProfile({
    required String token,
    String? name, // Torna os parâmetros opcionais
    String? email,
    String? phoneNumber,
  }) async {
    final body = <String, String>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;

    final response = await http.put(
      Uri.parse('$_baseUrl/user/profile'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao atualizar o perfil.');
    }
  }

  Future<String> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/password'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data['message'];
    } else {
      throw Exception(data['message'] ?? 'Falha ao alterar a senha.');
    }
  }

  // --- MÉTODOS DE DIETA E REFEIÇÕES ---

  Future<void> uploadDietPdf(String token, File pdfFile) async {
    final uri = Uri.parse('$_baseUrl/diets');
    var request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('diet_pdf', pdfFile.path));

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode != 201) {
      throw Exception('Falha ao enviar o PDF. Status: ${response.statusCode}');
    }
  }

  Future<DietPlan> getActiveDietPlan(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/diets/active'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return DietPlan.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar o plano alimentar.');
    }
  }

  Future<DailySummary> getDailySummary(String token, DateTime date) async {
    final uri = Uri.parse('$_baseUrl/daily-summary').replace(
      queryParameters: {'date': _formatDate(date)},
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return DailySummary.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar o resumo diário.');
    }
  }

  Future<List<MonthlyAverage>> getAnnualReport(String token, int year) async {
    final uri = Uri.parse('$_baseUrl/reports/annual').replace(
      queryParameters: {'year': year.toString()},
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MonthlyAverage.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          errorData['message'] ?? 'Falha ao carregar o relatório anual.');
    }
  }

  Future<List<MealLog>> getMealsForDate(String token, DateTime date) async {
    final uri = Uri.parse('$_baseUrl/meal-logs').replace(
      queryParameters: {'date': _formatDate(date)},
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => MealLog.fromJson(json)).toList();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
          'Falha ao carregar as refeições: ${errorData['message']}');
    }
  }

  Future<void> logMeal({
    required String token,
    required int dietId,
    required String foodName,
    required int quantity,
    required DateTime consumedAt,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/meal-logs'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // <-- Headers completos aqui
      },
      body: jsonEncode(<String, dynamic>{
        'diet_id': dietId,
        'food_name': foodName,
        'quantity': quantity,
        'consumed_at': DateFormat('yyyy-MM-dd').format(consumedAt),
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Falha ao registrar a refeição.');
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
    if (response.statusCode != 204) {
      throw Exception('Falha ao deletar a refeição.');
    }
  }

  Future<List<FoodSuggestion>> getFoodSuggestions(
      String token, String foodName) async {
    final uri = Uri.parse('$_baseUrl/food-suggestions').replace(
      queryParameters: {'food_name': foodName},
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> suggestionsList = jsonDecode(response.body)['suggestions'];
      return suggestionsList
          .map((json) => FoodSuggestion.fromJson(json))
          .toList();
    } else {
      throw Exception('Falha ao buscar sugestões.');
    }
  }

  // --- MÉTODOS DE NOTIFICAÇÃO E CONFIGURAÇÕES ---

  Future<void> sendDeviceToken(String authToken, String fcmToken) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/device-token'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(<String, String>{'fcm_token': fcmToken}),
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
      return Map<String, bool>.from(jsonDecode(response.body));
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

  Future<MonthlyReport> getWeeklyReport(String token, DateTime date) async {
    final uri = Uri.parse('$_baseUrl/reports/weekly').replace(
      queryParameters: {
        'date': _formatDate(date)
      }, // Envia um dia qualquer da semana
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return MonthlyReport.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Falha ao carregar o relatório.');
    }
  }

  Future<List<DailyHydrationLog>> getMonthlyHydrationChartData(
      String token, int year, int month) async {
    final uri = Uri.parse('$_baseUrl/reports/monthly-hydration-chart').replace(
      queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      },
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DailyHydrationLog.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar dados do gráfico de hidratação.');
    }
  }

  Future<List<DailyCalorieLog>> getMonthlyChartData(
      String token, int year, int month) async {
    final uri = Uri.parse('$_baseUrl/reports/monthly-chart').replace(
      queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      },
    );
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DailyCalorieLog.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar dados do gráfico mensal.');
    }
  }

  Future<MonthlyReport> getMonthlyReport(
      String token, int year, int month) async {
    final uri = Uri.parse('$_baseUrl/reports/monthly').replace(
      queryParameters: {
        'year': year.toString(),
        'month': month.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return MonthlyReport.fromJson(jsonDecode(response.body));
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Falha ao carregar o relatório.');
    }
  }

  Future<void> addHydrationLog({
    required String token,
    required int amount,
    required DateTime consumedAt, // <-- NOVO PARÂMETRO
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/hydration-logs'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      // 2. Envia a data no corpo da requisição

      body: jsonEncode({
        'amount_ml': amount,
        'consumed_at': DateFormat('yyyy-MM-dd').format(consumedAt),
      }),
    );
    if (response.statusCode != 201)
      throw Exception('Falha ao registrar consumo de água.');
  }

  Future<void> updateHydrationGoal(String token, int goal) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/user/hydration-goal'),
      // HEADERS CORRIGIDOS (ADICIONADOS)
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'goal': goal}),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar meta de hidratação.');
    }
  }

  Future<void> createManualDiet(
      String token, Map<String, dynamic> dietData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/diets/manual'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(dietData),
    );

    if (response.statusCode != 201) {
      throw Exception('Falha ao criar o plano alimentar.');
    }
  }

  Future<List<DietPlan>> getAllDietPlans(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/diets'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DietPlan.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar planos alimentares.');
    }
  }

  Future<void> setActiveDiet(String token, int dietId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/diets/$dietId/activate'),
      // Adicionamos os headers que estavam faltando
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao ativar o plano.');
    }
  }

  Future<void> deleteDiet(String token, int dietId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/diets/$dietId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 204)
      throw Exception('Falha ao deletar o plano.');
  }

  Future<String?> getAuthToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'auth_token');
  }

// Novo método que combina as chamadas para o dashboard
  Future<DashboardData> getDashboardData(String token, DateTime date) async {
    final results = await Future.wait([
      getDailySummary(token, date),
      getMealsForDate(token, date),
    ]);
    return DashboardData(
      summary: results[0] as DailySummary,
      todaysMeals: results[1] as List<MealLog>,
    );
  }

  // Agora retorna o ID do novo plano
  Future<RecalculationResult> recalculateDiet(String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/diets/recalculate'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return RecalculationResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao recalcular a dieta.');
    }
  }

  Future<DietPlan> getDietPlanDetails(String token, int dietId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/diets/$dietId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return DietPlan.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao carregar detalhes do plano.');
    }
  }

  Future<bool> checkUserStatus(String token) async {
    final uri = Uri.parse('${_baseUrl.replaceAll("/v1", "")}/user/status');
    final response = await http.get(uri, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['has_active_diet'];
    }
    return false; // Assume que não tem plano se a chamada falhar
  }

  Future<List<DietPlan>> getDietPlans(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/diets'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => DietPlan.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar planos alimentares.');
    }
  }
}
