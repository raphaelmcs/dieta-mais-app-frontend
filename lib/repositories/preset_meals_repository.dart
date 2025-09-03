// lib/repositories/preset_meals_repository.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/preset_meal.dart';

class PresetMealsRepository {
  static const _key = 'preset_meals_v1';

  Future<List<PresetMeal>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final txt = prefs.getString(_key);
    if (txt == null || txt.isEmpty) return [];
    final List raw = jsonDecode(txt) as List;
    return raw.map((e) => PresetMeal.fromJson(e as Map<String, dynamic>)).toList();
    }

  Future<void> save(PresetMeal meal) async {
    final list = await getAll();
    final updated = [...list, meal];
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final list = await getAll();
    final updated = list.where((m) => m.id != id).toList();
    await _persist(updated);
  }

  Future<void> _persist(List<PresetMeal> list) async {
    final prefs = await SharedPreferences.getInstance();
    final txt = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, txt);
  }
}
