import 'package:flutter/material.dart';
import '../models/feature_flags.dart';
import '../api/api_service.dart';

class FeatureProvider extends ChangeNotifier {
  FeatureFlags _flags = FeatureFlags.defaults();
  bool _loaded = false;

  FeatureFlags get flags => _flags;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final api = ApiService();
      _flags = await api.fetchFeatureFlags();
    } catch (_) {
      _flags = FeatureFlags.defaults();
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }
}
